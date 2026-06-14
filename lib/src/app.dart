import 'package:flutter/material.dart';

import 'application/dependencies.dart';
import 'application/library_controller.dart';
import 'ui/library/library_screen.dart';
import 'ui/theme/etude_theme.dart';

/// アプリのルート。差し替え境界([Dependencies])を受け取り、
/// 画面横断の状態(`LibraryController`)を組み立てて初期画面を描画する。
class EtudeApp extends StatefulWidget {
  const EtudeApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  State<EtudeApp> createState() => _EtudeAppState();
}

class _EtudeAppState extends State<EtudeApp> {
  late final LibraryController _library;

  @override
  void initState() {
    super.initState();
    _library = LibraryController(
      repository: widget.dependencies.scoreRepository,
      store: widget.dependencies.libraryStore,
      clock: widget.dependencies.clock,
    );
    // 永続化済みコレクションがあれば反映(無ければ収録曲 seed のまま)。
    _library.restore();
  }

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Étude',
      debugShowCheckedModeBanner: false,
      theme: EtudeTheme.dark(),
      home: LibraryScreen(
        controller: _library,
        audioEngine: widget.dependencies.audioEngine,
      ),
    );
  }
}
