import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/audio/audio_engine.dart';
import '../domain/score/piece.dart';
import '../domain/score/playback_schedule.dart';

/// 練習画面の再生状態。`PlaybackSchedule`(pure Dart)を `Timer` で駆動し、
/// `AudioEngine` 境界へ発音を委譲する。実時間に依存せず、テストは `fake_async`
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

  /// 描画フレーム相当の刻み(約 60fps)。
  static const Duration tickInterval = Duration(milliseconds: 16);

  final AudioEngine _audio;

  /// 再生対象の曲。
  Piece piece;

  double _bpm;
  bool _metronomeOn = false;
  bool _isPlaying = false;
  Duration _playhead = Duration.zero;
  int? _litNoteIndex;

  Timer? _timer;
  PlaybackSchedule? _schedule;
  Duration _elapsed = Duration.zero;
  int _nextEvent = 0;
  int _nextTick = 0;
  double _playSecondsPerBeat = 1;

  double get bpm => _bpm;
  bool get metronomeOn => _metronomeOn;
  bool get isPlaying => _isPlaying;

  /// 曲頭からの再生位置。
  Duration get playhead => _playhead;

  /// 曲頭からの再生位置(拍)。譜面の再生ヘッド描画に使う。
  /// テンポを再生中に変えても、再生に使っているテンポで換算する(譜面とズレない)。
  double get playheadBeats => _playSecondsPerBeat <= 0
      ? 0
      : _elapsed.inMicroseconds / 1e6 / _playSecondsPerBeat;

  /// いま鳴っている音符のインデックス(無ければ null)。譜面ハイライト用。
  int? get litNoteIndex => _litNoteIndex;

  /// 先頭から再生を開始する。空の旋律では何もしない。
  void play() {
    if (_isPlaying) return;
    final schedule = PlaybackSchedule.fromNotes(piece.notes, bpm: _bpm);
    if (schedule.events.isEmpty) return;
    _schedule = schedule;
    _playSecondsPerBeat = PlaybackSchedule.secondsPerBeat(_bpm);
    _audio.init();
    _elapsed = Duration.zero;
    _nextEvent = 0;
    _nextTick = 0;
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
    _playhead = Duration.zero;
    _litNoteIndex = null;
    notifyListeners();
  }

  void toggle() => _isPlaying ? stop() : play();

  /// テンポを変える(再生中は次の `play()` から反映)。
  void setBpm(double value) {
    _bpm = value.clamp(minBpm, maxBpm);
    notifyListeners();
  }

  void toggleMetronome() {
    _metronomeOn = !_metronomeOn;
    notifyListeners();
  }

  void _onTick() {
    final schedule = _schedule!;
    _elapsed += tickInterval;

    while (_nextEvent < schedule.events.length &&
        schedule.events[_nextEvent].time <= _elapsed) {
      final event = schedule.events[_nextEvent++];
      _audio.playNote(event.pitch, sustain: event.duration);
      _litNoteIndex = event.noteIndex;
    }

    if (_metronomeOn) {
      while (_nextTick < schedule.metronome.length &&
          schedule.metronome[_nextTick].time <= _elapsed) {
        final tick = schedule.metronome[_nextTick++];
        // クリックは AudioEngine の発音で代用(強拍/弱拍で音高を変える)。
        _audio.playNote(
          tick.isDownbeat ? 'C3' : 'G2',
          sustain: const Duration(milliseconds: 50),
        );
      }
    }

    _playhead = _elapsed;
    if (_elapsed >= schedule.total) {
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
