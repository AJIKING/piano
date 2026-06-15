import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/score_geometry.dart';
import 'package:etude/src/ui/practice/practice_screen.dart';
import 'package:etude/src/ui/widgets/grand_staff_view.dart';
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

  testWidgets('音符をタップするとその位置から再生する(前の音は鳴らさない)', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(piece: twoBeatMelody(), audioEngine: audio),
      ),
    );

    // twoBeatMelody = C4@0 拍 / E4@1 拍。E4 をタップして開始位置に選ぶ。
    const g = ScoreGeometry();
    final e4 = twoBeatMelody().sortedNotes[1];
    final origin = tester.getTopLeft(find.byType(ScoreView));
    await tester.tapAt(origin + Offset(g.xAtBeat(e4.beat), g.yForNote(e4)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    // 開始位置=1拍なので E4 は最初の tick で発音、C4(0拍)は鳴らさない。
    await tester.pump(const Duration(milliseconds: 100));
    expect(audio.playedPitches, contains('E4'));
    expect(audio.playedPitches, isNot(contains('C4')));

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
  });

  testWidgets('選択音符を再タップで解除し、先頭から再生する', (tester) async {
    final audio = RecordingAudioEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(piece: twoBeatMelody(), audioEngine: audio),
      ),
    );

    const g = ScoreGeometry();
    final e4 = twoBeatMelody().sortedNotes[1];
    final origin = tester.getTopLeft(find.byType(ScoreView));
    final p = origin + Offset(g.xAtBeat(e4.beat), g.yForNote(e4));
    await tester.tapAt(p); // 選択
    await tester.pump();
    await tester.tapAt(p); // 再タップで解除
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 200)); // 先頭 C4 が即発音
    expect(audio.playedPitches, contains('C4'));

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
  });

  testWidgets('fullNotes がある曲は両手(大譜表)モードに切り替えられる', (tester) async {
    final piece = twoBeatMelody().copyWith(
      fullNotes: const [
        Note(pitch: 'C3', beat: 0, duration: 1),
        Note(pitch: 'E4', beat: 0, duration: 1),
        Note(pitch: 'G4', beat: 1, duration: 1),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(piece: piece, audioEngine: RecordingAudioEngine()),
      ),
    );

    expect(find.byType(ScoreView), findsOneWidget);
    expect(find.byType(GrandStaffView), findsNothing);

    await tester.tap(find.byTooltip('両手のお手本'));
    await tester.pump();
    expect(find.byType(GrandStaffView), findsOneWidget);
    expect(find.byType(ScoreView), findsNothing);

    await tester.tap(find.byTooltip('片手(練習)に戻す'));
    await tester.pump();
    expect(find.byType(ScoreView), findsOneWidget);
    expect(find.byType(GrandStaffView), findsNothing);
  });

  testWidgets('fullNotes が無い曲は両手トグルが出ない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
        ),
      ),
    );
    expect(find.byTooltip('両手のお手本'), findsNothing);
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
