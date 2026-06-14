import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/playback_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';

void main() {
  group('PlaybackSchedule.fromNotes', () {
    test('60bpm では 1 拍 = 1 秒で発音時刻が決まる', () {
      final s = PlaybackSchedule.fromNotes(twoBeatMelody().notes, bpm: 60);
      expect(s.events.map((e) => e.pitch), ['C4', 'E4']);
      expect(s.events[0].time, Duration.zero);
      expect(s.events[1].time, const Duration(seconds: 1));
      expect(s.events[0].duration, const Duration(seconds: 1));
      expect(s.events.map((e) => e.noteIndex), [0, 1]);
    });

    test('テンポを上げると時刻が縮む', () {
      final s = PlaybackSchedule.fromNotes(twoBeatMelody().notes, bpm: 120);
      expect(s.events[1].time, const Duration(milliseconds: 500));
    });

    test('total は終端拍 + 余韻', () {
      final s = PlaybackSchedule.fromNotes(
        twoBeatMelody().notes,
        bpm: 60,
        tailBeats: 0.5,
      );
      // contentEnd=2拍, +0.5拍, 60bpm → 2.5秒
      expect(s.total, const Duration(milliseconds: 2500));
    });

    test('入力順に依らず beat 昇順へ整列する', () {
      final s = PlaybackSchedule.fromNotes(const [
        Note(pitch: 'E4', beat: 1, duration: 1),
        Note(pitch: 'C4', beat: 0, duration: 1),
      ], bpm: 60);
      expect(s.events.map((e) => e.pitch), ['C4', 'E4']);
    });

    test('メトロノームは拍頭が強拍、3/4 で 3 拍ごと', () {
      final s = PlaybackSchedule.fromNotes(const [
        Note(pitch: 'C4', beat: 0, duration: 4),
      ], bpm: 60);
      expect(s.metronome.map((t) => t.isDownbeat), [true, false, false, true]);
    });

    test('空の旋律は発音イベントを持たない', () {
      final s = PlaybackSchedule.fromNotes(const [], bpm: 60);
      expect(s.events, isEmpty);
    });
  });
}
