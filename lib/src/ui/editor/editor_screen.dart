import 'package:flutter/material.dart';

import '../../application/editor_controller.dart';
import '../../application/practice_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../../domain/score/piece.dart';
import '../practice/practice_screen.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_view.dart';

/// 楽譜エディタ。譜面/鍵盤タップで音符を追加・選択し、音価/♯ を編集する。
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.piece,
    required this.audioEngine,
    this.onSave,
  });

  final Piece piece;
  final AudioEngine audioEngine;

  /// 編集結果を保存する(LibraryStore へ永続化)。エディタを離れる時と練習開始時に呼ぶ。
  final void Function(Piece piece)? onSave;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _editor;
  late final PracticeController _preview;
  late final TextEditingController _titleField;

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
    _editor = EditorController(piece: widget.piece);
    _preview = PracticeController(
      piece: widget.piece,
      audioEngine: widget.audioEngine,
    );
    _titleField = TextEditingController(text: widget.piece.title);
  }

  @override
  void dispose() {
    _editor.dispose();
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

  void _openPractice() {
    _preview.stop();
    widget.onSave?.call(_editor.currentPiece);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          piece: _editor.currentPiece,
          audioEngine: widget.audioEngine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // 戻る操作で編集結果を永続化する(dispose 中だと再描画と競合するため)。
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onSave?.call(_editor.currentPiece);
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('楽譜エディタ'),
        actions: [
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _openPractice,
              child: const Text('練習する'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _editor,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _titleField,
                  onChanged: _editor.setTitle,
                  maxLength: 40,
                  style: const TextStyle(
                    fontFamily: 'ShipporiMincho',
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    labelText: '曲名',
                    counterText: '',
                  ),
                ),
              ),
              _toolbar(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ScoreView(
                  piece: _editor.currentPiece,
                  selectedIndex: _editor.selectedIndex,
                  caretBeat: _editor.insertBeat,
                  snap: _editor.currentDuration,
                  onAddAt: (beat, step) =>
                      _editor.addNoteAtStep(beat: beat, step: step),
                  onSelectNote: _editor.selectNote,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: PianoKeyboard(onNotePressed: _onKeyboard, height: 150),
                ),
              ),
            ],
          );
        },
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
