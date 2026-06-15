import 'note.dart';

/// 1 曲(収録曲または自作曲)。pure Dart。
class Piece {
  Piece({
    required this.id,
    required this.title,
    required this.composer,
    required this.notes,
    this.fullNotes = const [],
    this.isUserCreated = false,
    this.beatsPerMeasure = 3,
    this.defaultBpm = 72,
  });

  final String id;
  final String title;
  final String composer;

  /// 旋律(片手・弾ける単旋律)。`beat` 昇順に整列していることを期待する。
  /// エディタ・3オクターブ鍵盤・練習はこれを使う。
  final List<Note> notes;

  /// 両手のフル譜面(任意)。収録曲のうち実データのある曲だけ持つ。
  /// 大譜表表示＋両手再生(表示専用)に使う。音域は鍵盤範囲に縛られない。
  /// 自作曲・単旋律曲は空。
  final List<Note> fullNotes;

  /// 両手フル譜面を持つか。
  bool get hasFullScore => fullNotes.isNotEmpty;

  /// 両手の「お手本」に使えるか(バス=中央C(C4=60)より下の音を含む)。
  /// 片手だけの薄い fullNotes(メヌエット等)では false にして両手トグルを出さない。
  bool get hasTwoHandScore => fullNotes.any((n) => Note.midiOf(n.pitch) < 60);

  /// 拍子の 1 小節あたりの拍数(小節線・メトロノームの強拍に使う)。
  final int beatsPerMeasure;

  /// 既定テンポ(BPM)。練習・試聴の初期値に使う。
  final int defaultBpm;

  /// ユーザーが作成・編集した曲か(収録曲は false)。
  final bool isUserCreated;

  /// 音符列の終端拍(各音符の `beat + duration` の最大。空なら 0)。
  static double contentEndOf(Iterable<Note> notes) => notes.fold(
    0,
    (e, n) => n.beat + n.duration > e ? n.beat + n.duration : e,
  );

  /// 旋律の終端拍。
  double get contentEnd => contentEndOf(notes);

  /// 音符の正準な**全順序**(beat → 音高(MIDI) → 音価)。
  ///
  /// `List.sort` は安定ソートではないため、`beat` だけで比較すると同 beat の音符
  /// (和音)の相対順序がソートのたびに変わりうる。譜面描画・タップ判定・再生で
  /// 並びがズレないよう、どこでソートしても同じ並びになる全順序を 1 つに定める。
  static int compareNotes(Note a, Note b) {
    final byBeat = a.beat.compareTo(b.beat);
    if (byBeat != 0) return byBeat;
    final byPitch = Note.midiOf(a.pitch).compareTo(Note.midiOf(b.pitch));
    if (byPitch != 0) return byPitch;
    return a.duration.compareTo(b.duration);
  }

  /// 正準順に整列した旋律のコピー。
  List<Note> get sortedNotes => List<Note>.of(notes)..sort(compareNotes);

  Piece copyWith({
    String? id,
    String? title,
    String? composer,
    List<Note>? notes,
    List<Note>? fullNotes,
    bool? isUserCreated,
    int? beatsPerMeasure,
    int? defaultBpm,
  }) => Piece(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer ?? this.composer,
    notes: notes ?? this.notes,
    fullNotes: fullNotes ?? this.fullNotes,
    isUserCreated: isUserCreated ?? this.isUserCreated,
    beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
    defaultBpm: defaultBpm ?? this.defaultBpm,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'composer': composer,
    'isUserCreated': isUserCreated,
    'beatsPerMeasure': beatsPerMeasure,
    'defaultBpm': defaultBpm,
    'notes': notes.map((n) => n.toJson()).toList(),
    // fullNotes(両手フル譜面)は収録曲データ由来で量が大きいため永続化しない。
    // 復元時に id でデータ側から再注入する([LibraryController.restore])。
  };

  factory Piece.fromJson(Map<String, Object?> json) {
    List<Note> parseNotes(Object? raw) => (raw as List<Object?>? ?? const [])
        .map((e) => Note.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    return Piece(
      id: json['id']! as String,
      title: json['title']! as String,
      composer: json['composer']! as String,
      isUserCreated: json['isUserCreated'] as bool? ?? false,
      beatsPerMeasure: (json['beatsPerMeasure'] as num?)?.toInt() ?? 3,
      defaultBpm: (json['defaultBpm'] as num?)?.toInt() ?? 72,
      notes: parseNotes(json['notes']),
      fullNotes: parseNotes(json['fullNotes']),
    );
  }

  @override
  String toString() => 'Piece($id "$title" / $composer, ${notes.length} notes)';
}
