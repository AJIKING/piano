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
/// このアダプタはプラグイン呼び出しを薄く委譲するだけのため**自動テスト対象外**。
/// 実音・レイテンシは実機 / エミュレータで確認する。テストでは
/// `RecordingAudioEngine` を注入する。
class MidiProAudioEngine implements AudioEngine {
  MidiProAudioEngine({this.assetPath = 'assets/audio/piano.sf2'});

  /// 読み込む SoundFont のアセットパス。
  final String assetPath;

  final MidiPro _midi = MidiPro();

  /// 読み込んだ SoundFont の ID。未ロード/失敗時は null(無音)。
  int? _sfId;
  Future<void>? _loading;

  /// 鍵(MIDI key)ごとの保留中ノートオフ。連打時に前の音が切られないよう管理する。
  final Map<int, Timer> _noteOff = {};

  @override
  Future<void> init() {
    if (_sfId != null) return Future<void>.value();
    // 多重呼び出しでも 1 回だけロードする。失敗時は再試行できるよう後で null に戻す。
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      _sfId = await _midi.loadSoundfontAsset(assetPath: assetPath);
    } catch (_) {
      // .sf2 未配置などで失敗してもアプリは起動する(発音のみ無音)。
      _sfId = null;
    }
    // 失敗時は次回 init() で読み直せるようにする(成功時はキャッシュ)。
    if (_sfId == null) _loading = null;
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
    // 同じ鍵の保留中ノートオフをキャンセルしてから鳴らす(連打で切られないように)。
    _noteOff.remove(key)?.cancel();
    await _midi.playNote(channel: 0, key: key, velocity: 96, sfId: sfId);
    // 余韻の長さだけ鳴らしてからノートオフ(MIDI はサスティン中鳴り続けるため)。
    _noteOff[key] = Timer(sustain, () {
      _noteOff.remove(key);
      _midi.stopNote(channel: 0, key: key, sfId: sfId);
    });
  }

  @override
  void stopAll() {
    for (final timer in _noteOff.values) {
      timer.cancel();
    }
    _noteOff.clear();
    final sfId = _sfId;
    if (sfId != null) unawaited(_midi.stopAllNotes(sfId: sfId));
  }
}
