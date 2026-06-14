import 'package:etude/src/application/practice_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';
import '../../fixtures/recording_audio_engine.dart';

void main() {
  group('PracticeController', () {
    test('再生で音符が時刻順に発音され、末尾で自動停止する', () {
      fakeAsync((async) {
        final audio = RecordingAudioEngine();
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: audio,
          bpm: 60,
        );

        c.play();
        expect(c.isPlaying, isTrue);
        expect(audio.initCount, 1);

        // 1.1 秒経過: C4(0s)→E4(1s)が鳴っている。
        async.elapse(const Duration(milliseconds: 1100));
        expect(audio.playedPitches, ['C4', 'E4']);

        // total=2.3 秒を超えると自動停止し先頭へ戻る。
        async.elapse(const Duration(milliseconds: 1400));
        expect(c.isPlaying, isFalse);
        expect(c.playhead, Duration.zero);
        expect(audio.stopAllCount, greaterThanOrEqualTo(1));

        c.dispose();
      });
    });

    test('メトロノーム ON でクリックが鳴る', () {
      fakeAsync((async) {
        final audio = RecordingAudioEngine();
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: audio,
          bpm: 60,
        );
        c.toggleMetronome();

        c.play();
        async.elapse(const Duration(milliseconds: 1100));

        // 強拍 C3(拍0)と弱拍 G2(拍1)が含まれる。
        expect(audio.playedPitches, contains('C3'));
        expect(audio.playedPitches, contains('G2'));

        c.stop();
        c.dispose();
      });
    });

    test('弾き切ると onCompleted が 1 度だけ呼ばれる', () {
      fakeAsync((async) {
        var completed = 0;
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
          bpm: 60,
          onCompleted: () => completed++,
        );
        c.play();
        async.elapse(const Duration(milliseconds: 2500)); // total 2.3s 超
        expect(completed, 1);
        async.flushTimers();
        c.dispose();
      });
    });

    test('ユーザー停止では onCompleted は呼ばれない', () {
      fakeAsync((async) {
        var completed = 0;
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
          bpm: 60,
          onCompleted: () => completed++,
        );
        c.play();
        async.elapse(const Duration(milliseconds: 500));
        c.stop();
        async.flushTimers();
        expect(completed, 0);
        c.dispose();
      });
    });

    test('playheadBeats は再生開始時のテンポで換算する(途中のテンポ変更に揺れない)', () {
      fakeAsync((async) {
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
          bpm: 60,
        );
        c.play();
        async.elapse(const Duration(milliseconds: 1000)); // 60bpm で 1 拍
        // 再生中にスライダーを動かしても、再生ヘッドは play 時のテンポ換算のまま。
        c.setBpm(120);
        expect(c.playheadBeats, closeTo(1.0, 0.05));
        c.stop();
        async.flushTimers();
        c.dispose();
      });
    });

    test('空の旋律では再生を開始しない', () {
      final audio = RecordingAudioEngine();
      final c = PracticeController(piece: emptyUserPiece(), audioEngine: audio);
      c.play();
      expect(c.isPlaying, isFalse);
      expect(audio.playedPitches, isEmpty);
      c.dispose();
    });

    test('setBpm は 40–160 にクランプする', () {
      final c = PracticeController(
        piece: twoBeatMelody(),
        audioEngine: RecordingAudioEngine(),
      );
      c.setBpm(999);
      expect(c.bpm, 160);
      c.setBpm(0);
      expect(c.bpm, 40);
      c.dispose();
    });

    test('toggle は再生/停止を切り替える', () {
      fakeAsync((async) {
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
          bpm: 60,
        );
        c.toggle();
        expect(c.isPlaying, isTrue);
        c.toggle();
        expect(c.isPlaying, isFalse);
        async.flushTimers();
        c.dispose();
      });
    });
  });
}
