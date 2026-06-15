import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../domain/library/library_store.dart';
import '../domain/score/mastery.dart';
import '../domain/score/piece.dart';
import '../domain/score/score_repository.dart';

/// ライブラリ画面の状態。収録曲＋ユーザー曲のコレクションを保持し、
/// 編集の保存・練習完了による習得度更新を永続化する。
///
/// 初期化時は収録曲(`ScoreRepository`)で即座に seed し、画面はすぐ描画できる。
/// [restore] で永続化済みのコレクションを上書きする(非同期)。
class LibraryController extends ChangeNotifier {
  LibraryController({
    required ScoreRepository repository,
    required this._store,
    required this._clock,
  }) : _seedFeatured = repository.featured(),
       _featuredId = repository.featured().id,
       _pieces = [repository.featured(), ...repository.samplePieces()];

  final LibraryStore _store;
  final Clock _clock;
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
  Future<void> restore() async {
    final saved = await _store.load();
    if (saved == null || saved.isEmpty) return;
    _pieces = saved.any((p) => p.id == _featuredId)
        ? saved
        : [_seedFeatured, ...saved];
    notifyListeners();
  }

  /// 空の自作曲(「無題の楽譜」)を作成して末尾に追加し、永続化する。
  Future<Piece> createPiece() async {
    final piece = Piece(
      id: 'user-${_nextUserSeq()}',
      title: '無題の楽譜',
      composer: '自作',
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

  /// 練習を 1 回弾き切ったときの記録。習得度を上げ、最終練習日時を更新する。
  /// 注: 「今練習中」カード廃止により、現状この値を表示する UI は無い。
  /// データとしては保持し続ける(将来の進捗表示に備える)。
  Future<void> recordPractice(String pieceId) async {
    final i = _pieces.indexWhere((p) => p.id == pieceId);
    if (i < 0) return;
    final piece = _pieces[i];
    _pieces = [..._pieces];
    _pieces[i] = piece.copyWith(
      masteryPercent: Mastery.afterPractice(piece.masteryPercent),
      lastPracticedAt: _clock.now(),
    );
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
