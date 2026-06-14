import 'package:etude/src/core/relative_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);

  group('relativePracticeLabel', () {
    test('未練習は —', () {
      expect(relativePracticeLabel(null, now), '—');
    });

    test('同日は 今日(時刻差は無視)', () {
      expect(relativePracticeLabel(DateTime(2026, 1, 10, 1), now), '今日');
    });

    test('前日は 昨日', () {
      expect(relativePracticeLabel(DateTime(2026, 1, 9, 23), now), '昨日');
    });

    test('2 日以上前は N 日前', () {
      expect(relativePracticeLabel(DateTime(2026, 1, 7), now), '3 日前');
    });
  });
}
