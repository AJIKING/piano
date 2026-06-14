import 'package:etude/src/application/dependencies.dart';
import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_clock.dart';
import '../fixtures/fixture_pieces.dart';
import '../fixtures/in_memory_library_store.dart';
import '../fixtures/recording_audio_engine.dart';

void main() {
  ({Widget app, InMemoryLibraryStore store}) build([InMemoryLibraryStore? s]) {
    final store = s ?? InMemoryLibraryStore();
    final deps = Dependencies(
      clock: FakeClock(DateTime(2026, 1, 1)),
      scoreRepository: FixtureScoreRepository(),
      libraryStore: store,
      audioEngine: RecordingAudioEngine(),
    );
    return (app: MaterialApp(home: AppShell(dependencies: deps)), store: store);
  }

  testWidgets('レールの 4 タブと初期ライブラリを表示する', (tester) async {
    await tester.pumpWidget(build().app);
    await tester.pumpAndSettle();

    for (final label in ['楽譜', '練習', '編集', '演奏']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('ライブラリ'), findsOneWidget);
  });

  testWidgets('レールは開閉できる', (tester) async {
    await tester.pumpWidget(build().app);
    await tester.pumpAndSettle();
    expect(find.text('練習'), findsOneWidget); // 開いている=ラベル表示

    await tester.tap(find.byIcon(Icons.menu_open)); // 閉じる
    await tester.pumpAndSettle();
    expect(find.text('練習'), findsNothing); // ラベルが消える
    expect(find.byIcon(Icons.menu), findsOneWidget); // 開くボタン

    await tester.tap(find.byIcon(Icons.menu)); // 開く
    await tester.pumpAndSettle();
    expect(find.text('練習'), findsOneWidget);
  });

  testWidgets('レールで演奏タブへ切り替えられる', (tester) async {
    await tester.pumpWidget(build().app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('演奏'));
    await tester.pumpAndSettle();

    expect(find.text('自由演奏'), findsOneWidget);
  });

  testWidgets('曲をタップすると練習タブが開く', (tester) async {
    await tester.pumpWidget(build().app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('曲 A'));
    await tester.pumpAndSettle();

    // 練習画面のみテンポスライダーを持つ。
    expect(find.byType(Slider), findsOneWidget);
    expect(find.widgetWithText(AppBar, '曲 A'), findsOneWidget);
  });

  testWidgets('編集タブで追加した音符が、タブ移動時に永続化される', (tester) async {
    final built = build();
    await tester.pumpWidget(built.app);
    await tester.pumpAndSettle();

    // 編集タブへ(既定の編集対象は featured = fixture-two-beat の 2 音符)。
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.text('音符数: 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();
    expect(find.text('音符数: 3'), findsOneWidget);

    // 楽譜タブへ戻る → 編集タブを離れる時に保存される。
    await tester.tap(find.text('楽譜'));
    await tester.pumpAndSettle();

    expect(built.store.saveCount, greaterThanOrEqualTo(1));
    final saved = built.store.saved!;
    final featured = saved.firstWhere((p) => p.id == 'fixture-two-beat');
    expect(featured.notes, hasLength(3));
  });

  testWidgets('別の曲を編集タブで開くと曲名・音符数が切り替わる', (tester) async {
    await tester.pumpWidget(build().app);
    await tester.pumpAndSettle();

    // featured(2 音符)を編集タブで開き、1 音追加して 3 音符に。
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();
    expect(find.text('音符数: 3'), findsOneWidget);

    // 楽譜タブへ戻り、曲 A(2 音符)の編集を開く。
    await tester.tap(find.text('楽譜'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('編集').first); // 曲 A
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '曲 A'), findsOneWidget);
    expect(find.text('音符数: 2'), findsOneWidget);
  });

  testWidgets('再起動時、保存済み featured の編集が編集タブに反映される', (tester) async {
    // 前回 featured を 3 音符に編集して保存した状態を再現。
    final editedFeatured = twoBeatMelody().copyWith(
      notes: const [
        Note(pitch: 'C4', beat: 0, duration: 1),
        Note(pitch: 'E4', beat: 1, duration: 1),
        Note(pitch: 'G4', beat: 2, duration: 1),
      ],
    );
    final store = InMemoryLibraryStore([editedFeatured]);

    await tester.pumpWidget(build(store).app);
    await tester.pumpAndSettle(); // restore 完了 → _editor を読み直す

    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();

    expect(find.text('音符数: 3'), findsOneWidget);
  });
}
