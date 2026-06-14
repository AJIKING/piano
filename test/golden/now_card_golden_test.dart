@Tags(['golden'])
library;

import 'package:etude/src/ui/library/now_practicing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixture_pieces.dart';
import 'golden_setup.dart';

void main() {
  setUpAll(loadEtudeFonts);

  testWidgets('NowPracticingCard（習得度あり）', (tester) async {
    final piece = twoBeatMelody().copyWith(
      title: 'ジムノペディ 第1番',
      composer: 'エリック・サティ',
      masteryPercent: 64,
    );
    await pumpGolden(
      tester,
      SizedBox(
        width: 280,
        child: NowPracticingCard(piece: piece, lastPracticedLabel: '昨日'),
      ),
      size: const Size(320, 320),
    );
    await expectGolden(tester, 'now_practicing_card');
  }, skip: skipGoldens);
}
