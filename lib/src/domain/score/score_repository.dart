import 'piece.dart';

/// 同梱の収録曲を供給する境界。テストでは最小 fixture に差し替える。
/// 実装は data 層(`BundledScoreRepository`)。供給方式は ADR 0003。
abstract interface class ScoreRepository {
  /// 起動時に編集タブの既定として開く代表曲。
  Piece featured();

  /// featured を除く収録曲のコレクション(一覧では featured と結合して表示)。
  List<Piece> samplePieces();

  /// 収録曲の初期版を id で返す(編集前へ戻す用)。該当しなければ null。
  Piece? original(String id);
}
