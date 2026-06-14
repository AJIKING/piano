import 'package:flutter/material.dart';

import '../application/dependencies.dart';
import '../application/editor_controller.dart';
import '../application/library_controller.dart';
import '../domain/audio/audio_engine.dart';
import '../domain/score/piece.dart';
import 'editor/editor_screen.dart';
import 'free/free_screen.dart';
import 'library/library_screen.dart';
import 'practice/practice_screen.dart';

/// アプリの骨格。左の `NavigationRail`(楽譜 / 練習 / 編集 / 演奏)で 4 つの画面を
/// 切り替える。横画面前提で、縦の余白を鍵盤に回すため左レールにする。
///
/// 編集状態([EditorController])と現在曲はシェルが所有し、タブを跨いでも保持する。
/// 練習はこの編集中の曲を再生するので、編集→練習で内容が反映される。
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _kLibrary = 0;
  static const _kPractice = 1;
  static const _kEditor = 2;
  static const _kFree = 3;

  late final LibraryController _library;
  late EditorController _editor;
  int _index = _kLibrary;

  AudioEngine get _audio => widget.dependencies.audioEngine;

  @override
  void initState() {
    super.initState();
    _library = LibraryController(
      repository: widget.dependencies.scoreRepository,
      store: widget.dependencies.libraryStore,
      clock: widget.dependencies.clock,
    );
    _editor = EditorController(piece: _library.featured);
    _library.restore();
  }

  @override
  void dispose() {
    _editor.dispose();
    _library.dispose();
    super.dispose();
  }

  /// 現在の編集内容を永続化する。
  void _persistEditor() => _library.savePiece(_editor.currentPiece);

  /// 別の曲を編集状態へ読み込む(直前の編集は保存してから差し替える)。
  void _loadPiece(Piece piece) {
    _persistEditor();
    _editor.dispose();
    _editor = EditorController(piece: piece);
  }

  void _select(int index) {
    if (index == _index) return;
    if (_index == _kEditor) _persistEditor(); // 編集タブを離れる時に保存
    setState(() => _index = index);
  }

  void _openPractice(Piece piece) {
    _loadPiece(piece);
    setState(() => _index = _kPractice);
  }

  void _openEditor(Piece piece) {
    _loadPiece(piece);
    setState(() => _index = _kEditor);
  }

  void _practiceCurrent() {
    _persistEditor();
    setState(() => _index = _kPractice);
  }

  Widget _content() {
    switch (_index) {
      case _kPractice:
        return PracticeScreen(
          piece: _editor.currentPiece,
          audioEngine: _audio,
          onCompleted: () => _library.recordPractice(_editor.currentPiece.id),
        );
      case _kEditor:
        return EditorScreen(
          controller: _editor,
          audioEngine: _audio,
          onPractice: _practiceCurrent,
        );
      case _kFree:
        return FreeScreen(audioEngine: _audio);
      case _kLibrary:
      default:
        return LibraryScreen(
          controller: _library,
          onOpenPractice: _openPractice,
          onOpenEditor: _openEditor,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: Text('楽譜'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.piano_outlined),
                  selectedIcon: Icon(Icons.piano),
                  label: Text('練習'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit_outlined),
                  selectedIcon: Icon(Icons.edit),
                  label: Text('編集'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: Text('演奏'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }
}
