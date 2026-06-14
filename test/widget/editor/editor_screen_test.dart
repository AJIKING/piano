import 'package:etude/src/ui/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/recording_audio_engine.dart';

void main() {
  testWidgets('曲名・ツールバー・音符数を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(
          piece: emptyUserPiece(),
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );

    expect(find.widgetWithText(TextField, '無題の楽譜'), findsOneWidget);
    expect(find.text('音符数: 0'), findsOneWidget);
    expect(find.text('♯'), findsOneWidget);
  });

  testWidgets('鍵盤タップで音符が増え、発音する', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(piece: emptyUserPiece(), audioEngine: audio),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();

    expect(audio.playedPitches, ['C3']);
    expect(find.text('音符数: 1'), findsOneWidget);
  });

  testWidgets('練習するで練習画面へ遷移する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );

    await tester.tap(find.text('練習する'));
    await tester.pumpAndSettle();

    // 練習画面のみテンポスライダーを持つ。
    expect(find.byType(Slider), findsOneWidget);
  });
}
