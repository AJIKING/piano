import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/piece.dart';
import 'package:etude/src/domain/score/score_repository.dart';

/// 「2 拍の単旋律」— ロジックテスト用の最小曲。本番データに依存しない。
Piece twoBeatMelody() => Piece(
  id: 'fixture-two-beat',
  title: '2 拍の単旋律',
  composer: 'テスト',
  stars: 1,
  notes: const [
    Note(pitch: 'C4', beat: 0, duration: 1),
    Note(pitch: 'E4', beat: 1, duration: 1),
  ],
);

/// 空の自作曲。
Piece emptyUserPiece() => Piece(
  id: 'fixture-empty',
  title: '無題の楽譜',
  composer: '自作',
  notes: const [],
  isUserCreated: true,
);

/// 最小 fixture を返す `ScoreRepository`。
class FixtureScoreRepository implements ScoreRepository {
  @override
  Piece featured() => twoBeatMelody();

  @override
  List<Piece> samplePieces() => [
    twoBeatMelody().copyWith(id: 'fixture-a', title: '曲 A'),
    twoBeatMelody().copyWith(id: 'fixture-b', title: '曲 B'),
  ];
}
