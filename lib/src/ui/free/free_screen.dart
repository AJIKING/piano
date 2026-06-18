import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
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
    // 最後に弾いた音を音名(C / C♯ …。オクターブなし)で表示する。
    setState(() => _lastNote = Note.letterName(pitch));
  }

  @override
  Widget build(BuildContext context) {
    if (_fullscreen) return _fullscreenView();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).freePlay),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_full),
            tooltip: AppLocalizations.of(context).fullscreen,
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
              child: _lastNoteLabel(),
            ),
          ),
          // 鍵盤は画面高さに追従(タブレットでは大きく)。鍵盤側で縦横比に頭打ちする。
          PianoKeyboard(
            onNotePressed: _onNote,
            startOctave: 2,
            octaveCount: 4,
            height: (MediaQuery.sizeOf(context).height * 0.55).clamp(
              160.0,
              340.0,
            ),
          ),
        ],
      ),
    );
  }

  /// 全画面モード: 鍵盤を画面いっぱいに。右上に終了ボタン、左上に音名表示。
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
                  // 全画面は「大きく弾く」モード: 鍵を高さに合わせて大きくし横スクロール。
                  expand: true,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_fullscreen),
                tooltip: AppLocalizations.of(context).exitFullscreen,
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

  Widget _lastNoteLabel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _lastNote,
          style: const TextStyle(
            fontFamily: 'ShipporiMincho',
            fontSize: 34,
            color: EtudeColors.brassSoft,
          ),
        ),
        Text(
          AppLocalizations.of(context).noteNameLabel,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            color: EtudeColors.ivory3,
          ),
        ),
      ],
    );
  }
}
