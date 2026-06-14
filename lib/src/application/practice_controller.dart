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
  int? _litNoteIndex;

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

  /// いま鳴っている音符のインデックス([piece] の正準順)。譜面ハイライト用。
  int? get litNoteIndex => _litNoteIndex;

  /// 先頭から再生を開始する。空の旋律では何もしない。
  void play() {
    if (_isPlaying) return;
    _notes = piece.sortedNotes;
    if (_notes.isEmpty) return;
    _contentEndBeats = Piece.contentEndOf(_notes);
    _totalBeats = _contentEndBeats + tailBeats;
    _elapsedBeats = 0;
    _nextNote = 0;
    _nextBeat = 0;
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
    _litNoteIndex = null;
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
      _litNoteIndex = _nextNote - 1;
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
    super.dispose();
  }
}
