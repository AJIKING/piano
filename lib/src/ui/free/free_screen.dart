import 'package:flutter/material.dart';

import '../../domain/audio/audio_engine.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';

/// 自由演奏画面。フル鍵盤をタップして発音し、最後に弾いた音名を表示する。
class FreeScreen extends StatefulWidget {
  const FreeScreen({super.key, required this.audioEngine});

  final AudioEngine audioEngine;

  @override
  State<FreeScreen> createState() => _FreeScreenState();
}

class _FreeScreenState extends State<FreeScreen> {
  String _lastNote = '—';
  bool _audioReady = false;

  void _onNote(String pitch) {
    if (!_audioReady) {
      widget.audioEngine.init();
      _audioReady = true;
    }
    widget.audioEngine.playNote(pitch);
    setState(() => _lastNote = pitch.replaceAll('#', '♯'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自由演奏')),
      body: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _lastNote,
                    style: const TextStyle(
                      fontFamily: 'ShipporiMincho',
                      fontSize: 34,
                      color: EtudeColors.brassSoft,
                    ),
                  ),
                  const Text(
                    'LAST NOTE',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: EtudeColors.ivory3,
                    ),
                  ),
                ],
              ),
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
}
