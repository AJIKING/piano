import 'package:etude/src/application/library_controller.dart';
import 'package:etude/src/domain/score/piece.dart';
import 'package:etude/src/ui/library/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fake_clock.dart';
import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/in_memory_library_store.dart';

void main() {
  LibraryController buildController() => LibraryController(
    repository: FixtureScoreRepository(),
    store: InMemoryLibraryStore(),
    clock: FakeClock(DateTime(2026, 1, 1)),
  );

  Widget wrap(
    LibraryController controller, {
    void Function(Piece)? onOpenPractice,
    void Function(Piece)? onOpenEditor,
  }) => MaterialApp(
    home: LibraryScreen(
      controller: controller,
      onOpenPractice: onOpenPractice ?? (_) {},
      onOpenEditor: onOpenEditor ?? (_) {},
    ),
  );

  testWidgets('収録曲一覧を表示する(featured も含む)', (tester) async {
    await tester.pumpWidget(wrap(buildController()));

    expect(find.text('2 拍の単旋律'), findsOneWidget); // featured も一覧に
    expect(find.text('曲 A'), findsOneWidget);
    expect(find.text('曲 B'), findsOneWidget);
    // 「今練習中」カードは廃止。
    expect(find.text('今練習中'), findsNothing);
  });

  testWidgets('曲タップで onOpenPractice にその曲が渡る', (tester) async {
    Piece? opened;
    await tester.pumpWidget(
      wrap(buildController(), onOpenPractice: (p) => opened = p),
    );

    await tester.tap(find.text('曲 A'));
    expect(opened?.id, 'fixture-a');
  });

  testWidgets('編集ボタンで onOpenEditor にその曲が渡る', (tester) async {
    Piece? edited;
    await tester.pumpWidget(
      wrap(buildController(), onOpenEditor: (p) => edited = p),
    );

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, '曲 A'),
        matching: find.byTooltip('編集'),
      ),
    );
    expect(edited?.id, 'fixture-a');
  });

  testWidgets('楽譜を作成で曲が増え、onOpenEditor に新曲が渡る', (tester) async {
    final controller = buildController();
    Piece? edited;
    await tester.pumpWidget(wrap(controller, onOpenEditor: (p) => edited = p));

    await tester.tap(find.text('楽譜を作成'));
    await tester.pumpAndSettle();

    expect(controller.pieces, hasLength(4));
    expect(edited?.isUserCreated, isTrue);
  });
}
