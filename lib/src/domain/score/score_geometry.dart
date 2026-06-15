import 'note.dart';

/// 五線譜のジオメトリ(pure Dart)。プロトタイプ `etude-piano-app.html` の
/// `xAt()` / `noteY()` / 譜面タップのスナップ計算に対応する。
///
/// 座標系は譜面ローカル(左上原点、右が +x、下が +y)。UI 層はこの値を
/// `CustomPainter` 等へそのまま渡す。flutter には依存しない。
class ScoreGeometry {
  const ScoreGeometry({
    this.pxPerBeat = 30,
    this.staffGap = 8,
    this.topY = 18,
    this.noteX0 = 44,
  });

  /// 1 拍あたりの横幅(px)。
  final double pxPerBeat;

  /// 五線の線間隔(px)。半音 1 段は [staffGap] / 2。
  final double staffGap;

  /// 最上線の y。
  final double topY;

  /// 拍 0 の音符中心の x(ト音記号・拍子記号ぶんの左余白)。
  final double noteX0;

  /// 五線の最下線(= E4, diatonicStep 0)の y。
  double get baseY => topY + 4 * staffGap;

  /// 拍位置 → x 座標(音符中心)。
  double xAtBeat(double beat) => noteX0 + beat * pxPerBeat;

  /// diatonicStep(E4=0、上が大) → y 座標。上ほど小さい y。
  double yForStep(int diatonicStep) => baseY - diatonicStep * (staffGap / 2);

  /// 音符 → y 座標。
  double yForNote(Note note) => yForStep(note.diatonicStep);

  /// x 座標 → 拍。[snap] 拍単位に丸め、負値は 0 にクランプする。
  double beatFromX(double x, {double snap = 1}) {
    final raw = (x - noteX0) / pxPerBeat;
    final clamped = raw < 0 ? 0.0 : raw;
    if (snap <= 0) return clamped;
    return (clamped / snap).round() * snap;
  }

  /// y 座標 → diatonicStep(最寄りの線/間にスナップ)。
  /// [minStep]/[maxStep] でクランプ(加線の範囲)。
  int stepFromY(double y, {int minStep = -9, int maxStep = 17}) {
    final step = ((baseY - y) / (staffGap / 2)).round();
    if (step < minStep) return minStep;
    if (step > maxStep) return maxStep;
    return step;
  }
}
