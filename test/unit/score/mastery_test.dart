import 'package:etude/src/domain/score/mastery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mastery.afterPractice', () {
    test('1 回ごとに practiceStep だけ上がる', () {
      expect(Mastery.afterPractice(0), Mastery.practiceStep);
      expect(Mastery.afterPractice(40), 40 + Mastery.practiceStep);
    });

    test('100 を超えない', () {
      expect(Mastery.afterPractice(95), 100);
      expect(Mastery.afterPractice(100), 100);
    });
  });
}
