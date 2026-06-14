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
    VoidCallback? onSave,
  }) => MaterialApp(
    home: EditorScreen(
      controller: controller,
      audioEngine: audio ?? RecordingAudioEngine(),
      onSave: onSave,
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

  testWidgets('保存するで onSave が呼ばれる', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      wrap(
        EditorController(piece: twoBeatMelody()),
        onSave: () => saved = true,
      ),
    );

    await tester.tap(find.text('保存する'));
    expect(saved, isTrue);
  });
}
