import 'package:etude/src/ui/free/free_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/localized_app.dart';
import '../../fixtures/recording_audio_engine.dart';

void main() {
  testWidgets('鍵盤タップで発音し、最後の音を音名(C/D/E)で表示する', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(localizedApp(home: FreeScreen(audioEngine: audio)));

    await tester.tap(find.byKey(const ValueKey('key-D2')));
    await tester.pump();

    expect(audio.playedPitches, ['D2']);
    expect(audio.initCount, 1);
    expect(find.text('D'), findsOneWidget); // D2 → D(音名・オクターブなし)
  });

  testWidgets('黒鍵は ♯ 付きの音名で表示される', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(localizedApp(home: FreeScreen(audioEngine: audio)));

    await tester.tap(find.byKey(const ValueKey('key-C#2')));
    await tester.pump();

    expect(audio.playedPitches, ['C#2']);
    expect(find.text('C♯'), findsOneWidget); // C#2 → C♯
  });

  testWidgets('全画面モードに入る/出る。鍵盤は全画面でも弾ける', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(localizedApp(home: FreeScreen(audioEngine: audio)));

    // 全画面へ → AppBar(タイトル)が消え、終了ボタンが出る。
    await tester.tap(find.byTooltip('全画面'));
    await tester.pump();
    expect(find.text('自由演奏'), findsNothing);
    expect(find.byTooltip('全画面を終了'), findsOneWidget);

    // 全画面でも発音できる。
    await tester.tap(find.byKey(const ValueKey('key-E2')));
    await tester.pump();
    expect(audio.playedPitches, ['E2']);

    // 終了 → 通常表示に戻る。
    await tester.tap(find.byTooltip('全画面を終了'));
    await tester.pump();
    expect(find.text('自由演奏'), findsOneWidget);
  });
}
