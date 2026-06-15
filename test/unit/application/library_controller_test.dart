import 'package:etude/src/application/library_controller.dart';
import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/piece.dart';
import 'package:etude/src/domain/score/score_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/in_memory_library_store.dart';

void main() {
  LibraryController build({InMemoryLibraryStore? store}) => LibraryController(
    repository: FixtureScoreRepository(),
    store: store ?? InMemoryLibraryStore(),
  );

  group('LibraryController', () {
    test('初期化時に収録曲で seed され、featured も一覧に含む', () {
      final controller = build();
      expect(controller.featured.id, 'fixture-two-beat');
      expect(controller.pieces.map((p) => p.id), [
        'fixture-two-beat',
        'fixture-a',
        'fixture-b',
      ]);
    });

    test('restore は保存済みコレクションで置き換える', () async {
      final store = InMemoryLibraryStore([emptyUserPiece()]);
      final controller = build(store: store);

      await controller.restore();

      // featured が無い保存データには featured を補い、一覧に含める。
      expect(controller.featured.id, 'fixture-two-beat');
      expect(controller.pieces.map((p) => p.id), [
        'fixture-two-beat',
        'fixture-empty',
      ]);
    });

    test('restore は保存が空なら seed を保つ', () async {
      final controller = build();
      await controller.restore();
      expect(controller.pieces, hasLength(3));
    });

    test('createPiece は自作曲を追加し、永続化し、通知する', () async {
      final store = InMemoryLibraryStore();
      final controller = build(store: store);
      var notified = 0;
      controller.addListener(() => notified++);

      final created = await controller.createPiece();

      expect(created.isUserCreated, isTrue);
      expect(controller.pieces.last.id, created.id);
      expect(controller.pieces, hasLength(4));
      expect(store.saveCount, 1);
      expect(store.saved!.last.id, created.id);
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('createPiece の id は一意', () async {
      final controller = build();
      final a = await controller.createPiece();
      final b = await controller.createPiece();
      expect(a.id, isNot(b.id));
    });

    test('savePiece は同じ id を置き換え、永続化する', () async {
      final store = InMemoryLibraryStore();
      final controller = build(store: store);

      await controller.savePiece(
        twoBeatMelody().copyWith(id: 'fixture-a', title: '編集済み'),
      );

      expect(
        controller.pieces.firstWhere((p) => p.id == 'fixture-a').title,
        '編集済み',
      );
      expect(store.saved!.any((p) => p.title == '編集済み'), isTrue);
    });

    test('savePiece は未知の id を追加する', () async {
      final controller = build();
      await controller.savePiece(emptyUserPiece());
      expect(controller.pieces.any((p) => p.id == 'fixture-empty'), isTrue);
    });

    test('createPiece は復元後も既存 user id と衝突しない', () async {
      final existing = emptyUserPiece().copyWith(id: 'user-1', title: '既存');
      final controller = build(store: InMemoryLibraryStore([existing]));
      await controller.restore();

      final created = await controller.createPiece();

      expect(created.id, isNot('user-1'));
      // 既存の user-1 が上書きされていない。
      expect(controller.pieces.where((p) => p.id == 'user-1'), hasLength(1));
    });

    test('restore は収録曲の fullNotes をデータ側から再注入する', () async {
      // 保存データには fullNotes が無い(永続化しない設計)が、id 一致の収録曲は
      // リポジトリ側の fullNotes を補う。
      final store = InMemoryLibraryStore([
        Piece(
          id: 'feat',
          title: '編集済み',
          composer: 'c',
          notes: const [Note(pitch: 'C4', beat: 0, duration: 1)],
        ),
      ]);
      final controller = LibraryController(
        repository: _RepoWithFull(),
        store: store,
      );

      await controller.restore();

      expect(controller.featured.id, 'feat');
      expect(controller.featured.fullNotes, hasLength(1)); // 再注入された
    });
  });
}

/// fullNotes を持つ収録曲を1曲だけ返すテスト用リポジトリ。
class _RepoWithFull implements ScoreRepository {
  static final _feat = Piece(
    id: 'feat',
    title: 'F',
    composer: 'c',
    notes: const [Note(pitch: 'C4', beat: 0, duration: 1)],
    fullNotes: const [Note(pitch: 'C3', beat: 0, duration: 1)],
  );

  @override
  Piece featured() => _feat;

  @override
  List<Piece> samplePieces() => const [];

  @override
  Piece? original(String id) => id == _feat.id ? _feat : null;
}
