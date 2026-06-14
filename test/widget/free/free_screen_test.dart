import 'package:etude/src/ui/free/free_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/recording_audio_engine.dart';

void main() {
  testWidgets('鍵盤タップで発音し、最後の音名を表示する', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(MaterialApp(home: FreeScreen(audioEngine: audio)));

    // C 鍵は鍵盤上に音名ラベルを持つため、衝突しない D2 を使う。
    await tester.tap(find.byKey(const ValueKey('key-D2')));
    await tester.pump();

    expect(audio.playedPitches, ['D2']);
    expect(audio.initCount, 1);
    expect(find.text('D2'), findsOneWidget);
  });

  testWidgets('黒鍵は ♯ 表記で表示される', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(MaterialApp(home: FreeScreen(audioEngine: audio)));

    await tester.tap(find.byKey(const ValueKey('key-C#2')));
    await tester.pump();

    expect(audio.playedPitches, ['C#2']);
    expect(find.text('C♯2'), findsOneWidget);
  });
}
