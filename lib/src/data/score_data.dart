import '../domain/score/note.dart';
import '../domain/score/piece.dart';

/// 収録曲データ本体(ADR 0003: 同梱 Dart コード)。
///
/// プロトタイプ `docs/prototype/etude-piano-app.html` の `DEFAULT` 旋律と
/// 曲リストを移植したもの。プロトタイプでは全曲が同じデモ旋律を共有しているため、
/// 本実装では曲ごとの実旋律へ順次差し替える(contract test が不変条件を守る)。

/// プロトタイプの `DEFAULT`(ジムノペディ風のデモ旋律。ハ長調・3/4 拍子)。
const List<Note> demoMelody = [
  Note(pitch: 'E4', beat: 0, duration: 1),
  Note(pitch: 'G4', beat: 1, duration: 1),
  Note(pitch: 'C5', beat: 2, duration: 1),
  Note(pitch: 'B4', beat: 3, duration: 1),
  Note(pitch: 'G4', beat: 4, duration: 1),
  Note(pitch: 'E4', beat: 5, duration: 1),
  Note(pitch: 'A4', beat: 6, duration: 2),
  Note(pitch: 'G4', beat: 8, duration: 1),
  Note(pitch: 'F4', beat: 9, duration: 1),
  Note(pitch: 'A4', beat: 10, duration: 1),
  Note(pitch: 'D5', beat: 11, duration: 1),
  Note(pitch: 'C5', beat: 12, duration: 3),
  Note(pitch: 'D4', beat: 15, duration: 1),
  Note(pitch: 'F4', beat: 16, duration: 1),
  Note(pitch: 'A4', beat: 17, duration: 1),
  Note(pitch: 'G4', beat: 18, duration: 2),
  Note(pitch: 'E4', beat: 20, duration: 1),
  Note(pitch: 'C4', beat: 21, duration: 1),
  Note(pitch: 'E4', beat: 22, duration: 1),
  Note(pitch: 'G4', beat: 23, duration: 1),
  Note(pitch: 'C5', beat: 24, duration: 3),
];

/// 「今練習中」の既定曲。
Piece buildFeaturedPiece() => Piece(
  id: 'gymnopedie-1',
  title: 'ジムノペディ 第1番',
  composer: 'エリック・サティ',
  stars: 3,
  masteryPercent: 64,
  notes: List<Note>.of(demoMelody),
);

/// マイ楽譜の初期コレクション(featured は含めない)。
List<Piece> buildSamplePieces() => [
  Piece(
    id: 'nocturne-2',
    title: 'ノクターン 第2番 変ホ長調',
    composer: 'F. ショパン',
    stars: 4,
    notes: List<Note>.of(demoMelody),
  ),
  Piece(
    id: 'clair-de-lune',
    title: '月の光',
    composer: 'C. ドビュッシー',
    stars: 5,
    notes: List<Note>.of(demoMelody),
  ),
  Piece(
    id: 'traumerei',
    title: 'トロイメライ',
    composer: 'R. シューマン',
    stars: 3,
    notes: List<Note>.of(demoMelody),
  ),
  Piece(
    id: 'fur-elise',
    title: 'エリーゼのために',
    composer: 'L.v. ベートーヴェン',
    stars: 2,
    notes: List<Note>.of(demoMelody),
  ),
  Piece(
    id: 'jesu-joy',
    title: '主よ、人の望みの喜びよ',
    composer: 'J.S. バッハ',
    stars: 4,
    notes: List<Note>.of(demoMelody),
  ),
  Piece(
    id: 'je-te-veux',
    title: 'ジュ・トゥ・ヴ',
    composer: 'E. サティ',
    stars: 3,
    notes: List<Note>.of(demoMelody),
  ),
];
