import '../core/clock.dart';
import '../domain/audio/audio_engine.dart';
import '../domain/library/library_store.dart';
import '../domain/score/score_repository.dart';

/// 差し替え境界の束。composition root(`main*.dart`)が組み立てて [EtudeApp] へ渡す。
class Dependencies {
  const Dependencies({
    required this.clock,
    required this.scoreRepository,
    required this.libraryStore,
    required this.audioEngine,
  });

  final Clock clock;
  final ScoreRepository scoreRepository;
  final LibraryStore libraryStore;
  final AudioEngine audioEngine;
}
