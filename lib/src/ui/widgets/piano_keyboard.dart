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
    this.maxWhiteKeyWidth = 72,
    this.blackKeyWidth = 26,
    this.height = 150,
    this.expand = false,
    this.litPitches = const {},
  });

  final void Function(String pitch) onNotePressed;
  final int startOctave;
  final int octaveCount;

  /// 白鍵の最小幅(=既定幅)。画面が狭ければこの幅で横スクロールする。
  final double whiteKeyWidth;

  /// 白鍵の最大幅。タブレット等で広げすぎないための上限。
  final double maxWhiteKeyWidth;
  final double blackKeyWidth;

  /// 鍵盤に与えられる高さ(利用可能高さ)。実際の描画高さは鍵幅に対する比率で
  /// 頭打ちにして、縦に間延びしないようにする。
  final double height;

  /// 「大きく弾く」モード(全画面など)。鍵を高さに合わせて大きくし、画面に
  /// 収まらなければ横スクロールする。false のときは全鍵が幅に収まるよう敷き詰める。
  final bool expand;

  /// 白鍵の高さ/幅の比(ピアノらしい縦横比の上限)。
  static const double _heightToWidthRatio = 5.0;

  /// expand 時の白鍵の最大幅(大きくしすぎて 1〜2 鍵しか見えないのを防ぐ)。
  static const double _expandMaxWhiteKeyWidth = 96;

  /// 光らせる(鳴っている)音高。再生/試聴中のハイライト用。
  final Set<String> litPitches;

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
    final n = whites.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : n * whiteKeyWidth;
        // 鍵幅の決め方:
        // - expand(全画面など): 与えられた高さに合わせて鍵を大きくし(比率を保つ)、
        //   はみ出せば横スクロール。「大きく弾く」用。
        // - 通常: 全鍵が画面幅に収まるよう敷き詰める(端末幅に追従)。
        final keyW = expand
            ? (height / _heightToWidthRatio).clamp(
                whiteKeyWidth,
                _expandMaxWhiteKeyWidth,
              )
            : (available / n).clamp(whiteKeyWidth, maxWhiteKeyWidth);
        final blackW = blackKeyWidth * (keyW / whiteKeyWidth);
        final boardWidth = n * keyW;
        // 鍵幅に対して縦に間延びしないよう、描画高さを比率で頭打ちにする。
        final boardHeight = height.clamp(0.0, keyW * _heightToWidthRatio);

        final blackKeys = <Widget>[];
        for (var i = 0; i < n; i++) {
          final black = _blackAfter[whites[i].letter];
          if (black == null) continue;
          final pitch = '$black${whites[i].octave}';
          blackKeys.add(
            Positioned(
              left: (i + 1) * keyW - blackW / 2,
              top: 0,
              child: _BlackKey(
                pitch: pitch,
                width: blackW,
                height: boardHeight * 0.62,
                lit: litPitches.contains(pitch),
                onPressed: () => onNotePressed(pitch),
              ),
            ),
          );
        }

        final board = SizedBox(
          width: boardWidth,
          height: boardHeight,
          child: Stack(
            children: [
              // Positioned.fill + stretch で白鍵を高さいっぱいに伸ばす。
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final w in whites)
                      _WhiteKey(
                        pitch: w.pitch,
                        width: keyW,
                        label: w.letter == 'C' ? w.pitch : null,
                        lit: litPitches.contains(w.pitch),
                        onPressed: () => onNotePressed(w.pitch),
                      ),
                  ],
                ),
              ),
              ...blackKeys,
            ],
          ),
        );

        // 収まる時はそのまま(下端の Align が横中央寄せも兼ねる)、はみ出す時は
        // 横スクロール。いずれも下の Align で画面下端に揃える。
        final content = boardWidth <= available + 0.5
            ? board
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: board,
              );

        return SizedBox(
          height: height,
          width: double.infinity,
          child: Align(alignment: Alignment.bottomCenter, child: content),
        );
      },
    );
  }
}

class _WhiteKey extends StatelessWidget {
  const _WhiteKey({
    required this.pitch,
    required this.width,
    required this.onPressed,
    this.label,
    this.lit = false,
  });

  final String pitch;
  final double width;
  final String? label;
  final bool lit;
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // 鳴っている鍵は真鍮色に光らせる。
              colors: lit
                  ? const [Color(0xFFF3DCA4), Color(0xFFEDD293)]
                  : const [Color(0xFFF7F1E4), Color(0xFFE2D5BB)],
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
    this.lit = false,
  });

  final String pitch;
  final double width;
  final double height;
  final bool lit;
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // 鳴っている鍵は真鍮色に光らせる。
              colors: lit
                  ? const [Color(0xFF6B5320), Color(0xFF3A2C10)]
                  : const [Color(0xFF3A3040), Color(0xFF0F0B14)],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
