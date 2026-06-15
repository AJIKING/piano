import 'package:flutter/material.dart';

import '../../application/editor_controller.dart';
import '../../application/practice_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../../domain/score/score_geometry.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_view.dart';

/// 楽譜エディタ(レールの「編集」タブ)。譜面/鍵盤タップで音符を追加・選択し、
/// 音価/♯ を編集する。戻る/進む・末尾へ・初期版へ戻す・試聴(テンポ可変)を備える。
///
/// 編集状態 [controller] はシェルが所有する(タブを切り替えても保持される)。
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.controller,
    required this.audioEngine,
    this.onSave,
  });

  final EditorController controller;
  final AudioEngine audioEngine;

  /// 「保存する」で編集内容を永続化する(シェルが LibraryStore へ保存)。
  final VoidCallback? onSave;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const _geometry = ScoreGeometry();

  late final PracticeController _preview;
  late final TextEditingController _titleField;
  final ScrollController _scoreScroll = ScrollController();
  double? _lastCaret;

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
    _editor.addListener(_keepCaretVisible);
  }

  @override
  void dispose() {
    _editor.removeListener(_keepCaretVisible);
    _preview.dispose();
    _titleField.dispose();
    _scoreScroll.dispose();
    super.dispose();
  }

  /// 編集でキャレットが動いたら、譜面が見切れないよう自動スクロールする
  /// (末尾への追加で新しい音符が見えるように)。キャレットが動いた時だけ実行する。
  void _keepCaretVisible() {
    if (_editor.insertBeat == _lastCaret) return;
    _lastCaret = _editor.insertBeat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scoreScroll.hasClients) return;
      final caretX = _geometry.xAtBeat(_editor.insertBeat);
      final pos = _scoreScroll.position;
      final left = pos.pixels;
      final right = left + pos.viewportDimension;
      if (caretX < left + 40 || caretX > right - 40) {
        final target = (caretX - pos.viewportDimension * 0.6).clamp(
          0.0,
          pos.maxScrollExtent,
        );
        _scoreScroll.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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

  void _save() {
    widget.onSave?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました'), duration: Duration(seconds: 1)),
    );
  }

  /// undo/redo/reset で曲名が変わったら入力欄へ反映する(タイピングには干渉しない)。
  void _syncTitleField() {
    final text = _editor.title;
    if (_titleField.text == text) return;
    _titleField.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _undo() {
    _editor.undo();
    _syncTitleField();
  }

  void _redo() {
    _editor.redo();
    _syncTitleField();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最初の状態に戻す'),
        content: const Text('この曲の編集を取り消して、最初に用意された楽譜に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('戻す'),
          ),
        ],
      ),
    );
    if (!mounted || !(ok ?? false)) return;
    _editor.resetToOriginal();
    _syncTitleField();
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
                  geometry: _geometry,
                  selectedIndex: _editor.selectedIndex,
                  caretBeat: _editor.insertBeat,
                  snap: _editor.currentDuration,
                  height: 120,
                  scrollController: _scoreScroll,
                  onAddAt: (beat, step) =>
                      _editor.addNoteAtStep(beat: beat, step: step),
                  onSelectNote: _editor.selectNote,
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
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

  /// 曲名(左・可変幅)とテンポ・試聴・保存を 1 行に並べる。
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
          _bpmControl(),
          const SizedBox(width: 4),
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
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('保存する'),
          ),
        ],
      ),
    );
  }

  /// 試聴のテンポ(BPM)を −/+ で設定する。
  Widget _bpmControl() {
    return ListenableBuilder(
      listenable: _preview,
      builder: (context, _) {
        final bpm = _preview.bpm;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'テンポを下げる',
              icon: const Icon(Icons.remove, size: 18),
              onPressed: bpm > PracticeController.minBpm
                  ? () => _preview.setBpm(bpm - 4)
                  : null,
            ),
            Text(
              '${bpm.round()}',
              style: const TextStyle(
                fontFamily: EtudeTheme.mono,
                color: EtudeColors.brassSoft,
              ),
            ),
            const Text(
              ' BPM',
              style: TextStyle(fontSize: 9, color: EtudeColors.ivory3),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'テンポを上げる',
              icon: const Icon(Icons.add, size: 18),
              onPressed: bpm < PracticeController.maxBpm
                  ? () => _preview.setBpm(bpm + 4)
                  : null,
            ),
          ],
        );
      },
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
          IconButton(
            tooltip: '戻る',
            icon: const Icon(Icons.undo),
            onPressed: _editor.canUndo ? _undo : null,
          ),
          IconButton(
            tooltip: '進む',
            icon: const Icon(Icons.redo),
            onPressed: _editor.canRedo ? _redo : null,
          ),
          IconButton(
            tooltip: '末尾へ(末尾に追加しやすくする)',
            icon: const Icon(Icons.last_page),
            onPressed: _editor.moveCaretToEnd,
          ),
          IconButton(
            tooltip: '選択を削除',
            icon: const Icon(Icons.backspace_outlined),
            onPressed: _editor.deleteSelected,
          ),
          IconButton(
            tooltip: '全消去',
            icon: const Icon(Icons.delete_outline),
            onPressed: _editor.clearAll,
          ),
          if (_editor.canReset)
            IconButton(
              tooltip: '最初の状態に戻す',
              icon: const Icon(Icons.restore),
              onPressed: _confirmReset,
            ),
          Text(
            '音符数: ${_editor.noteCount}',
            style: const TextStyle(fontSize: 11, color: EtudeColors.ivory3),
          ),
        ],
      ),
    );
  }
}
