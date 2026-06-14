import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/application/dependencies.dart';
import 'src/core/clock.dart';
import 'src/data/bundled_score_repository.dart';
import 'src/data/prefs_library_store.dart';
import 'src/data/soloud_audio_engine.dart';

/// 本番 composition root。差し替え境界に本番実装を詰める。
void main() {
  runApp(
    EtudeApp(
      dependencies: Dependencies(
        clock: const SystemClock(),
        scoreRepository: const BundledScoreRepository(),
        // 永続化方式は docs/design-docs/0001-library-persistence.md で決定。
        libraryStore: PrefsLibraryStore(),
        // 音源・再生方式は docs/design-docs/0004-audio-engine.md で決定。
        audioEngine: SoLoudAudioEngine(),
      ),
    ),
  );
}
