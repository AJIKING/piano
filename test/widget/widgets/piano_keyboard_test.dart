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
}
