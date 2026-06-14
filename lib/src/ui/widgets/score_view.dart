import 'package:flutter/material.dart';

import '../../domain/score/note.dart';
import '../../domain/score/piece.dart';
import '../../domain/score/score_geometry.dart';

/// 五線譜の描画。譜面紙の上に五線・小節線・音符・再生ヘッドを描く。
/// 横スクロールし、内容幅は旋律の長さに応じて伸びる。
class ScoreView extends StatelessWidget {
  const ScoreView({
    super.key,
    required this.piece,
    this.geometry = const ScoreGeometry(),
    this.litNoteIndex,
    this.selectedIndex,
    this.caretBeat,
    this.playheadX,
    this.height = 96,
    this.beatsPerMeasure = 3,
    this.onAddAt,
    this.onSelectNote,
    this.snap = 1,
    this.scrollController,
  });

  final Piece piece;
  final ScoreGeometry geometry;

  /// 横スクロールの制御(エディタの自動スクロール用)。
  final ScrollController? scrollController;

  /// 再生中にハイライトする音符。
  final int? litNoteIndex;

  /// エディタで選択中の音符。
  final int? selectedIndex;

  /// エディタの挿入キャレット位置(拍)。
  final double? caretBeat;

  /// 再生ヘッドの x(再生中のみ)。
  final double? playheadX;
  final double height;
  final int beatsPerMeasure;

  /// 譜面の空き領域タップ。スナップ済みの拍と五線位置(step)を渡す(エディタ用)。
  final void Function(double beat, int step)? onAddAt;

  /// 既存音符のタップ(エディタ用)。[piece] を整列した並びのインデックス。
  final void Function(int index)? onSelectNote;

  /// 追加時の拍スナップ単位(現在の音価)。
  final double snap;

  void _handleTapDown(TapDownDetails details) {
    final local = details.localPosition;
    final sorted = piece.sortedNotes;
    for (var i = 0; i < sorted.length; i++) {
      final nx = geometry.xAtBeat(sorted[i].beat);
      final ny = geometry.yForNote(sorted[i]);
      if ((local - Offset(nx, ny)).distance <= 12) {
        onSelectNote?.call(i);
        return;
      }
    }
    final beat = geometry.beatFromX(local.dx, snap: snap);
    final step = geometry.stepFromY(local.dy);
    onAddAt?.call(beat, step);
  }

  @override
  Widget build(BuildContext context) {
    final contentEnd = piece.contentEnd;
    final width = geometry.xAtBeat(contentEnd) + 28;
    final interactive = onAddAt != null || onSelectNote != null;
    Widget paint = CustomPaint(
      size: Size(width < 280 ? 280 : width, height),
      painter: _ScorePainter(
        piece: piece,
        geometry: geometry,
        litNoteIndex: litNoteIndex,
        selectedIndex: selectedIndex,
        caretBeat: caretBeat,
        playheadX: playheadX,
        beatsPerMeasure: beatsPerMeasure,
      ),
    );
    if (interactive) {
      paint = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        child: paint,
      );
    }
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: paint,
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  _ScorePainter({
    required this.piece,
    required this.geometry,
    required this.litNoteIndex,
    required this.selectedIndex,
    required this.caretBeat,
    required this.playheadX,
    required this.beatsPerMeasure,
  });

  final Piece piece;
  final ScoreGeometry geometry;
  final int? litNoteIndex;
  final int? selectedIndex;
  final double? caretBeat;
  final double? playheadX;
  final int beatsPerMeasure;

  static const _paper = Color(0xFFF4EDDC);
  static const _staffLine = Color(0xFF9D8E6F);
  static const _ink = Color(0xFF241C10);
  static const _bar = Color(0xFFC4B692);
  static const _lit = Color(0xFFB8893A);
  static const _selected = Color(0xFFC8922F);
  static const _caret = Color(0xFFB67C86);

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = _paper);

    final linePaint = Paint()
      ..color = _staffLine
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = g.topY + i * g.staffGap;
      canvas.drawLine(Offset(14, y), Offset(size.width - 8, y), linePaint);
    }

    // 小節線(3 拍ごと)。
    final barPaint = Paint()
      ..color = _bar
      ..strokeWidth = 1;
    final contentEnd = piece.contentEnd;
    for (var b = beatsPerMeasure; b < contentEnd; b += beatsPerMeasure) {
      final x = g.xAtBeat(b.toDouble()) - 13;
      canvas.drawLine(
        Offset(x, g.topY),
        Offset(x, g.topY + 4 * g.staffGap),
        barPaint,
      );
    }

    // 挿入キャレット(破線・ばら色)。
    if (caretBeat != null && playheadX == null) {
      final cx = g.xAtBeat(caretBeat!);
      final caretPaint = Paint()
        ..color = _caret
        ..strokeWidth = 1.6;
      for (var y = g.topY - 4; y < g.topY + 4 * g.staffGap + 4; y += 6) {
        canvas.drawLine(Offset(cx, y), Offset(cx, y + 3), caretPaint);
      }
    }

    final sorted = piece.sortedNotes;
    for (var i = 0; i < sorted.length; i++) {
      _paintNote(canvas, g, sorted[i], i == litNoteIndex, i == selectedIndex);
    }

    if (playheadX != null) {
      canvas.drawLine(
        Offset(playheadX!, g.topY - 6),
        Offset(playheadX!, g.topY + 4 * g.staffGap + 6),
        Paint()
          ..color = _lit
          ..strokeWidth = 2.4,
      );
    }
  }

  void _paintNote(
    Canvas canvas,
    ScoreGeometry g,
    Note note,
    bool lit,
    bool selected,
  ) {
    final x = g.xAtBeat(note.beat);
    final y = g.yForNote(note);
    final step = note.diatonicStep;

    final ledgerPaint = Paint()
      ..color = _staffLine
      ..strokeWidth = 1;
    if (step < 0) {
      for (var s = -2; s >= step; s -= 2) {
        final ly = g.baseY - s * (g.staffGap / 2);
        canvas.drawLine(Offset(x - 8, ly), Offset(x + 8, ly), ledgerPaint);
      }
    } else if (step > 8) {
      for (var s = 10; s <= step; s += 2) {
        final ly = g.baseY - s * (g.staffGap / 2);
        canvas.drawLine(Offset(x - 8, ly), Offset(x + 8, ly), ledgerPaint);
      }
    }

    final headColor = selected
        ? _selected
        : lit
        ? _lit
        : _ink;
    final notePaint = Paint()
      ..color = headColor
      ..strokeWidth = 1.4;

    // ♯ 記号(線で描画。フォントに依存しない)。
    if (note.pitch.contains('#')) {
      final sx = x - 15;
      canvas.drawLine(Offset(sx - 2, y - 6), Offset(sx - 2, y + 5), notePaint);
      canvas.drawLine(Offset(sx + 2, y - 7), Offset(sx + 2, y + 4), notePaint);
      canvas.drawLine(Offset(sx - 4, y - 1), Offset(sx + 4, y - 3), notePaint);
      canvas.drawLine(Offset(sx - 4, y + 3), Offset(sx + 4, y + 1), notePaint);
    }

    final up = step < 4;
    final stemX = x + (up ? 5.6 : -5.6);
    final stemY = up ? y - 22 : y + 22;
    canvas.drawLine(Offset(stemX, y), Offset(stemX, stemY), notePaint);

    // 8 分音符(0.5 拍)の旗。
    if (note.duration < 1) {
      final flag = Path()
        ..moveTo(stemX, stemY)
        ..quadraticBezierTo(
          stemX + 8,
          stemY + (up ? 3 : -3),
          stemX + 5,
          stemY + (up ? 12 : -12),
        );
      canvas.drawPath(
        flag,
        Paint()
          ..color = headColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // 符頭。2 分・付点2分(2 拍以上)は白抜き、それ未満は塗りつぶし。
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.31); // 約 -18 度
    final headRect = Rect.fromCenter(
      center: Offset.zero,
      width: 12,
      height: 9.2,
    );
    final headPaint = Paint()..color = headColor;
    if (note.duration >= 2) {
      headPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
    }
    canvas.drawOval(headRect, headPaint);
    canvas.restore();

    // 選択中はリングで強調(符頭の塗り/白抜きは音価で決まるので別表示)。
    if (selected) {
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()
          ..color = _selected
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_ScorePainter old) =>
      old.piece != piece ||
      old.litNoteIndex != litNoteIndex ||
      old.selectedIndex != selectedIndex ||
      old.caretBeat != caretBeat ||
      old.playheadX != playheadX;
}
