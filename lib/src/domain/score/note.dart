import 'dart:math' as math;

/// 1 つの音符。pure Dart(`package:flutter` を import しない)。
///
/// - [pitch]: 科学的音名(`C4` / `F#5` など)。`^[A-G]#?\d$` にマッチする。
/// - [beat]: 開始拍(拍単位、0 始まり)。
/// - [duration]: 音価(拍単位)。8 分=0.5 / 4 分=1 / 2 分=2 / 付点 2 分=3。
class Note {
  const Note({required this.pitch, required this.beat, required this.duration});

  final String pitch;
  final double beat;
  final double duration;

  /// 許容する音価(拍単位)。16分(0.25)/ 8分(0.5)/ 4分(1)/ 付点4分(1.5)/
  /// 2分(2)/ 付点2分(3)の 6 種。
  /// (double は == を override するため const Set には入れられない。List で持つ)
  static const List<double> allowedDurations = [0.25, 0.5, 1, 1.5, 2, 3];

  static final RegExp _pitchPattern = RegExp(r'^([A-G])(#?)([0-9])$');

  /// 黒鍵を持つ(♯ を付けられる)音名。
  static const Set<String> _sharpable = {'C', 'D', 'F', 'G', 'A'};

  static const Map<String, int> _letterStep = {
    'C': 0,
    'D': 1,
    'E': 2,
    'F': 3,
    'G': 4,
    'A': 5,
    'B': 6,
  };

  static bool isValidPitch(String pitch) => _pitchPattern.hasMatch(pitch);

  bool get hasValidPitch => isValidPitch(pitch);

  bool get hasValidDuration => allowedDurations.contains(duration);

  /// 妥当な音符か(音名・音価・非負の拍)。
  bool get isValid => hasValidPitch && hasValidDuration && beat >= 0;

  /// 五線上の位置(diatonic step)。E4(ト音記号の下第 1 線)を 0 とする。
  /// プロトタイプ `dia()` 相当。値が大きいほど上。
  int get diatonicStep {
    final m = _pitchPattern.firstMatch(pitch);
    if (m == null) {
      throw FormatException('不正な音名: $pitch');
    }
    final letter = _letterStep[m.group(1)]!;
    final octave = int.parse(m.group(3)!);
    // E4 を基準(=0)にする: 4*7+2 が E4 の絶対 step。
    return octave * 7 + letter - (4 * 7 + 2);
  }

  /// この音名に ♯ を付けられるか。
  bool get isSharpable {
    final m = _pitchPattern.firstMatch(pitch);
    return m != null && _sharpable.contains(m.group(1));
  }

  /// 音名の ♯ を [sharp] に合わせて付け外しする(不正な音名はそのまま返す)。
  static String withAccidental(String pitch, {required bool sharp}) {
    final m = _pitchPattern.firstMatch(pitch);
    if (m == null) return pitch;
    return '${m.group(1)}${sharp ? '#' : ''}${m.group(3)}';
  }

  /// diatonicStep(E4=0)+ 臨時記号 → 音名。譜面タップ・鍵盤からの音符追加に使う。
  /// プロトタイプ `stepToNote()` 相当。♯ は黒鍵を持つ音名にのみ付く。
  static const _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static String pitchForStep(int diatonicStep, {bool sharp = false}) {
    // E4(step 0)の絶対 step は 4*7+2 = 30。
    final abs = diatonicStep + 30;
    final octave = abs ~/ 7;
    final letter = _letters[abs - octave * 7];
    final withSharp = sharp && _sharpable.contains(letter);
    return '$letter${withSharp ? '#' : ''}$octave';
  }

  /// 音名 → 音階(ドレミ)表記。オクターブは付けない。`C4`→`ド`, `F#5`→`ファ♯`。
  static const Map<String, String> _solfege = {
    'C': 'ド',
    'D': 'レ',
    'E': 'ミ',
    'F': 'ファ',
    'G': 'ソ',
    'A': 'ラ',
    'B': 'シ',
  };
  static String solfege(String pitch) {
    final m = _pitchPattern.firstMatch(pitch);
    if (m == null) return pitch;
    return '${_solfege[m.group(1)]!}${m.group(2) == '#' ? '♯' : ''}';
  }

  /// 音名(オクターブなし)。`C4`→`C`, `F#5`→`F♯`。言語非依存の表示に使う。
  static String letterName(String pitch) {
    final m = _pitchPattern.firstMatch(pitch);
    if (m == null) return pitch;
    return '${m.group(1)}${m.group(2) == '#' ? '♯' : ''}';
  }

  /// C からの半音数(C=0, C#=1, …, B=11)。
  static const Map<String, int> _letterSemitone = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  /// 音名 → MIDI ノート番号(A4=69)。
  static int midiOf(String pitch) {
    final m = _pitchPattern.firstMatch(pitch);
    if (m == null) throw FormatException('不正な音名: $pitch');
    final semitone = _letterSemitone[m.group(1)]! + (m.group(2) == '#' ? 1 : 0);
    final octave = int.parse(m.group(3)!);
    return (octave + 1) * 12 + semitone;
  }

  /// 音名 → 周波数(Hz)。A4 = 440Hz の平均律。
  static double frequencyOf(String pitch) =>
      440 * math.pow(2, (midiOf(pitch) - 69) / 12).toDouble();

  /// この音符の周波数(Hz)。
  double get frequencyHz => frequencyOf(pitch);

  Note copyWith({String? pitch, double? beat, double? duration}) => Note(
    pitch: pitch ?? this.pitch,
    beat: beat ?? this.beat,
    duration: duration ?? this.duration,
  );

  Map<String, Object?> toJson() => {
    'pitch': pitch,
    'beat': beat,
    'duration': duration,
  };

  factory Note.fromJson(Map<String, Object?> json) => Note(
    pitch: json['pitch']! as String,
    beat: (json['beat']! as num).toDouble(),
    duration: (json['duration']! as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.pitch == pitch &&
      other.beat == beat &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(pitch, beat, duration);

  @override
  String toString() => 'Note($pitch @$beat ×$duration)';
}
