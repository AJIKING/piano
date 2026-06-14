import '../score/piece.dart';

/// ユーザーの楽譜コレクション(自作曲・習得度・最終練習日時)を永続化する境界。
/// テストではインメモリ fake に差し替える。実装は data 層(`PrefsLibraryStore`)。
/// 永続化方式は ADR 0001。
abstract interface class LibraryStore {
  /// 保存済みコレクションを読む。未保存・破損時は null(初回起動として扱う)。
  Future<List<Piece>?> load();

  /// コレクション全体を保存する。
  Future<void> save(List<Piece> pieces);
}
