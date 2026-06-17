import 'package:etude/src/application/library_controller.dart';
import 'package:etude/src/data/bundled_score_repository.dart';
import 'package:etude/src/ui/library/library_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/in_memory_library_store.dart';
import '../../fixtures/localized_app.dart';

/// 多言語対応(日本語 / 英語 / 簡体字中国語)の検証。
/// ロケールに応じて UI 文言と収録曲名が切り替わることを確認する。
void main() {
  LibraryScreen libraryScreen() => LibraryScreen(
    controller: LibraryController(
      repository: const BundledScoreRepository(),
      store: InMemoryLibraryStore(),
    ),
    onOpenPractice: (_) {},
    onOpenEditor: (_) {},
  );

  testWidgets('日本語: UI と曲名が日本語', (tester) async {
    await tester.pumpWidget(
      localizedApp(home: libraryScreen(), locale: const Locale('ja')),
    );
    expect(find.text('ライブラリ'), findsOneWidget);
    expect(find.text('楽譜を作成'), findsOneWidget);
    expect(find.text('きらきら星'), findsOneWidget); // featured
    expect(find.text('フランス民謡'), findsWidgets);
  });

  testWidgets('英語: UI と曲名が英語', (tester) async {
    await tester.pumpWidget(
      localizedApp(home: libraryScreen(), locale: const Locale('en')),
    );
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Create score'), findsOneWidget);
    expect(find.text('Twinkle Twinkle Little Star'), findsOneWidget);
    expect(find.text('French folk song'), findsWidgets);
    // 日本語表記は出ない。
    expect(find.text('ライブラリ'), findsNothing);
  });

  testWidgets('簡体字中国語: UI と曲名が中国語', (tester) async {
    await tester.pumpWidget(
      localizedApp(home: libraryScreen(), locale: const Locale('zh')),
    );
    expect(find.text('乐谱库'), findsOneWidget);
    expect(find.text('新建乐谱'), findsOneWidget);
    expect(find.text('小星星'), findsOneWidget);
    expect(find.text('法国民谣'), findsWidgets);
  });
}
