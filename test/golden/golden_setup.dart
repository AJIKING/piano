import 'dart:io';

import 'package:etude/src/ui/theme/etude_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// golden の基準 platform は CI と同じ Linux(ADR 0002)。
/// Windows / macOS はフォントレンダリングが Linux と一致せず、platform 差由来の
/// 差分で必ず失敗するため、非 Linux では自動 skip する。これによりローカル
/// (Windows 開発機)の `flutter test` は全 green を保つ。
final bool skipGoldens = !Platform.isLinux;

/// pubspec.yaml で宣言したカスタムフォントをすべてロードする。
/// golden ではフォント未ロードだと文字がプレースホルダ(Ahem)で描画され
/// 視覚契約として意味をなさないため、`setUpAll` で必ず呼ぶ。
Future<void> loadEtudeFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadFamily(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await loadFamily('ShipporiMincho', [
    'assets/fonts/ShipporiMincho-Medium.ttf',
    'assets/fonts/ShipporiMincho-Bold.ttf',
    'assets/fonts/ShipporiMincho-ExtraBold.ttf',
  ]);
  await loadFamily('ZenKakuGothicNew', [
    'assets/fonts/ZenKakuGothicNew-Regular.ttf',
    'assets/fonts/ZenKakuGothicNew-Medium.ttf',
    'assets/fonts/ZenKakuGothicNew-Bold.ttf',
  ]);
  await loadFamily('IBMPlexMono', [
    'assets/fonts/IBMPlexMono-Medium.ttf',
    'assets/fonts/IBMPlexMono-SemiBold.ttf',
  ]);
}

/// golden の固定条件(device size / text scale 1.0 / theme)で [child] を
/// pump する。surface は [size] に固定し、devicePixelRatio は 1.0 にする。
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EtudeTheme.dark(),
      // text scale を端末設定に依存させない(golden の固定条件)。
      builder: (context, inner) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: inner!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// pump 済みの画面(theme 背景込みの Scaffold 全体)を
/// `test/golden/goldens/<name>.png` の baseline と比較する。
Future<void> expectGolden(WidgetTester tester, String name) =>
    expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/$name.png'));
