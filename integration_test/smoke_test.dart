import 'package:etude/main_test.dart' as app;
import 'package:etude/src/ui/widgets/score_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// smoke journey(docs/test-plan.md の Integration smoke):
/// 起動 → ライブラリに収録曲が表示される → 曲をタップ → 練習画面が開く。
///
/// 実行にはエミュレータ / シミュレータが必要:
/// `flutter test integration_test -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('起動 → ライブラリ → 曲をタップ → 練習画面', (tester) async {
    app.runTestApp();
    await tester.pumpAndSettle();

    // ライブラリ表示の確認(収録曲が並ぶ)。
    expect(find.text('ライブラリ'), findsOneWidget);

    // 収録曲の 1 つ(featured)をタップ → 練習画面へ。
    final firstPiece = find.text('エリーゼのために');
    await tester.scrollUntilVisible(
      firstPiece,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(firstPiece);
    await tester.pumpAndSettle();

    // 練習画面が開く(譜面が描画される)。
    expect(find.byType(ScoreView), findsOneWidget);
  });
}
