import 'note.dart';

/// 1 曲(収録曲または自作曲)。pure Dart。
class Piece {
  Piece({
    required this.id,
    required this.title,
    required this.composer,
    required this.notes,
    this.stars = 0,
    this.masteryPercent = 0,
    this.lastPracticedAt,
    this.isUserCreated = false,
  });

  final String id;
  final String title;
  final String composer;

  /// 旋律。`beat` 昇順に整列していることを期待する([sortedNotes] で正規化できる)。
  final List<Note> notes;

  /// 難易度(★ 0–5)。
  final int stars;

  /// 習得度(0–100)。
  final int masteryPercent;

  /// 最終練習日時(未練習なら null)。
  final DateTime? lastPracticedAt;

  /// ユーザーが作成・編集した曲か(収録曲は false)。
  final bool isUserCreated;

  /// 音符列の終端拍(各音符の `beat + duration` の最大。空なら 0)。
  static double contentEndOf(Iterable<Note> notes) => notes.fold(
    0,
    (e, n) => n.beat + n.duration > e ? n.beat + n.duration : e,
  );

  /// 旋律の終端拍。
  double get contentEnd => contentEndOf(notes);

  /// `beat` 昇順に整列した旋律のコピー。
  List<Note> get sortedNotes =>
      List<Note>.of(notes)..sort((a, b) => a.beat.compareTo(b.beat));

  Piece copyWith({
    String? id,
    String? title,
    String? composer,
    List<Note>? notes,
    int? stars,
    int? masteryPercent,
    DateTime? lastPracticedAt,
    bool? isUserCreated,
  }) => Piece(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer ?? this.composer,
    notes: notes ?? this.notes,
    stars: stars ?? this.stars,
    masteryPercent: masteryPercent ?? this.masteryPercent,
    lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    isUserCreated: isUserCreated ?? this.isUserCreated,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'composer': composer,
    'stars': stars,
    'masteryPercent': masteryPercent,
    'lastPracticedAt': lastPracticedAt?.toIso8601String(),
    'isUserCreated': isUserCreated,
    'notes': notes.map((n) => n.toJson()).toList(),
  };

  factory Piece.fromJson(Map<String, Object?> json) {
    final rawNotes = (json['notes'] as List<Object?>? ?? const [])
        .map((e) => Note.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    final rawDate = json['lastPracticedAt'] as String?;
    return Piece(
      id: json['id']! as String,
      title: json['title']! as String,
      composer: json['composer']! as String,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      masteryPercent: (json['masteryPercent'] as num?)?.toInt() ?? 0,
      lastPracticedAt: rawDate == null ? null : DateTime.parse(rawDate),
      isUserCreated: json['isUserCreated'] as bool? ?? false,
      notes: rawNotes,
    );
  }

  @override
  String toString() => 'Piece($id "$title" / $composer, ${notes.length} notes)';
}
