import 'package:etude/src/application/editor_controller.dart';
import 'package:etude/src/ui/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/recording_audio_engine.dart';

void main() {
  Widget wrap(
    EditorController controller, {
    RecordingAudioEngine? audio,
    VoidCallback? onPractice,
  }) => MaterialApp(
    home: EditorScreen(
      controller: controller,
      audioEngine: audio ?? RecordingAudioEngine(),
      onPractice: onPractice,
    ),
  );

  testWidgets('曲名・ツールバー・音符数を表示する', (tester) async {
    await tester.pumpWidget(wrap(EditorController(piece: emptyUserPiece())));

    expect(find.widgetWithText(TextField, '無題の楽譜'), findsOneWidget);
    expect(find.text('音符数: 0'), findsOneWidget);
    expect(find.text('♯'), findsOneWidget);
  });

  testWidgets('鍵盤タップで音符が増え、発音する', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(
      wrap(EditorController(piece: emptyUserPiece()), audio: audio),
    );

    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();

    expect(audio.playedPitches, ['C3']);
    expect(find.text('音符数: 1'), findsOneWidget);
  });

  testWidgets('練習するで onPractice が呼ばれる', (tester) async {
    var practiced = false;
    await tester.pumpWidget(
      wrap(
        EditorController(piece: twoBeatMelody()),
        onPractice: () => practiced = true,
      ),
    );

    await tester.tap(find.text('練習する'));
    expect(practiced, isTrue);
  });
}
