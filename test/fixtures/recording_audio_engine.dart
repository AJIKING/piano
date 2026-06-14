import 'package:etude/src/domain/audio/audio_engine.dart';

/// 実発音せず、呼び出しを記録するだけの `AudioEngine`。
/// 「いつ・どの音を鳴らしたか」を検証するために使う(音は鳴らさない)。
class RecordingAudioEngine implements AudioEngine {
  final List<String> playedPitches = [];
  int initCount = 0;
  int stopAllCount = 0;

  @override
  Future<void> init() async => initCount++;

  @override
  void playNote(
    String pitch, {
    Duration sustain = const Duration(milliseconds: 900),
  }) {
    playedPitches.add(pitch);
  }

  @override
  void stopAll() => stopAllCount++;
}
