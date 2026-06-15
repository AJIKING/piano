import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/application/dependencies.dart';
import 'src/data/bundled_score_repository.dart';
import 'src/data/midi_pro_audio_engine.dart';
import 'src/data/prefs_library_store.dart';

/// 本番 composition root。差し替え境界に本番実装を詰める。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ピアノは横画面前提(鍵盤を画面いっぱいに使う)。横向きに固定する。
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    EtudeApp(
      dependencies: Dependencies(
        scoreRepository: const BundledScoreRepository(),
        // 永続化方式は docs/design-docs/0001-library-persistence.md で決定。
        libraryStore: PrefsLibraryStore(),
        // 音源・再生方式は docs/design-docs/0004-audio-engine.md で決定。
        // ピアノ音は assets/audio/piano.sf2(SoundFont)に依存(README 参照)。
        audioEngine: MidiProAudioEngine(),
      ),
    ),
  );
}
