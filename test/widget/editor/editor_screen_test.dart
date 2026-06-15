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

  testWidgets('戻る・末尾へボタンがあり、ユーザー曲では元に戻すは出ない', (tester) async {
    await tester.pumpWidget(wrap(EditorController(piece: emptyUserPiece())));

    expect(find.byTooltip('戻る'), findsOneWidget);
    expect(find.byTooltip('進む'), findsOneWidget);
    expect(find.byTooltip('末尾へ(末尾に追加しやすくする)'), findsOneWidget);
    // original 無し → リセット(最初に戻す)は非表示。
    expect(find.byTooltip('最初に戻す'), findsNothing);
  });

  testWidgets('収録曲(original あり)ではリセットアイコンが出る', (tester) async {
    final original = twoBeatMelody();
    await tester.pumpWidget(
      wrap(EditorController(piece: original, original: original)),
    );

    expect(find.byTooltip('最初に戻す'), findsOneWidget);
  });

  testWidgets('鍵盤で追加 → 戻るで音符数が減る', (tester) async {
    await tester.pumpWidget(wrap(EditorController(piece: emptyUserPiece())));

    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();
    expect(find.text('音符数: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('戻る'));
    await tester.pump();
    expect(find.text('音符数: 0'), findsOneWidget);
  });

  testWidgets('試聴中は鍵盤で音符が増えない(弾き合わせのみ)', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(
      wrap(EditorController(piece: twoBeatMelody()), audio: audio),
    );

    await tester.tap(find.text('試聴'));
    await tester.pump();
    expect(find.text('停止'), findsOneWidget); // 試聴中

    await tester.tap(find.byKey(const ValueKey('key-C3')));
    await tester.pump();
    expect(find.text('音符数: 2'), findsOneWidget); // 増えない
    expect(audio.playedPitches, contains('C3')); // 音は鳴る

    await tester.tap(find.text('停止')); // タイマー後始末
    await tester.pump();
  });

  testWidgets('ハンドルでツールバーを表示/非表示できる', (tester) async {
    await tester.pumpWidget(wrap(EditorController(piece: emptyUserPiece())));
    expect(find.byTooltip('戻る'), findsOneWidget); // 既定で表示

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up)); // 閉じる
    await tester.pump();
    expect(find.byTooltip('戻る'), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down)); // 開く
    await tester.pump();
    expect(find.byTooltip('戻る'), findsOneWidget);
  });
}
