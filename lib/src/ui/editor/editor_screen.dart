import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../application/editor_controller.dart';
import '../../application/practice_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../../domain/score/score_geometry.dart';
import '../theme/etude_theme.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_scroll_follower.dart';
import '../widgets/score_view.dart';

/// 楽譜エディタ(レールの「編集」タブ)。譜面/鍵盤タップで音符を追加・選択し、
/// 音価/♯ を編集する。戻る/進む・末尾へ・初期版へ戻す・試聴(テンポ可変・
/// 選択位置から・鍵盤と譜面のハイライト)・ツールバーの表示切替を備える。
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
  late final Listenable _editAndPreview;
  final ScoreScrollFollower _follow = ScoreScrollFollower();
  double? _lastCaret;
  bool _toolsVisible = true;
  bool _previewing = false;

  EditorController get _editor => widget.controller;

  // 音価ツール。value=拍, label=表示(数字なので翻訳不要)。説明は [_durationTip]。
  static const _durations = <({double value, String label})>[
    (value: 3, label: '2.'),
    (value: 2, label: '2'),
    (value: 1.5, label: '4.'),
    (value: 1, label: '4'),
    (value: 0.5, label: '8'),
    (value: 0.25, label: '16'),
  ];

  /// 音価ツールの説明(ツールチップ)を表示言語で返す。
  static String _durationTip(AppLocalizations l, double value) =>
      switch (value) {
        3 => l.dottedHalfNote,
        2 => l.halfNote,
        1.5 => l.dottedQuarterNote,
        1 => l.quarterNote,
        0.5 => l.eighthNote,
        _ => l.sixteenthNote,
      };

  @override
  void initState() {
    super.initState();
    _preview = PracticeController(
      piece: _editor.currentPiece,
      audioEngine: widget.audioEngine,
      bpm: _editor.currentPiece.defaultBpm.toDouble(),
    );
    _titleField = TextEditingController(text: _editor.title);
    _editAndPreview = Listenable.merge([_editor, _preview]);
    _editor.addListener(_keepCaretVisible);
    _preview.addListener(_onPreviewChanged);
    // 鳴る音が変わるたびに(=毎フレームではなく)再生ヘッドを追従させる。
    _preview.litPitches.addListener(_followPlayhead);
  }

  @override
  void dispose() {
    _editor.removeListener(_keepCaretVisible);
    _preview.litPitches.removeListener(_followPlayhead);
    _preview.removeListener(_onPreviewChanged);
    _preview.dispose();
    _titleField.dispose();
    _follow.dispose();
    super.dispose();
  }

  /// 試聴の開始/停止に合わせて編集ロック状態を切り替える(毎フレームではなく状態変化時のみ)。
  void _onPreviewChanged() {
    if (_preview.isPlaying != _previewing) {
      setState(() => _previewing = _preview.isPlaying);
    }
  }

  /// 試聴中、再生ヘッドが見切れたら譜面をスクロールして追従する。
  /// ただしユーザーが手動スクロール中は [ScoreScrollFollower] 側で追従を止める。
  void _followPlayhead() => _follow.follow(
    isActive: () => _preview.isPlaying,
    targetX: () => _geometry.xAtBeat(_preview.playheadBeats),
  );

  /// 編集でキャレットが動いたら、譜面が見切れないよう自動スクロールする。
  void _keepCaretVisible() {
    if (_editor.insertBeat == _lastCaret) return;
    _lastCaret = _editor.insertBeat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_follow.controller.hasClients) return;
      final caretX = _geometry.xAtBeat(_editor.insertBeat);
      final pos = _follow.controller.position;
      if (caretX < pos.pixels + 40 ||
          caretX > pos.pixels + pos.viewportDimension - 40) {
        _follow.controller.animateTo(
          (caretX - pos.viewportDimension * 0.6).clamp(
            0.0,
            pos.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onKeyboard(String pitch) {
    widget.audioEngine.init();
    widget.audioEngine.playNote(pitch);
    // 試聴中は弾き合わせのみ(音符は追加しない。発音と描画の乖離を防ぐ)。
    if (_previewing) return;
    _editor.addNoteFromKeyboard(pitch);
  }

  void _togglePreview() {
    if (_preview.isPlaying) {
      _preview.stop();
    } else {
      _follow.resume(); // 試聴開始で追従を復帰。
      _preview.piece = _editor.currentPiece;
      // 音符を選択していればその位置から、無ければ先頭から試聴する。
      final i = _editor.selectedIndex;
      final notes = _editor.notes;
      final from = (i != null && i < notes.length) ? notes[i].beat : 0.0;
      _preview.play(fromBeat: from);
    }
  }

  void _save() {
    widget.onSave?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).saved),
        duration: const Duration(seconds: 1),
      ),
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
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.resetTitle),
        content: Text(l.resetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.reset),
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
      body: Column(
        children: [
          _titleBar(),
          if (_toolsVisible)
            // 試聴中は編集ロック(発音スナップショットと描画の乖離を防ぐ)。
            AbsorbPointer(
              absorbing: _previewing,
              child: Opacity(
                opacity: _previewing ? 0.4 : 1,
                child: ListenableBuilder(
                  listenable: _editor,
                  builder: (context, _) => _toolbar(),
                ),
              ),
            ),
          _toolsHandle(),
          // 編集中はキャレット/選択、試聴中は再生ヘッド/該当音符をハイライトする。
          ListenableBuilder(
            listenable: _editAndPreview,
            builder: (context, _) {
              final previewing = _preview.isPlaying;
              // 試聴中の手動ドラッグで自動追従を止める。
              return _follow.wrap(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ScoreView(
                    piece: _editor.currentPiece,
                    geometry: _geometry,
                    selectedIndex: previewing ? null : _editor.selectedIndex,
                    caretBeat: previewing ? null : _editor.insertBeat,
                    litNoteIndices: previewing
                        ? _preview.litNoteIndices
                        : const {},
                    playheadX: previewing
                        ? _geometry.xAtBeat(_preview.playheadBeats)
                        : null,
                    snap: _editor.currentDuration,
                    height: 120,
                    scrollController: _follow.controller,
                    // 試聴中は誤編集を避けるためタップを無効化する。
                    onAddAt: previewing
                        ? null
                        : (beat, step) =>
                              _editor.addNoteAtStep(beat: beat, step: step),
                    onSelectNote: previewing ? null : _editor.selectNote,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _preview.litPitches,
                    builder: (context, lit, _) => PianoKeyboard(
                      onNotePressed: _onKeyboard,
                      height: constraints.maxHeight,
                      litPitches: lit,
                    ),
                  ),
            ),
          ),
        ],
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
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: AppLocalizations.of(context).songNameHint,
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
              label: Text(
                _preview.isPlaying
                    ? AppLocalizations.of(context).stop
                    : AppLocalizations.of(context).preview,
              ),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(AppLocalizations.of(context).save),
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
              tooltip: AppLocalizations.of(context).tempoDown,
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
              tooltip: AppLocalizations.of(context).tempoUp,
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

  /// ツールバーの表示/非表示を切り替える細い帯(タップ or 上下スワイプ)。
  Widget _toolsHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _toolsVisible = !_toolsVisible),
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -80 && _toolsVisible) setState(() => _toolsVisible = false);
        if (v > 80 && !_toolsVisible) setState(() => _toolsVisible = true);
      },
      child: SizedBox(
        height: 20,
        child: Center(
          child: Icon(
            _toolsVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 18,
            color: EtudeColors.ivory3,
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    final l = AppLocalizations.of(context);
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
                  tooltip: _durationTip(l, d.value),
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
            tooltip: l.undo,
            icon: const Icon(Icons.undo),
            onPressed: _editor.canUndo ? _undo : null,
          ),
          IconButton(
            tooltip: l.redo,
            icon: const Icon(Icons.redo),
            onPressed: _editor.canRedo ? _redo : null,
          ),
          IconButton(
            tooltip: l.toEnd,
            icon: const Icon(Icons.last_page),
            onPressed: _editor.moveCaretToEnd,
          ),
          IconButton(
            tooltip: l.deleteSelection,
            icon: const Icon(Icons.backspace_outlined),
            onPressed: _editor.deleteSelected,
          ),
          IconButton(
            tooltip: l.clearAll,
            icon: const Icon(Icons.delete_outline),
            onPressed: _editor.clearAll,
          ),
          if (_editor.canReset)
            IconButton(
              tooltip: l.resetToOriginal,
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: _confirmReset,
            ),
          Text(
            l.noteCount(_editor.noteCount),
            style: const TextStyle(fontSize: 11, color: EtudeColors.ivory3),
          ),
        ],
      ),
    );
  }
}
