import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/audio/audio_engine.dart';
import '../domain/score/note.dart';
import '../domain/score/piece.dart';

/// 練習画面の再生状態。旋律を**拍ベース**で進め、`AudioEngine` 境界へ発音を委譲する。
///
/// 拍の進み(`_elapsedBeats`)を毎フレーム `bpm` に応じて加算するため、**再生中に
/// テンポを変えると即座に再生速度が変わる**。実時間に依存せず、テストは `fake_async`
/// で `Timer` を進めて検証する。
class PracticeController extends ChangeNotifier {
  PracticeController({
    required this.piece,
    required AudioEngine audioEngine,
    double bpm = 72,
    this.onCompleted,
  }) : _audio = audioEngine,
       _bpm = bpm.clamp(minBpm, maxBpm);

  /// 曲を最後まで弾き切ったときに 1 度だけ呼ばれる(ユーザー停止では呼ばれない)。
  final VoidCallback? onCompleted;

  static const double minBpm = 40;
  static const double maxBpm = 160;

  /// 拍子の強拍周期(3/4 拍子)。
  static const int beatsPerMeasure = 3;

  /// 末尾に付ける余韻(拍)。
  static const double tailBeats = 0.3;

  /// 描画フレーム相当の刻み(約 60fps)。
  static const Duration tickInterval = Duration(milliseconds: 16);

  final AudioEngine _audio;

  /// 再生対象の曲。
  Piece piece;

  double _bpm;
  bool _metronomeOn = false;
  bool _isPlaying = false;
  Set<int> _litNoteIndices = const {};
  final ValueNotifier<Set<String>> _litPitches = ValueNotifier(const {});

  Timer? _timer;
  List<Note> _notes = const [];
  double _elapsedBeats = 0;
  double _contentEndBeats = 0;
  double _totalBeats = 0;
  int _nextNote = 0;
  int _nextBeat = 0;

  double get bpm => _bpm;
  bool get metronomeOn => _metronomeOn;
  bool get isPlaying => _isPlaying;

  /// 曲頭からの再生位置(拍)。譜面の再生ヘッド描画に使う。
  double get playheadBeats => _elapsedBeats;

  /// いま鳴っている音符のインデックス集合([piece] の正準順)。譜面ハイライト用。
  /// 同じタイミングの和音を全て光らせるため集合で持つ。
  Set<int> get litNoteIndices => _litNoteIndices;

  /// いま鳴っている音高の集合(和音は複数)。鍵盤ハイライト用。
  /// 毎フレームではなく「鳴る音が変わった時だけ」通知するので、鍵盤は
  /// これだけを購読すれば再生中に毎フレーム再構築されない。
  ValueListenable<Set<String>> get litPitches => _litPitches;

  /// 再生を開始する。空の旋律では何もしない。
  /// [fromBeat] を指定すると、その拍位置から再生する(指定位置からの試聴)。
  void play({double fromBeat = 0}) {
    if (_isPlaying) return;
    _notes = piece.sortedNotes;
    if (_notes.isEmpty) return;
    _contentEndBeats = Piece.contentEndOf(_notes);
    _totalBeats = _contentEndBeats + tailBeats;
    final start = fromBeat.clamp(0.0, _contentEndBeats);
    _elapsedBeats = start;
    // start 以降の最初の音符・メトロノーム拍から始める(前の音は鳴らさない)。
    final firstNote = _notes.indexWhere((n) => n.beat >= start);
    _nextNote = firstNote < 0 ? _notes.length : firstNote;
    _nextBeat = start.ceil();
    _litNoteIndices = const {};
    _litPitches.value = const {};
    _audio.init();
    _isPlaying = true;
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
    notifyListeners();
  }

  /// 再生を停止し、先頭へ戻す。
  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_isPlaying) _audio.stopAll();
    _isPlaying = false;
    _elapsedBeats = 0;
    _litNoteIndices = const {};
    _litPitches.value = const {};
    notifyListeners();
  }

  void toggle() => _isPlaying ? stop() : play();

  /// テンポを変える。**再生中なら即座に再生速度へ反映される**。
  void setBpm(double value) {
    _bpm = value.clamp(minBpm, maxBpm);
    notifyListeners();
  }

  void toggleMetronome() {
    _metronomeOn = !_metronomeOn;
    notifyListeners();
  }

  void _onTick() {
    final seconds = tickInterval.inMicroseconds / 1e6;
    // この瞬間のテンポで拍を進める(再生中のテンポ変更が即反映される)。
    _elapsedBeats += seconds * (_bpm / 60);
    final secondsPerBeat = 60 / _bpm;

    final fired = <String>[];
    final firedIndices = <int>[];
    while (_nextNote < _notes.length &&
        _notes[_nextNote].beat <= _elapsedBeats) {
      final note = _notes[_nextNote++];
      // 余韻は発音時点のテンポで実時間に換算する。発音後に大きくテンポを変えると
      // この note-off は古い実時間で予約済みのため多少ずれる(次の音から整合する)。
      _audio.playNote(
        note.pitch,
        sustain: Duration(
          microseconds: (note.duration * secondsPerBeat * 1e6).round(),
        ),
      );
      firedIndices.add(_nextNote - 1);
      fired.add(note.pitch);
    }
    // 新しく鳴った音があれば、その集合をハイライト対象にする(和音は複数音/複数鍵)。
    if (fired.isNotEmpty) {
      _litPitches.value = fired.toSet();
      _litNoteIndices = firedIndices.toSet();
    }

    if (_metronomeOn) {
      final lastBeat = _contentEndBeats.ceil();
      while (_nextBeat < lastBeat && _nextBeat <= _elapsedBeats) {
        // クリックは AudioEngine の発音で代用(強拍/弱拍で音高を変える)。
        _audio.playNote(
          _nextBeat % beatsPerMeasure == 0 ? 'C3' : 'G2',
          sustain: const Duration(milliseconds: 50),
        );
        _nextBeat++;
      }
    }

    if (_elapsedBeats >= _totalBeats) {
      stop();
      onCompleted?.call();
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 再生中に破棄されたら鳴っている音も止める(notifyListeners は呼ばない)。
    if (_isPlaying) _audio.stopAll();
    _litPitches.dispose();
    super.dispose();
  }
}
