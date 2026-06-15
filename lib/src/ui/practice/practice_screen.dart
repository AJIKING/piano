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

  /// 譜面でタップして選んだ「再生開始音符」(正準順インデックス)。
  /// null なら先頭から再生する。
  int? _startIndex;

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

  /// 選択した音符があればその位置から、無ければ先頭から再生する。
  void _togglePlay() {
    if (_controller.isPlaying) {
      _controller.stop();
    } else {
      final notes = widget.piece.sortedNotes;
      final i = _startIndex;
      final from = (i != null && i < notes.length) ? notes[i].beat : 0.0;
      _controller.play(fromBeat: from);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.piece.title)),
      body: Column(
        children: [
          // 譜面と再生コントロールは毎フレーム(再生ヘッド)更新する。
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final playing = _controller.isPlaying;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ScoreView(
                      piece: widget.piece,
                      geometry: _geometry,
                      litNoteIndex: playing ? _controller.litNoteIndex : null,
                      playheadX: _playheadX(),
                      // 停止中は選んだ開始音符を強調。タップで開始位置を選ぶ。
                      selectedIndex: playing ? null : _startIndex,
                      onSelectNote: playing
                          ? null
                          : (i) => setState(() => _startIndex = i),
                      // 余白タップで開始位置を解除し、先頭からに戻す。
                      onAddAt: playing
                          ? null
                          : (_, _) => setState(() => _startIndex = null),
                    ),
                  ),
                  if (!playing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '音符をタップすると、その位置から再生します',
                        style: TextStyle(
                          fontSize: 11,
                          color: EtudeColors.ivory3,
                        ),
                      ),
                    ),
                  _controls(),
                ],
              );
            },
          ),
          const Divider(height: 1),
          // 鍵盤は「鳴る音が変わった時」だけ再構築する(毎フレーム再構築を避ける)。
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: _controller.litPitches,
                builder: (context, lit, _) => PianoKeyboard(
                  onNotePressed: _onKey,
                  height: 160,
                  litPitches: lit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _togglePlay,
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
