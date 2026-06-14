import 'package:flutter/material.dart';

/// 横スクロールするピアノ鍵盤。白鍵を並べ、黒鍵を重ねて配置する。
/// タップで [onNotePressed] にその音高(`C4` / `F#4` など)を渡す。
/// 発音そのものは呼び出し側が `AudioEngine` 経由で行う(この widget は音を鳴らさない)。
class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.onNotePressed,
    this.startOctave = 3,
    this.octaveCount = 3,
    this.whiteKeyWidth = 40,
    this.blackKeyWidth = 26,
    this.height = 150,
  });

  final void Function(String pitch) onNotePressed;
  final int startOctave;
  final int octaveCount;
  final double whiteKeyWidth;
  final double blackKeyWidth;
  final double height;

  static const _whiteLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  // 各白鍵の右肩に乗る黒鍵(B と E の後には無い)。
  static const _blackAfter = {
    'C': 'C#',
    'D': 'D#',
    'F': 'F#',
    'G': 'G#',
    'A': 'A#',
  };

  @override
  Widget build(BuildContext context) {
    final whites = <({String pitch, String letter, int octave})>[];
    for (var o = 0; o < octaveCount; o++) {
      final octave = startOctave + o;
      for (final letter in _whiteLetters) {
        whites.add((pitch: '$letter$octave', letter: letter, octave: octave));
      }
    }

    final blackKeys = <Widget>[];
    for (var i = 0; i < whites.length; i++) {
      final black = _blackAfter[whites[i].letter];
      if (black == null) continue;
      final pitch = '$black${whites[i].octave}';
      blackKeys.add(
        Positioned(
          left: (i + 1) * whiteKeyWidth - blackKeyWidth / 2,
          top: 0,
          child: _BlackKey(
            pitch: pitch,
            width: blackKeyWidth,
            height: height * 0.62,
            onPressed: () => onNotePressed(pitch),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: whites.length * whiteKeyWidth,
          height: height,
          child: Stack(
            children: [
              Row(
                children: [
                  for (final w in whites)
                    _WhiteKey(
                      pitch: w.pitch,
                      width: whiteKeyWidth,
                      label: w.letter == 'C' ? w.pitch : null,
                      onPressed: () => onNotePressed(w.pitch),
                    ),
                ],
              ),
              ...blackKeys,
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteKey extends StatelessWidget {
  const _WhiteKey({
    required this.pitch,
    required this.width,
    required this.onPressed,
    this.label,
  });

  final String pitch;
  final double width;
  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: pitch,
      button: true,
      child: GestureDetector(
        key: ValueKey('key-$pitch'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onPressed(),
        child: Container(
          width: width,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F1E4), Color(0xFFE2D5BB)],
            ),
            border: Border.all(color: const Color(0xFFCABFA6)),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(6),
            ),
          ),
          child: label == null
              ? null
              : Text(
                  label!,
                  style: const TextStyle(fontSize: 9, color: Color(0xFFA99873)),
                ),
        ),
      ),
    );
  }
}

class _BlackKey extends StatelessWidget {
  const _BlackKey({
    required this.pitch,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  final String pitch;
  final double width;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: pitch,
      button: true,
      child: GestureDetector(
        key: ValueKey('key-$pitch'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onPressed(),
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A3040), Color(0xFF0F0B14)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}
