import 'package:etude/src/application/editor_controller.dart';
import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/piece.dart';
import 'package:etude/src/ui/editor/editor_screen.dart';
import 'package:etude/src/ui/practice/practice_screen.dart';
import 'package:etude/src/ui/widgets/score_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/recording_audio_engine.dart';

/// 横スクロールできる長さの旋律(0.25 拍ごとに音→onset が頻繁に出る)。
Piece longMelody() => Piece(
  id: 'fixture-long',
  title: '長い旋律',
  composer: 'テスト',
  notes: [
    for (var i = 0; i < 160; i++)
      Note(pitch: i.isEven ? 'C4' : 'E4', beat: i * 0.25, duration: 0.25),
  ],
);

/// 再生中に追従アニメ(animateTo)を実際に駆動するため、小刻みに pump する。
Future<void> pumpSteps(
  WidgetTester tester, {
  int steps = 12,
  int ms = 50,
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

void main() {
  testWidgets('再生中に手動スクロールしたら追従で戻らない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(
          piece: longMelody(),
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );

    // 再生開始(再生ヘッドは先頭=拍0付近)。
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 50));

    final scrollable = find.descendant(
      of: find.byType(ScoreView),
      matching: find.byType(Scrollable),
    );

    // ユーザーが先の小節を見ようと右へスクロール(content を左へドラッグ)。
    await tester.drag(scrollable, const Offset(-300, 0));
    await tester.pump();

    final offsetAfterDrag = tester.getTopLeft(
      find
          .descendant(
            of: find.byType(ScoreView),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    // 再生ヘッドが進んで次の音が鳴る(litPitches 更新→追従が走りうる)まで待つ。
    await pumpSteps(tester);

    final offsetAfterPlay = tester.getTopLeft(
      find
          .descendant(
            of: find.byType(ScoreView),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    // 停止(pending timer を残さない)。
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();

    // 追従が止まっていれば、手動スクロール位置から大きくは戻らない。
    expect(
      (offsetAfterPlay.dx - offsetAfterDrag.dx).abs(),
      lessThan(40),
      reason: '手動スクロール後に再生ヘッド追従で位置が戻ってしまっている',
    );
  });

  testWidgets('エディタ試聴中に手動スクロールしたら追従で戻らない', (tester) async {
    final controller = EditorController(piece: longMelody());
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(
          controller: controller,
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );

    // 試聴開始(再生ヘッドは先頭付近)。
    await tester.tap(find.widgetWithText(TextButton, '試聴'));
    await tester.pump(const Duration(milliseconds: 50));

    final scrollable = find.descendant(
      of: find.byType(ScoreView),
      matching: find.byType(Scrollable),
    );

    await tester.drag(scrollable, const Offset(-300, 0));
    await tester.pump();

    final offsetAfterDrag = tester.getTopLeft(
      find
          .descendant(
            of: find.byType(ScoreView),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    await pumpSteps(tester);

    final offsetAfterPlay = tester.getTopLeft(
      find
          .descendant(
            of: find.byType(ScoreView),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    await tester.tap(find.widgetWithText(TextButton, '停止'));
    await tester.pump();

    expect(
      (offsetAfterPlay.dx - offsetAfterDrag.dx).abs(),
      lessThan(40),
      reason: '試聴中の手動スクロール後に再生ヘッド追従で位置が戻ってしまっている',
    );
  });
}
