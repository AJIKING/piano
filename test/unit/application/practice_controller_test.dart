import 'package:etude/src/application/practice_controller.dart';
import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/piece.dart';
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
        expect(c.playheadBeats, 0);
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

    test('BPM 変更の瞬間に再生位置(playheadBeats)は飛ばない', () {
      fakeAsync((async) {
        final c = PracticeController(
          piece: twoBeatMelody(),
          audioEngine: RecordingAudioEngine(),
          bpm: 60,
        );
        c.play();
        async.elapse(const Duration(milliseconds: 1000)); // 60bpm で約 1 拍
        // テンポを変えても、その瞬間に再生位置はジャンプしない(以後の進む速さが変わるだけ)。
        c.setBpm(120);
        expect(c.playheadBeats, closeTo(1.0, 0.05));
        c.stop();
        async.flushTimers();
        c.dispose();
      });
    });

    test('同 beat の音符(和音)はすべて発音される', () {
      fakeAsync((async) {
        final audio = RecordingAudioEngine();
        final piece = Piece(
          id: 'p',
          title: 't',
          composer: 'c',
          notes: const [
            Note(pitch: 'C4', beat: 0, duration: 1),
            Note(pitch: 'E4', beat: 0, duration: 1),
            Note(pitch: 'G4', beat: 0, duration: 1),
          ],
        );
        final c = PracticeController(piece: piece, audioEngine: audio, bpm: 60);
        c.play();
        async.elapse(const Duration(milliseconds: 100));
        // 3 音とも鳴る(正準順 C4→E4→G4)。
        expect(audio.playedPitches, ['C4', 'E4', 'G4']);
        c.stop();
        async.flushTimers();
        c.dispose();
      });
    });

    test('再生中に BPM を上げると以後の進みが速くなる', () {
      fakeAsync((async) {
        // 途中で止まらないよう長めの曲。
        final piece = Piece(
          id: 'p',
          title: 't',
          composer: 'c',
          notes: const [
            Note(pitch: 'C4', beat: 0, duration: 1),
            Note(pitch: 'C5', beat: 8, duration: 1),
          ],
        );
        final c = PracticeController(
          piece: piece,
          audioEngine: RecordingAudioEngine(),
          bpm: 60,
        );

        c.play();
        async.elapse(const Duration(milliseconds: 500)); // 60bpm → ~0.5 拍
        c.setBpm(120);
        async.elapse(const Duration(milliseconds: 500)); // 120bpm → +~1.0 拍

        // 一定 60bpm なら 1.0 拍だが、途中で倍速にしたので ~1.5 拍進む。
        expect(c.playheadBeats, closeTo(1.5, 0.15));

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
