import 'package:etude/src/ui/widgets/piano_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<String>> pumpAndCapture(
    WidgetTester tester, {
    int startOctave = 3,
  }) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PianoKeyboard(
            startOctave: startOctave,
            onNotePressed: pressed.add,
          ),
        ),
      ),
    );
    return pressed;
  }

  testWidgets('白鍵タップでその音高が通知される', (tester) async {
    final pressed = await pumpAndCapture(tester);
    await tester.tap(find.byKey(const ValueKey('key-C3')));
    expect(pressed, ['C3']);
  });

  testWidgets('黒鍵タップで ♯ 付き音高が通知される', (tester) async {
    final pressed = await pumpAndCapture(tester);
    await tester.tap(find.byKey(const ValueKey('key-C#3')));
    expect(pressed, ['C#3']);
  });

  testWidgets('鍵盤に意味ラベル(Semantics)が付く', (tester) async {
    await pumpAndCapture(tester);
    // C 鍵は音名ラベルの Text も持つため、ラベルのみの D3 で検証する。
    expect(find.bySemanticsLabel('D3'), findsOneWidget);
  });

  testWidgets('litPitches で該当鍵が点灯色になり、範囲外は無視される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PianoKeyboard(
            onNotePressed: (_) {},
            litPitches: const {'C3', 'C9'}, // C9 は表示範囲外 → 無視される
          ),
        ),
      ),
    );

    Color firstColor(String pitch) {
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byKey(ValueKey('key-$pitch')),
          matching: find.byType(Container),
        ),
      );
      return ((box.decoration! as BoxDecoration).gradient! as LinearGradient)
          .colors
          .first;
    }

    expect(firstColor('C3'), const Color(0xFFF3DCA4)); // 点灯色
    expect(firstColor('D3'), const Color(0xFFF7F1E4)); // 通常色
  });

  // ---- レスポンシブ(タブレット対応) ----
  // 端末サイズ自体を変えて検証する(SizedBox では既定 800 幅にクランプされるため)。
  Future<void> pumpBoard(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PianoKeyboard(onNotePressed: (_) {}, height: height),
        ),
      ),
    );
  }

  Size whiteKeySize(WidgetTester tester) =>
      tester.getSize(find.byKey(const ValueKey('key-C3')));

  testWidgets('広い画面(タブレット)では白鍵が既定幅より広がる', (tester) async {
    await pumpBoard(tester, width: 1200, height: 300);
    final w = whiteKeySize(tester).width;
    // 21 白鍵 → 1200/21 ≈ 57。既定40より広く、上限72以下。収まるのでスクロールしない。
    expect(w, greaterThan(50));
    expect(w, lessThanOrEqualTo(72));
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('狭い画面では既定幅のまま横スクロールする', (tester) async {
    await pumpBoard(tester, width: 300, height: 200);
    expect(whiteKeySize(tester).width, moreOrLessEquals(40, epsilon: 0.5));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('高さは鍵幅に対する比率で頭打ち、鍵盤は下端に揃う', (tester) async {
    // 高さ 600 を与えても 白鍵幅(≈57)×5 ≈ 285 で頭打ち。
    await pumpBoard(tester, width: 1200, height: 600);
    expect(whiteKeySize(tester).height, lessThan(320));
    // 余白は上側にでき、鍵盤は画面下端に接する(中央寄せにならない)。
    final board = tester.getRect(find.byType(PianoKeyboard));
    final key = tester.getRect(find.byKey(const ValueKey('key-C3')));
    expect(key.bottom, moreOrLessEquals(board.bottom, epsilon: 1));
  });
}
