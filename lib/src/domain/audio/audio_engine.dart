/// 発音・再生の副作用境界(pure Dart)。プロトタイプの Tone.js に相当。
///
/// 責務は最小に保つ — 初期化・単音の発音・停止のみ。
/// 「いつ鳴らすか」(旋律のスケジュール・テンポ・メトロノーム)はこの境界の外、
/// pure Dart のスケジュールロジックが持つ(ADR 0004)。
///
/// テストでは呼び出しを記録する fake(`RecordingAudioEngine`)に差し替え、
/// 実際の音は鳴らさない。本番実装は data 層(`SampledPianoAudioEngine`)。
abstract interface class AudioEngine {
  /// 音源の初期化(サンプルのロードなど)。発音前に 1 度呼ぶ。
  Future<void> init();

  /// 指定音高を発音する。[sustain] は余韻の長さ。
  void playNote(String pitch, {Duration sustain});

  /// 鳴っている音をすべて止める。
  void stopAll();
}
