import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/piece.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';

void main() {
  group('Piece', () {
    test('contentEnd は最後の音符の終端拍', () {
      final piece = Piece(
        id: 'p',
        title: 't',
        composer: 'c',
        notes: const [
          Note(pitch: 'C4', beat: 0, duration: 1),
          Note(pitch: 'E4', beat: 2, duration: 3),
        ],
      );
      expect(piece.contentEnd, 5);
    });

    test('空の旋律の contentEnd は 0', () {
      expect(emptyUserPiece().contentEnd, 0);
    });

    test('sortedNotes は beat 昇順', () {
      final piece = Piece(
        id: 'p',
        title: 't',
        composer: 'c',
        notes: const [
          Note(pitch: 'C4', beat: 2, duration: 1),
          Note(pitch: 'E4', beat: 0, duration: 1),
        ],
      );
      expect(piece.sortedNotes.map((n) => n.beat), [0, 2]);
      // 元の notes は変更しない。
      expect(piece.notes.first.beat, 2);
    });

    test('sortedNotes は同 beat を音高順に整列(安定ソートに依存しない全順序)', () {
      final piece = Piece(
        id: 'p',
        title: 't',
        composer: 'c',
        notes: const [
          Note(pitch: 'G4', beat: 0, duration: 1),
          Note(pitch: 'C4', beat: 0, duration: 1),
          Note(pitch: 'E4', beat: 0, duration: 1),
        ],
      );
      expect(piece.sortedNotes.map((n) => n.pitch), ['C4', 'E4', 'G4']);
    });

    test('copyWith は指定フィールドだけ差し替える', () {
      final updated = twoBeatMelody().copyWith(title: '改名');
      expect(updated.title, '改名');
      expect(updated.id, 'fixture-two-beat');
    });

    test('JSON 往復で主要フィールドが保たれる', () {
      final piece = twoBeatMelody().copyWith(
        beatsPerMeasure: 4,
        defaultBpm: 96,
      );
      final restored = Piece.fromJson(piece.toJson());
      expect(restored.id, piece.id);
      expect(restored.beatsPerMeasure, 4);
      expect(restored.defaultBpm, 96);
      expect(restored.notes, piece.notes);
    });

    test('旧スキーマの JSON も読める(余分キーは無視・欠損は既定値)', () {
      // 旧バージョンの保存データ: 廃止した stars/masteryPercent/lastPracticedAt を
      // 含み、追加した beatsPerMeasure/defaultBpm を含まない。
      final oldJson = <String, Object?>{
        'id': 'old-1',
        'title': '旧データ',
        'composer': '作者',
        'stars': 4,
        'masteryPercent': 80,
        'lastPracticedAt': '2026-01-02T10:30:00.000',
        'isUserCreated': true,
        'notes': [
          {'pitch': 'C4', 'beat': 0, 'duration': 1},
        ],
      };

      final p = Piece.fromJson(oldJson); // 例外を投げない
      expect(p.id, 'old-1');
      expect(p.isUserCreated, isTrue);
      expect(p.beatsPerMeasure, 3); // 欠損 → 既定
      expect(p.defaultBpm, 72); // 欠損 → 既定
      expect(p.notes, hasLength(1));
    });
  });
}
