import 'package:flutter/material.dart';

import '../../application/editor_controller.dart';
import '../../application/practice_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_view.dart';

/// 楽譜エディタ(レールの「編集」タブ)。譜面/鍵盤タップで音符を追加・選択し、
/// 音価/♯ を編集する。
///
/// 編集状態 [controller] はシェルが所有する(タブを切り替えても保持される)。
/// この widget は描画と試聴・練習への切替だけを担う。
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.controller,
    required this.audioEngine,
    this.onPractice,
  });

  final EditorController controller;
  final AudioEngine audioEngine;

  /// 「練習する」で練習タブへ切り替える(シェルが現在の編集内容で練習を開く)。
  final VoidCallback? onPractice;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final PracticeController _preview;
  late final TextEditingController _titleField;

  EditorController get _editor => widget.controller;

  // 音価ツール。value=拍, label=表示, tip=説明(付点2分 / 2分 / 4分 / 8分)。
  static const _durations = <({double value, String label, String tip})>[
    (value: 3, label: '2.', tip: '付点2分音符'),
    (value: 2, label: '2', tip: '2分音符'),
    (value: 1, label: '4', tip: '4分音符'),
    (value: 0.5, label: '8', tip: '8分音符'),
  ];

  @override
  void initState() {
    super.initState();
    _preview = PracticeController(
      piece: _editor.currentPiece,
      audioEngine: widget.audioEngine,
    );
    _titleField = TextEditingController(text: _editor.title);
  }

  @override
  void dispose() {
    _preview.dispose();
    _titleField.dispose();
    super.dispose();
  }

  void _onKeyboard(String pitch) {
    widget.audioEngine.init();
    widget.audioEngine.playNote(pitch);
    _editor.addNoteFromKeyboard(pitch);
  }

  void _togglePreview() {
    if (_preview.isPlaying) {
      _preview.stop();
    } else {
      _preview.piece = _editor.currentPiece;
      _preview.play();
    }
  }

  void _practice() {
    _preview.stop();
    widget.onPractice?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _editor,
        builder: (context, _) {
          return Column(
            children: [
              _titleBar(),
              _toolbar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: ScoreView(
                  piece: _editor.currentPiece,
                  selectedIndex: _editor.selectedIndex,
                  caretBeat: _editor.insertBeat,
                  snap: _editor.currentDuration,
                  height: 120,
                  onAddAt: (beat, step) =>
                      _editor.addNoteAtStep(beat: beat, step: step),
                  onSelectNote: _editor.selectNote,
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              // 鍵盤は残り高さいっぱいに広げる。
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => PianoKeyboard(
                    onNotePressed: _onKeyboard,
                    height: constraints.maxHeight,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 曲名(左・可変幅)と 試聴 / 練習する ボタンを 1 行に並べる。
  Widget _titleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _titleField,
              onChanged: _editor.setTitle,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontFamily: 'ShipporiMincho',
                fontSize: 18,
              ),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                hintText: '曲名',
              ),
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: _preview,
            builder: (context, _) => TextButton.icon(
              onPressed: _togglePreview,
              icon: Icon(
                _preview.isPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(_preview.isPlaying ? '停止' : '試聴'),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(onPressed: _practice, child: const Text('練習する')),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              for (final d in _durations)
                ButtonSegment(
                  value: d.value,
                  label: Text(d.label),
                  tooltip: d.tip,
                ),
            ],
            selected: {_editor.currentDuration},
            onSelectionChanged: (s) => _editor.setDuration(s.first),
          ),
          FilterChip(
            label: const Text('♯'),
            selected: _editor.currentSharp,
            onSelected: (_) => _editor.toggleSharp(),
          ),
          TextButton(
            onPressed: _editor.deleteSelected,
            child: const Text('選択を削除'),
          ),
          TextButton(onPressed: _editor.clearAll, child: const Text('全消去')),
          Text(
            '音符数: ${_editor.noteCount}',
            style: const TextStyle(fontSize: 11, color: EtudeColors.ivory3),
          ),
        ],
      ),
    );
  }
}
