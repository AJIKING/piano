import 'package:etude/src/ui/practice/practice_screen.dart';
import 'package:etude/src/ui/widgets/score_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/recording_audio_engine.dart';

void main() {
  testWidgets('曲名・譜面・鍵盤を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );

    expect(find.text('2 拍の単旋律'), findsOneWidget);
    expect(find.byType(ScoreView), findsOneWidget);
  });

  testWidgets('鍵盤タップで発音する', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(piece: twoBeatMelody(), audioEngine: audio),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('key-C3')));
    expect(audio.playedPitches, ['C3']);
  });

  testWidgets('再生ボタンで再生→停止できる(保留タイマーを残さない)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );

    // 再生開始 → 停止アイコンに変わる。
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    // 停止 → タイマーを後始末(pending timer を残さない)。
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
