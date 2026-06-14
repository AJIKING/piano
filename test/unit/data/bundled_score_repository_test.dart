import 'package:etude/src/data/bundled_score_repository.dart';
import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/piece.dart';
import 'package:flutter_test/flutter_test.dart';

/// 収録曲データの contract test(ADR 0003)。本番データの不変条件を守る。
void main() {
  const repo = BundledScoreRepository();

  List<Piece> allPieces() => [repo.featured(), ...repo.samplePieces()];

  test('featured と収録曲が存在する', () {
    expect(repo.featured().title, isNotEmpty);
    expect(repo.samplePieces(), isNotEmpty);
  });

  test('id は全曲で一意', () {
    final ids = allPieces().map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('original は id で初期版を返し、未知 id は null', () {
    expect(repo.original(repo.featured().id)?.id, repo.featured().id);
    expect(repo.original(repo.samplePieces().first.id), isNotNull);
    expect(repo.original('user-999'), isNull);
  });

  test('stars は 0–5', () {
    for (final p in allPieces()) {
      expect(p.stars, inInclusiveRange(0, 5), reason: p.id);
    }
  });

  test('全音符が妥当（音名・音価・非負拍）', () {
    for (final p in allPieces()) {
      for (final n in p.notes) {
        expect(n.isValid, isTrue, reason: '${p.id}: $n');
        expect(
          Note.allowedDurations,
          contains(n.duration),
          reason: '${p.id}: $n',
        );
      }
    }
  });

  test('旋律は beat 昇順に整列できる（整列後に逆行しない）', () {
    for (final p in allPieces()) {
      final beats = p.sortedNotes.map((n) => n.beat).toList();
      for (var i = 1; i < beats.length; i++) {
        expect(beats[i], greaterThanOrEqualTo(beats[i - 1]), reason: p.id);
      }
    }
  });
}
