import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/ui/widgets/grand_staff_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 低音(ヘ音譜表)〜高音(ト音譜表)＋中央 C をまたぐ両手音符。
  const twoHand = [
    Note(pitch: 'C3', beat: 0, duration: 1), // ヘ音譜表
    Note(pitch: 'G3', beat: 0, duration: 1),
    Note(pitch: 'C4', beat: 1, duration: 1), // 中央 C(加線)
    Note(pitch: 'E4', beat: 1, duration: 1), // ト音譜表
    Note(pitch: 'G4', beat: 2, duration: 2),
    Note(pitch: 'C5', beat: 4, duration: 1),
  ];

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('両手にまたがる音符を例外なく描画する', (tester) async {
    await tester.pumpWidget(
      wrap(const GrandStaffView(notes: twoHand, beatsPerMeasure: 4)),
    );

    expect(find.byType(GrandStaffView), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('再生ヘッドと発音中ハイライトを付けても描画できる', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GrandStaffView(
          notes: twoHand,
          beatsPerMeasure: 4,
          litNoteIndices: {2, 3},
          playheadX: 120,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('空でも落ちない', (tester) async {
    await tester.pumpWidget(wrap(const GrandStaffView(notes: [])));
    expect(tester.takeException(), isNull);
  });
}
