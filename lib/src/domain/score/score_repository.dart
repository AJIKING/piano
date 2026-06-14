import 'piece.dart';

/// 同梱の収録曲を供給する境界。テストでは最小 fixture に差し替える。
/// 実装は data 層(`BundledScoreRepository`)。供給方式は ADR 0003。
abstract interface class ScoreRepository {
  /// 「今練習中」として最初に提示する既定曲。
  Piece featured();

  /// 収録曲のコレクション(マイ楽譜の初期一覧。featured は含めない)。
  List<Piece> samplePieces();
}
