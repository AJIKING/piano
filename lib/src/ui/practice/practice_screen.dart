import 'package:flutter/material.dart';

import '../../application/practice_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../../domain/score/piece.dart';
import '../../domain/score/score_geometry.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_view.dart';

/// 練習画面。譜面・テンポ・メトロノーム・再生と、下部の鍵盤。
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.piece,
    required this.audioEngine,
    this.onCompleted,
  });

  final Piece piece;
  final AudioEngine audioEngine;

  /// 曲を最後まで弾き切ったときに呼ばれる(習得度の記録など)。
  final VoidCallback? onCompleted;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const _geometry = ScoreGeometry();
  late final PracticeController _controller;
  bool _audioReady = false;

  @override
  void initState() {
    super.initState();
    _controller = PracticeController(
      piece: widget.piece,
      audioEngine: widget.audioEngine,
      onCompleted: widget.onCompleted,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onKey(String pitch) {
    if (!_audioReady) {
      widget.audioEngine.init();
      _audioReady = true;
    }
    widget.audioEngine.playNote(pitch);
  }

  double? _playheadX() {
    if (!_controller.isPlaying) return null;
    return _geometry.xAtBeat(_controller.playheadBeats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.piece.title)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ScoreView(
                  piece: widget.piece,
                  geometry: _geometry,
                  litNoteIndex: _controller.litNoteIndex,
                  playheadX: _playheadX(),
                ),
              ),
              _controls(),
              const Divider(height: 1),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: PianoKeyboard(
                    onNotePressed: _onKey,
                    height: 160,
                    // 再生中は鳴っている鍵を光らせる。
                    litPitches:
                        _controller.isPlaying && _controller.litPitch != null
                        ? {_controller.litPitch!}
                        : const {},
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _controller.toggle,
            icon: Icon(
              _controller.isPlaying
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
            ),
            tooltip: _controller.isPlaying ? '停止' : '再生',
          ),
          const SizedBox(width: 8),
          Text(
            '${_controller.bpm.round()}',
            style: const TextStyle(
              fontFamily: EtudeTheme.mono,
              color: EtudeColors.brassSoft,
            ),
          ),
          const Text(
            ' BPM',
            style: TextStyle(fontSize: 10, color: EtudeColors.ivory3),
          ),
          Expanded(
            child: Slider(
              min: PracticeController.minBpm,
              max: PracticeController.maxBpm,
              value: _controller.bpm,
              onChanged: _controller.setBpm,
            ),
          ),
          IconButton(
            onPressed: _controller.toggleMetronome,
            isSelected: _controller.metronomeOn,
            icon: const Icon(Icons.av_timer_outlined),
            selectedIcon: const Icon(Icons.av_timer),
            tooltip: 'メトロノーム',
          ),
        ],
      ),
    );
  }
}
