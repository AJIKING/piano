import 'dart:async';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import '../domain/audio/audio_engine.dart';
import '../domain/score/note.dart';

/// `AudioEngine` の本番実装(ADR 0004)。
///
/// SoundFont(.sf2)を `flutter_midi_pro` で読み込み、音名を MIDI ノートに変換して
/// 発音する。本物のピアノ音色は `assets/audio/piano.sf2` の SoundFont に依存する
/// (置き方は assets/audio/README.md)。
///
/// このアダプタは `SystemClock` と同様に**自動テスト対象外**。実音・レイテンシは
/// 実機 / エミュレータで確認する。テストでは `RecordingAudioEngine` を注入する。
class MidiProAudioEngine implements AudioEngine {
  MidiProAudioEngine({this.assetPath = 'assets/audio/piano.sf2'});

  /// 読み込む SoundFont のアセットパス。
  final String assetPath;

  final MidiPro _midi = MidiPro();

  /// 読み込んだ SoundFont の ID。未ロード/失敗時は null(無音)。
  int? _sfId;
  Future<void>? _loading;

  @override
  Future<void> init() {
    // 多重呼び出しでも 1 回だけロードする。
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      _sfId = await _midi.loadSoundfontAsset(assetPath: assetPath);
    } catch (_) {
      // .sf2 未配置などで失敗してもアプリは起動する(発音のみ無音)。
      _sfId = null;
    }
  }

  @override
  void playNote(
    String pitch, {
    Duration sustain = const Duration(milliseconds: 900),
  }) {
    // 同期 API のため非同期処理は投げっぱなしにする(発音は副作用)。
    unawaited(_playNote(pitch, sustain));
  }

  Future<void> _playNote(String pitch, Duration sustain) async {
    if (!Note.isValidPitch(pitch)) return;
    await init();
    final sfId = _sfId;
    if (sfId == null) return;

    final key = Note.midiOf(pitch);
    await _midi.playNote(channel: 0, key: key, velocity: 96, sfId: sfId);
    // 余韻の長さだけ鳴らしてからノートオフ(MIDI はサスティン中鳴り続けるため)。
    Future<void>.delayed(sustain, () {
      _midi.stopNote(channel: 0, key: key, sfId: sfId);
    });
  }

  @override
  void stopAll() {
    final sfId = _sfId;
    if (sfId != null) unawaited(_midi.stopAllNotes(sfId: sfId));
  }
}
