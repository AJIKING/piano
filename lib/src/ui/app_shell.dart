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

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const _kLibrary = 0;
  static const _kPractice = 1;
  static const _kEditor = 2;
  static const _kFree = 3;

  late final LibraryController _library;
  late EditorController _editor;
  int _index = _kLibrary;
  bool _railOpen = true;

  AudioEngine get _audio => widget.dependencies.audioEngine;

  /// 編集状態を生成する。収録曲なら初期版(`original`)を渡して「元に戻す」を可能にする。
  EditorController _makeEditor(Piece piece) => EditorController(
    piece: piece,
    original: widget.dependencies.scoreRepository.original(piece.id),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 音源(SoundFont)のロードは時間がかかるので起動時に先読みしておく
    // (初回の試聴・再生で音が詰まる/出ないのを防ぐ)。
    _audio.init();
    _library = LibraryController(
      repository: widget.dependencies.scoreRepository,
      store: widget.dependencies.libraryStore,
      clock: widget.dependencies.clock,
    );
    _editor = _makeEditor(_library.featured);
    _restore();
  }

  Future<void> _restore() async {
    await _library.restore();
    if (!mounted) return;
    // 永続化済みの featured を初期編集対象へ反映(まだ何も操作していない時のみ。
    // 編集/練習タブへ移っている場合はユーザー操作を尊重して触らない)。
    if (_index == _kLibrary &&
        _editor.currentPiece.id == _library.featured.id) {
      setState(() {
        _editor.dispose();
        _editor = _makeEditor(_library.featured);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンド化/終了の手前で未保存の編集を永続化する。
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _persistEditor();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _editor = _makeEditor(piece);
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

  Widget _content() {
    switch (_index) {
      case _kPractice:
        // 再生対象と記録対象を同じ piece に固定する(完了時に参照がブレない)。
        final piece = _editor.currentPiece;
        return PracticeScreen(
          key: ValueKey('practice-${piece.id}'),
          piece: piece,
          audioEngine: _audio,
          onCompleted: () => _library.recordPractice(piece.id),
        );
      case _kEditor:
        // controller が差し替わったら State を作り直す(古い曲名/試聴対象を残さない)。
        return EditorScreen(
          key: ValueKey(_editor),
          controller: _editor,
          audioEngine: _audio,
          onSave: _persistEditor,
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
            _railOpen ? _rail() : _collapsedBar(),
            const VerticalDivider(width: 1),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  /// 開いた状態のナビゲーションレール(先頭に閉じるボタン)。
  Widget _rail() {
    return NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: _select,
      labelType: NavigationRailLabelType.all,
      leading: IconButton(
        icon: const Icon(Icons.menu_open),
        tooltip: 'メニューを閉じる',
        onPressed: () => setState(() => _railOpen = false),
      ),
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
    );
  }

  /// 閉じた状態の細い帯(開くボタンのみ)。本文を広く使える。
  Widget _collapsedBar() {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          const SizedBox(height: 4),
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'メニューを開く',
            onPressed: () => setState(() => _railOpen = true),
          ),
        ],
      ),
    );
  }
}
