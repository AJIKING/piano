import 'package:flutter/material.dart';

import '../../domain/score/piece.dart';
import '../theme/etude_theme.dart';

/// ライブラリ上部の「今練習中」カード。曲名・作曲者・習得度・最終練習・再開ボタン。
class NowPracticingCard extends StatelessWidget {
  const NowPracticingCard({
    super.key,
    required this.piece,
    required this.lastPracticedLabel,
    this.onResume,
  });

  final Piece piece;

  /// 「昨日」「3 日前」などの相対表示(算出は呼び出し側)。
  final String lastPracticedLabel;

  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EtudeColors.inkLine),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF33283B), Color(0xFF211A29)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 7),
                decoration: const BoxDecoration(
                  color: EtudeColors.rose,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                '今練習中',
                style: TextStyle(
                  color: EtudeColors.rose,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            piece.title,
            style: const TextStyle(
              fontFamily: 'ShipporiMincho',
              fontSize: 21,
              color: EtudeColors.ivory,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            piece.composer,
            style: const TextStyle(fontSize: 12, color: EtudeColors.ivory2),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: piece.masteryPercent / 100,
              minHeight: 5,
              backgroundColor: const Color(0x1FF2EAD9),
              valueColor: const AlwaysStoppedAnimation(EtudeColors.brass),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '習得度 ${piece.masteryPercent}%',
                style: const TextStyle(fontSize: 10, color: EtudeColors.ivory3),
              ),
              Text(
                '最終練習 $lastPracticedLabel',
                style: const TextStyle(fontSize: 10, color: EtudeColors.ivory3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('練習を再開'),
              style: FilledButton.styleFrom(
                backgroundColor: EtudeColors.brass,
                foregroundColor: const Color(0xFF2A1D05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
