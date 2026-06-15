@Tags(['golden'])
library;

import 'package:etude/src/ui/widgets/piano_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_setup.dart';

void main() {
  setUpAll(loadEtudeFonts);

  testWidgets('PianoKeyboard（和音ハイライトあり）', (tester) async {
    await pumpGolden(
      tester,
      const PianoKeyboard(
        onNotePressed: _noop,
        startOctave: 4,
        octaveCount: 1,
        height: 150,
        litPitches: {'C4', 'E4', 'G4'},
      ),
      size: const Size(300, 180),
    );
    await expectGolden(tester, 'piano_keyboard');
  }, skip: skipGoldens);
}

void _noop(String _) {}
