import 'package:etude/src/domain/score/note.dart';
import 'package:etude/src/domain/score/score_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const g = ScoreGeometry();

  group('拍 ↔ x', () {
    test('xAtBeat は noteX0 + beat*pxPerBeat', () {
      expect(g.xAtBeat(0), 80);
      expect(g.xAtBeat(1), 110);
      expect(g.xAtBeat(2.5), 80 + 2.5 * 30);
    });

    test('beatFromX は snap 単位に丸め、負は 0 にクランプ', () {
      expect(g.beatFromX(110), 1);
      expect(g.beatFromX(0), 0);
      expect(g.beatFromX(-50), 0);
      expect(g.beatFromX(95, snap: 0.5), 0.5);
    });
  });

  group('音高 ↔ y', () {
    test('E4(step 0)は最下線 baseY', () {
      expect(g.yForStep(0), g.baseY);
      expect(
        g.yForNote(const Note(pitch: 'E4', beat: 0, duration: 1)),
        g.baseY,
      );
    });

    test('1 段上がると staffGap/2 だけ y が小さくなる', () {
      expect(g.yForStep(2), g.baseY - 2 * (g.staffGap / 2));
    });

    test('stepFromY は最寄り段にスナップしクランプする', () {
      expect(g.stepFromY(g.baseY), 0);
      expect(g.stepFromY(g.yForStep(4)), 4);
      expect(g.stepFromY(-9999, maxStep: 17), 17);
      expect(g.stepFromY(9999, minStep: -9), -9);
    });
  });
}
