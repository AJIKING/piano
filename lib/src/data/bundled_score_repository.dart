import '../domain/score/piece.dart';
import '../domain/score/score_repository.dart';
import 'score_data.dart';

/// 同梱 Dart データから収録曲を供給する `ScoreRepository` の本番実装(ADR 0003)。
class BundledScoreRepository implements ScoreRepository {
  const BundledScoreRepository();

  @override
  Piece featured() => buildFeaturedPiece();

  @override
  List<Piece> samplePieces() => buildSamplePieces();

  @override
  Piece? original(String id) {
    for (final piece in [featured(), ...samplePieces()]) {
      if (piece.id == id) return piece;
    }
    return null;
  }
}
