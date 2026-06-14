import 'note.dart';
import 'piece.dart';

/// 再生時の 1 発音イベント(pure Dart)。
class PlaybackEvent {
  const PlaybackEvent({
    required this.time,
    required this.pitch,
    required this.duration,
    required this.noteIndex,
  });

  /// 曲頭からの発音開始時刻。
  final Duration time;

  /// 発音する音高。
  final String pitch;

  /// 発音の長さ(余韻含む)。
  final Duration duration;

  /// 元の旋律(整列後)における音符インデックス。再生中ハイライトに使う。
  final int noteIndex;
}

/// メトロノームの 1 クリック。
class MetronomeTick {
  const MetronomeTick({required this.time, required this.isDownbeat});

  /// 曲頭からのクリック時刻。
  final Duration time;

  /// 小節先頭(強拍)か。
  final bool isDownbeat;
}

/// 旋律 + テンポから発音イベント列を組み立てる(pure Dart)。
/// 実時間にも `AudioEngine` にも依存しないため、テストで決定的に検証できる。
class PlaybackSchedule {
  PlaybackSchedule._(this.events, this.total, this.metronome);

  /// 発音イベント(time 昇順)。
  final List<PlaybackEvent> events;

  /// 再生の総尺(末尾の音の終端 + わずかな余韻)。
  final Duration total;

  /// メトロノームのクリック列。
  final List<MetronomeTick> metronome;

  /// 1 拍の秒数。
  static double secondsPerBeat(double bpm) => 60 / bpm;

  static Duration _beatsToDuration(double beats, double bpm) =>
      Duration(microseconds: (beats * secondsPerBeat(bpm) * 1e6).round());

  /// [notes] を [bpm] で再生するスケジュールを作る。
  ///
  /// - [tailBeats]: 最後の音の後に付ける余韻(停止判定用)。
  /// - [beatsPerMeasure]: メトロノームの強拍周期(3/4 なら 3)。
  factory PlaybackSchedule.fromNotes(
    List<Note> notes, {
    required double bpm,
    double tailBeats = 0.3,
    int beatsPerMeasure = 3,
  }) {
    assert(bpm > 0, 'bpm は正の値である必要があります: $bpm');
    // 譜面ハイライトの noteIndex を painter の並び(Piece.sortedNotes)と一致させるため、
    // 同じ正準比較子で整列する。
    final sorted = List<Note>.of(notes)..sort(Piece.compareNotes);

    final events = <PlaybackEvent>[
      for (final (i, n) in sorted.indexed)
        PlaybackEvent(
          time: _beatsToDuration(n.beat, bpm),
          pitch: n.pitch,
          duration: _beatsToDuration(n.duration, bpm),
          noteIndex: i,
        ),
    ];

    final contentEndBeats = Piece.contentEndOf(sorted);
    final total = _beatsToDuration(contentEndBeats + tailBeats, bpm);

    final tickCount = contentEndBeats.ceil();
    final metronome = <MetronomeTick>[
      for (var b = 0; b < tickCount; b++)
        MetronomeTick(
          time: _beatsToDuration(b.toDouble(), bpm),
          isDownbeat: b % beatsPerMeasure == 0,
        ),
    ];

    return PlaybackSchedule._(events, total, metronome);
  }
}
