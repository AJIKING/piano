import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/application/dependencies.dart';
import 'src/core/clock.dart';
import 'src/data/bundled_score_repository.dart';
import 'src/domain/audio/audio_engine.dart';
import 'src/domain/library/library_store.dart';
import 'src/domain/score/piece.dart';

/// integration test 用 composition root。
///
/// 本番との差分は差し替え境界の中身だけ:
/// - [_ManualClock]: 固定時刻から手動でのみ進む clock(実時間に依存しない)
/// - [_InMemoryLibraryStore]: プロセス内にのみ保持する store(前回の端末状態に依存しない)
/// - [_RecordingAudioEngine]: 実発音せず呼び出しを記録するだけの音源
///
/// fake クラスは `test/fixtures/` と同等だが、lib からは test/ を import
/// できないため、この composition root 内に private で定義する。
void main() {
  runTestApp();
}

/// integration test から呼ぶエントリーポイント。
/// 毎回同じ初期状態(空の保存・時刻 2026-01-01 09:00)でアプリを起動し、
/// 時刻操作などのためのハンドルを返す。
TestAppHandle runTestApp() {
  final clock = _ManualClock(DateTime(2026, 1, 1, 9));
  final store = _InMemoryLibraryStore();
  final audio = _RecordingAudioEngine();
  runApp(
    EtudeApp(
      dependencies: Dependencies(
        clock: clock,
        scoreRepository: const BundledScoreRepository(),
        libraryStore: store,
        audioEngine: audio,
      ),
    ),
  );
  return TestAppHandle._(clock, store, audio);
}

/// テストからアプリの差し替え境界を操作するためのハンドル。
class TestAppHandle {
  TestAppHandle._(this._clock, this.libraryStore, this.audioEngine);

  final _ManualClock _clock;

  /// インメモリのライブラリ store(保存内容の検証用)。
  final LibraryStore libraryStore;

  /// 発音呼び出しを記録する音源(検証用)。
  final AudioEngine audioEngine;

  /// 現在の注入時刻。
  DateTime get now => _clock.now();

  /// 注入 clock を手動で進める。
  void advanceClock(Duration duration) => _clock.advance(duration);
}

/// 固定時刻から手動でのみ進む clock。`DateTime.now()` には依存しない。
class _ManualClock implements Clock {
  _ManualClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

/// プロセス内にのみ保持するインメモリ store。起動ごとに空から始まる。
class _InMemoryLibraryStore implements LibraryStore {
  List<Piece>? _saved;

  @override
  Future<List<Piece>?> load() async => _saved;

  @override
  Future<void> save(List<Piece> pieces) async => _saved = List.of(pieces);
}

/// 実発音せず、鳴らした音高を記録するだけの音源。
class _RecordingAudioEngine implements AudioEngine {
  final List<String> played = [];

  @override
  Future<void> init() async {}

  @override
  void playNote(
    String pitch, {
    Duration sustain = const Duration(milliseconds: 900),
  }) {
    played.add(pitch);
  }

  @override
  void stopAll() {}
}
