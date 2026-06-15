import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/score/note.dart';
import '../../domain/score/piece.dart';
import '../../domain/score/score_geometry.dart';

/// 大譜表(ト音＋ヘ音の2段)で両手の譜面を描く**表示専用**ウィジェット。
///
/// 既存の [ScoreGeometry](E4=diatonicStep 0)をそのまま使う。ト音譜表は
/// step 0–8、ヘ音譜表は step −12〜−4 に並び、中央 C(step −2)が両譜表の間に
/// 加線で載る。音高だけで段が自動的に決まるので、左手/右手の区別データは不要。
///
/// 高さ・縦オフセットは**音域から自動算出**する(高音/低音が見切れないように)。
/// 編集はしない(キャレット/選択なし)。再生ヘッド・発音中ハイライトのみ。
class GrandStaffView extends StatelessWidget {
  const GrandStaffView({
    super.key,
    required this.notes,
    this.beatsPerMeasure = 4,
    this.geometry = const ScoreGeometry(),
    this.litNoteIndices = const {},
    this.playheadX,
    this.scrollController,
  });

  /// 描画する音符(両手まとめて)。
  final List<Note> notes;
  final int beatsPerMeasure;
  final ScoreGeometry geometry;

  /// 発音中の音符(整列した並びのインデックス)。和音は複数。
  final Set<int> litNoteIndices;

  /// 再生ヘッドの x(再生中のみ)。
  final double? playheadX;
  final ScrollController? scrollController;

  static const _padTop = 26.0;
  static const _padBottom = 26.0;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Note>.of(notes)..sort(Piece.compareNotes);

    // 譜表は常に表示しつつ、音符の最高/最低 step まで描画範囲を広げる。
    var maxStep = 8, minStep = -12;
    for (final n in sorted) {
      final s = n.diatonicStep;
      if (s > maxStep) maxStep = s;
      if (s < minStep) minStep = s;
    }
    // 最高音(maxStep)の符尾上端が _padTop に来るよう縦オフセットを決める。
    final dy = _padTop - geometry.yForStep(maxStep);
    final height = geometry.yForStep(minStep) + dy + _padBottom;

    final rawWidth = geometry.xAtBeat(Piece.contentEndOf(sorted)) + 16;
    final width = rawWidth < 280 ? 280.0 : rawWidth;

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(width, height),
          painter: _GrandStaffPainter(
            notes: notes,
            sorted: sorted,
            geometry: geometry,
            beatsPerMeasure: beatsPerMeasure,
            litNoteIndices: litNoteIndices,
            playheadX: playheadX,
            dy: dy,
          ),
        ),
      ),
    );
  }
}

class _GrandStaffPainter extends CustomPainter {
  _GrandStaffPainter({
    required this.notes,
    required this.sorted,
    required this.geometry,
    required this.beatsPerMeasure,
    required this.litNoteIndices,
    required this.playheadX,
    required this.dy,
  });

  /// shouldRepaint の参照比較用(元リスト。描画には [sorted] を使う)。
  final List<Note> notes;
  final List<Note> sorted;
  final ScoreGeometry geometry;
  final int beatsPerMeasure;
  final Set<int> litNoteIndices;
  final double? playheadX;
  final double dy;

  static const _paper = Color(0xFFF4EDDC);
  static const _staffLine = Color(0xFF9D8E6F);
  static const _ink = Color(0xFF241C10);
  static const _bar = Color(0xFFC4B692);
  static const _lit = Color(0xFFB8893A);

  // ト音譜表の線(下から E4,G4,B4,D5,F5)= step 0,2,4,6,8。
  static const _trebleSteps = [0, 2, 4, 6, 8];
  // ヘ音譜表の線(下から G2,B2,D3,F3,A3)= step −12,−10,−8,−6,−4。
  static const _bassSteps = [-12, -10, -8, -6, -4];

  double _y(int step) => geometry.yForStep(step) + dy;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = _paper,
    );

    final linePaint = Paint()
      ..color = _staffLine
      ..strokeWidth = 1;
    final right = size.width - 8;
    for (final s in [..._trebleSteps, ..._bassSteps]) {
      final y = _y(s);
      canvas.drawLine(Offset(18, y), Offset(right, y), linePaint);
    }

    // 左の連結(大譜表の括り)。両譜表を縦線でつなぐ。
    final braceTop = _y(8);
    final braceBottom = _y(-12);
    canvas.drawLine(
      Offset(18, braceTop),
      Offset(18, braceBottom),
      Paint()
        ..color = _staffLine
        ..strokeWidth = 2.2,
    );

    // 小節線(両譜表を貫く)。
    final barPaint = Paint()
      ..color = _bar
      ..strokeWidth = 1;
    final contentEnd = Piece.contentEndOf(sorted);
    for (var b = beatsPerMeasure; b < contentEnd; b += beatsPerMeasure) {
      final x = g.xAtBeat(b.toDouble()) - 13;
      canvas.drawLine(Offset(x, braceTop), Offset(x, braceBottom), barPaint);
    }

    for (var i = 0; i < sorted.length; i++) {
      _paintNote(canvas, sorted[i], litNoteIndices.contains(i));
    }

    if (playheadX != null) {
      canvas.drawLine(
        Offset(playheadX!, braceTop - 6),
        Offset(playheadX!, braceBottom + 6),
        Paint()
          ..color = _lit
          ..strokeWidth = 2.4,
      );
    }
  }

  void _paintNote(Canvas canvas, Note note, bool lit) {
    final x = geometry.xAtBeat(note.beat);
    final y = _y(note.diatonicStep);
    final step = note.diatonicStep;
    final color = lit ? _lit : _ink;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;

    // 加線: ト音上方(step≥10)/ 中央C(step −2)/ ヘ音下方(step≤−14)。
    void ledger(int s) {
      final ly = _y(s);
      canvas.drawLine(
        Offset(x - 8, ly),
        Offset(x + 8, ly),
        Paint()
          ..color = _staffLine
          ..strokeWidth = 1,
      );
    }

    if (step >= 10) {
      for (var s = 10; s <= step; s += 2) {
        ledger(s);
      }
    } else if (step == -2) {
      ledger(-2);
    } else if (step <= -14) {
      for (var s = -14; s >= step; s -= 2) {
        ledger(s);
      }
    }

    // ♯ 記号(線で描画)。
    if (note.pitch.contains('#')) {
      final sx = x - 15;
      canvas.drawLine(Offset(sx - 2, y - 6), Offset(sx - 2, y + 5), paint);
      canvas.drawLine(Offset(sx + 2, y - 7), Offset(sx + 2, y + 4), paint);
      canvas.drawLine(Offset(sx - 4, y - 1), Offset(sx + 4, y - 3), paint);
      canvas.drawLine(Offset(sx - 4, y + 3), Offset(sx + 4, y + 1), paint);
    }

    // 符尾: ヘ音域は中線(−8)、ト音域は中線(4)を境に向きを変える。
    final up = step <= -4 ? step < -8 : step < 4;
    final stemX = x + (up ? 5.6 : -5.6);
    canvas.drawLine(
      Offset(stemX, y),
      Offset(stemX, up ? y - 22 : y + 22),
      paint,
    );

    // 符頭。2 拍以上は白抜き、それ未満は塗りつぶし。
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.31);
    final headPaint = Paint()..color = color;
    if (note.duration >= 2) {
      headPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 9.2),
      headPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GrandStaffPainter old) =>
      !identical(old.notes, notes) ||
      old.dy != dy ||
      old.beatsPerMeasure != beatsPerMeasure ||
      !setEquals(old.litNoteIndices, litNoteIndices) ||
      old.playheadX != playheadX;
}
