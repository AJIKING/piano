import 'package:flutter/material.dart';

import '../../domain/audio/audio_engine.dart';
import '../../domain/score/note.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';

/// 自由演奏画面。フル鍵盤をタップして発音し、最後に弾いた音名を表示する。
/// 「全画面」モードでは UI を隠して鍵盤を画面いっぱいに広げる(キーが大きくなる)。
class FreeScreen extends StatefulWidget {
  const FreeScreen({super.key, required this.audioEngine});

  final AudioEngine audioEngine;

  @override
  State<FreeScreen> createState() => _FreeScreenState();
}

class _FreeScreenState extends State<FreeScreen> {
  String _lastNote = '—';
  bool _audioReady = false;
  bool _fullscreen = false;

  void _onNote(String pitch) {
    if (!_audioReady) {
      widget.audioEngine.init();
      _audioReady = true;
    }
    widget.audioEngine.playNote(pitch);
    // 「A3」等ではなく音階(ドレミ)で表示する。
    setState(() => _lastNote = Note.solfege(pitch));
  }

  @override
  Widget build(BuildContext context) {
    if (_fullscreen) return _fullscreenView();

    return Scaffold(
      appBar: AppBar(
        title: const Text('自由演奏'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_full),
            tooltip: '全画面',
            onPressed: () => setState(() => _fullscreen = true),
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: _lastNoteLabel(big: true),
            ),
          ),
          PianoKeyboard(
            onNotePressed: _onNote,
            startOctave: 2,
            octaveCount: 4,
            height: 170,
          ),
        ],
      ),
    );
  }

  /// 全画面モード: 鍵盤を画面いっぱいに。右上に終了ボタン、左上に音階表示。
  Widget _fullscreenView() {
    return Scaffold(
      backgroundColor: EtudeColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => PianoKeyboard(
                  onNotePressed: _onNote,
                  startOctave: 2,
                  octaveCount: 4,
                  height: constraints.maxHeight,
                ),
              ),
            ),
            Positioned(top: 8, left: 12, child: _lastNoteLabel(big: false)),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_fullscreen),
                tooltip: '全画面を終了',
                style: IconButton.styleFrom(
                  backgroundColor: EtudeColors.ink3.withValues(alpha: 0.7),
                  foregroundColor: EtudeColors.ivory2,
                ),
                onPressed: () => setState(() => _fullscreen = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lastNoteLabel({required bool big}) {
    return Column(
      crossAxisAlignment: big
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _lastNote,
          style: TextStyle(
            fontFamily: 'ShipporiMincho',
            fontSize: big ? 34 : 22,
            color: EtudeColors.brassSoft,
          ),
        ),
        const Text(
          '音階',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            color: EtudeColors.ivory3,
          ),
        ),
      ],
    );
  }
}
