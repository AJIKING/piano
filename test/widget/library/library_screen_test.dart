import 'package:etude/src/application/library_controller.dart';
import 'package:etude/src/ui/library/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fake_clock.dart';
import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/in_memory_library_store.dart';
import '../../fixtures/recording_audio_engine.dart';

void main() {
  LibraryController buildController() => LibraryController(
    repository: FixtureScoreRepository(),
    store: InMemoryLibraryStore(),
    clock: FakeClock(DateTime(2026, 1, 1)),
  );

  Widget wrap(LibraryController controller) => MaterialApp(
    home: LibraryScreen(
      controller: controller,
      audioEngine: RecordingAudioEngine(),
    ),
  );

  testWidgets('featured カードと収録曲一覧を表示する', (tester) async {
    final controller = buildController();
    await tester.pumpWidget(wrap(controller));

    expect(find.text('今練習中'), findsOneWidget);
    expect(find.text('2 拍の単旋律'), findsOneWidget); // featured
    expect(find.text('曲 A'), findsOneWidget);
    expect(find.text('曲 B'), findsOneWidget);
    expect(find.text('マイ楽譜'), findsOneWidget);
  });

  testWidgets('曲をタップすると練習画面へ遷移する', (tester) async {
    final controller = buildController();
    await tester.pumpWidget(wrap(controller));

    await tester.tap(find.text('曲 A'));
    await tester.pumpAndSettle();

    // 練習画面へ遷移(テンポスライダーは練習画面にのみ存在する)。
    expect(find.byType(Slider), findsOneWidget);
    expect(find.widgetWithText(AppBar, '曲 A'), findsOneWidget);
  });

  testWidgets('楽譜を作成すると曲が増えてエディタへ遷移する', (tester) async {
    final controller = buildController();
    await tester.pumpWidget(wrap(controller));

    await tester.tap(find.text('楽譜を作成'));
    await tester.pumpAndSettle();

    expect(controller.pieces, hasLength(3));
    // 楽譜エディタへ遷移(曲名フィールドに「無題の楽譜」)。
    expect(find.text('楽譜エディタ'), findsOneWidget);
    expect(find.widgetWithText(TextField, '無題の楽譜'), findsOneWidget);
  });

  testWidgets('エディタで追加した音符が戻る時に永続化される', (tester) async {
    final store = InMemoryLibraryStore();
    final controller = LibraryController(
      repository: FixtureScoreRepository(),
      store: store,
      clock: FakeClock(DateTime(2026, 1, 1)),
    );
    await tester.pumpWidget(wrap(controller));

    // 曲 A の編集を開く(fixture-a は最初 2 音符)。
    await tester.tap(find.byTooltip('編集').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();

    // 戻る → dispose で保存される。
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(store.saveCount, greaterThanOrEqualTo(1));
    final saved = controller.pieces.firstWhere((p) => p.id == 'fixture-a');
    expect(saved.notes, hasLength(3));
  });
}
