import 'package:flutter/foundation.dart';

import '../domain/library/library_store.dart';
import '../domain/score/piece.dart';
import '../domain/score/score_repository.dart';

/// ライブラリ画面の状態。収録曲＋ユーザー曲のコレクションを保持し、
/// 編集の保存を永続化する。
///
/// 初期化時は収録曲(`ScoreRepository`)で即座に seed し、画面はすぐ描画できる。
/// [restore] で永続化済みのコレクションを上書きする(非同期)。
class LibraryController extends ChangeNotifier {
  LibraryController({required ScoreRepository repository, required this._store})
    : _repository = repository,
      _seedFeatured = repository.featured(),
      _featuredId = repository.featured().id,
      _pieces = [repository.featured(), ...repository.samplePieces()];

  final ScoreRepository _repository;
  final LibraryStore _store;
  final Piece _seedFeatured;
  final String _featuredId;
  List<Piece> _pieces;

  /// 永続化の直列化チェーン。複数の保存が並走して古い snapshot が後着し、
  /// ディスク内容が巻き戻る(lost update)のを防ぐ。
  Future<void> _writes = Future<void>.value();

  /// 起動時に編集タブの既定として開く曲(収録曲の代表)。
  Piece get featured => _pieces.firstWhere(
    (p) => p.id == _featuredId,
    orElse: () => _seedFeatured,
  );

  /// 楽譜の一覧(収録曲＋ユーザー曲をすべて表示順で)。
  List<Piece> get pieces => List.unmodifiable(_pieces);

  /// 永続化済みのコレクションがあれば読み込んで置き換える。
  /// 旧スキーマで featured を含まない保存データには featured を補う。
  /// fullNotes(両手フル譜面)は永続化していないため、収録曲は id でデータ側から
  /// 再注入する(保存サイズを抑えつつ、アプリ更新でのデータ改善にも追従できる)。
  Future<void> restore() async {
    final saved = await _store.load();
    if (saved == null || saved.isEmpty) return;
    final placed = saved.any((p) => p.id == _featuredId)
        ? saved
        : [_seedFeatured, ...saved];
    _pieces = placed.map(_withFullNotes).toList();
    notifyListeners();
  }

  /// 収録曲データに対応する id があれば fullNotes を補う(自作曲は対象外)。
  Piece _withFullNotes(Piece piece) {
    if (piece.fullNotes.isNotEmpty) return piece;
    final original = _repository.original(piece.id);
    return (original != null && original.fullNotes.isNotEmpty)
        ? piece.copyWith(fullNotes: original.fullNotes)
        : piece;
  }

  /// 空の自作曲を作成して末尾に追加し、永続化する。
  /// 既定の曲名・作曲者は表示言語に合わせて UI から渡す(省略時は日本語)。
  Future<Piece> createPiece({
    String title = '無題の楽譜',
    String composer = '自作',
  }) async {
    final piece = Piece(
      id: 'user-${_nextUserSeq()}',
      title: title,
      composer: composer,
      notes: const [],
      isUserCreated: true,
    );
    _pieces = [..._pieces, piece];
    notifyListeners();
    await _persist();
    return piece;
  }

  /// 既存の `user-N` id の最大値 + 1。復元後でも id が衝突しないようにする。
  int _nextUserSeq() {
    final pattern = RegExp(r'^user-(\d+)$');
    var max = 0;
    for (final p in _pieces) {
      final m = pattern.firstMatch(p.id);
      if (m != null) {
        final n = int.parse(m.group(1)!);
        if (n > max) max = n;
      }
    }
    return max + 1;
  }

  /// 編集結果を保存する。同じ id があれば置き換え、無ければ追加する。
  Future<void> savePiece(Piece piece) async {
    final i = _pieces.indexWhere((p) => p.id == piece.id);
    _pieces = [..._pieces];
    if (i >= 0) {
      _pieces[i] = piece;
    } else {
      _pieces.add(piece);
    }
    notifyListeners();
    await _persist();
  }

  /// 現在のコレクションを永続化する。呼び出し順を保って直列に書き込む
  /// (各書き込みは呼び出し時点の snapshot を保存する)。
  Future<void> _persist() {
    final snapshot = _pieces;
    _writes = _writes
        .then((_) => _store.save(snapshot))
        .catchError((Object _) {});
    return _writes;
  }
}
