import 'package:etude/src/application/editor_controller.dart';
import 'package:etude/src/application/library_controller.dart';
import 'package:etude/src/data/bundled_score_repository.dart';
import 'package:etude/src/ui/editor/editor_screen.dart';
import 'package:etude/src/ui/library/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/in_memory_library_store.dart';
import '../../fixtures/localized_app.dart';
import '../../fixtures/recording_audio_engine.dart';

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

  testWidgets('エディタの曲名入力欄も収録曲は表示言語で出る', (tester) async {
    // 収録曲(featured = きらきら星 / twinkle-star)を英語で編集画面に開く。
    final editor = EditorController(
      piece: const BundledScoreRepository().featured(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: EditorScreen(
          controller: editor,
          audioEngine: RecordingAudioEngine(),
        ),
        locale: const Locale('en'),
      ),
    );
    // タイトル入力欄が日本語ではなく英語の曲名で初期表示される。
    expect(
      find.widgetWithText(TextField, 'Twinkle Twinkle Little Star'),
      findsOneWidget,
    );
    expect(find.text('きらきら星'), findsNothing);
  });
}
