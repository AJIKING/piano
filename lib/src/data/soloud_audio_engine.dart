import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../domain/audio/audio_engine.dart';
import '../domain/score/note.dart';

/// `AudioEngine` の本番実装(ADR 0004)。
///
/// flutter_soloud の波形シンセ(三角波)で各音高を発音する。プロトタイプの
/// フォールバックシンセに相当し、音源アセットを必要としない。サンプルピアノ音源
/// へ差し替える場合は ADR 0004 を改訂する。
///
/// このアダプタは `SystemClock` と同様に**自動テスト対象外**。実音・レイテンシ・
/// オーディオセッション挙動は実機 / エミュレータで確認する。テストでは
/// `RecordingAudioEngine`(test/fixtures/)を注入する。
class SoLoudAudioEngine implements AudioEngine {
  SoLoudAudioEngine();

  final SoLoud _soloud = SoLoud.instance;

  /// 音高ごとの波形ソース(周波数を 1 度だけ設定して使い回す)。
  /// 別ソースにすることで複数音の同時発音(ポリフォニー)ができる。
  final Map<String, AudioSource> _voices = {};

  /// 鳴動中のハンドル(stopAll で止める)。
  final List<SoundHandle> _active = [];

  bool _initStarted = false;

  @override
  Future<void> init() async {
    if (_soloud.isInitialized || _initStarted) return;
    _initStarted = true;
    await _soloud.init();
  }

  @override
  void playNote(
    String pitch, {
    Duration sustain = const Duration(milliseconds: 900),
  }) {
    // 同期 API なので非同期処理は投げっぱなしにする(発音は副作用)。
    unawaited(_playNote(pitch, sustain));
  }

  Future<void> _playNote(String pitch, Duration sustain) async {
    if (!Note.isValidPitch(pitch)) return;
    await init();
    if (!_soloud.isInitialized) return;

    final source = await _voiceFor(pitch);
    final handle = _soloud.play(source, volume: 0.6);
    _active.add(handle);
    // 余韻いっぱいかけて減衰させ(撥弦/打鍵風)、終端で停止する。
    _soloud.fadeVolume(handle, 0, sustain);
    _soloud.scheduleStop(handle, sustain);

    // ハンドルが際限なく溜まらないよう、古いものから間引く。
    if (_active.length > 64) _active.removeRange(0, _active.length - 64);
  }

  Future<AudioSource> _voiceFor(String pitch) async {
    final existing = _voices[pitch];
    if (existing != null) return existing;
    // superWave=false: 単一の三角波(クリアな音)。scale/detune は superWave 用なので 0。
    final source = await _soloud.loadWaveform(WaveForm.triangle, false, 0, 0);
    _soloud.setWaveformFreq(source, Note.frequencyOf(pitch));
    _voices[pitch] = source;
    return source;
  }

  @override
  void stopAll() {
    if (!_soloud.isInitialized) return;
    for (final handle in _active) {
      unawaited(_soloud.stop(handle));
    }
    _active.clear();
  }
}
