import 'package:flutter/material.dart';

import '../../application/library_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../../domain/score/piece.dart';
import '../editor/editor_screen.dart';
import '../free/free_screen.dart';
import '../practice/practice_screen.dart';
import '../theme/etude_theme.dart';
import 'now_practicing_card.dart';

/// ライブラリ画面。「今練習中」カード＋マイ楽譜一覧＋楽譜作成。
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.controller,
    required this.audioEngine,
  });

  final LibraryController controller;
  final AudioEngine audioEngine;

  void _openPractice(BuildContext context, Piece piece) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          piece: piece,
          audioEngine: audioEngine,
          // 弾き切ったら習得度を上げて最終練習日時を記録・永続化する。
          onCompleted: () => controller.recordPractice(piece.id),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, Piece piece) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(
          piece: piece,
          audioEngine: audioEngine,
          // 編集結果を永続化する。
          onSave: controller.savePiece,
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final piece = await controller.createPiece();
    if (context.mounted) _openEditor(context, piece);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ライブラリ'),
        actions: [
          IconButton(
            tooltip: '自由演奏',
            icon: const Icon(Icons.music_note_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FreeScreen(audioEngine: audioEngine),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('楽譜を作成'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final pieces = controller.pieces;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              NowPracticingCard(
                piece: controller.featured,
                lastPracticedLabel: controller.lastPracticedLabel(
                  controller.featured,
                ),
                onResume: () => _openPractice(context, controller.featured),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
                child: Text(
                  'マイ楽譜',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    color: EtudeColors.ivory2,
                  ),
                ),
              ),
              for (final (i, piece) in pieces.indexed)
                _PieceRow(
                  index: i,
                  piece: piece,
                  onOpen: () => _openPractice(context, piece),
                  onEdit: () => _openEditor(context, piece),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PieceRow extends StatelessWidget {
  const _PieceRow({
    required this.index,
    required this.piece,
    required this.onOpen,
    required this.onEdit,
  });

  final int index;
  final Piece piece;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final stars = '★' * piece.stars + '☆' * (5 - piece.stars);
    return ListTile(
      onTap: onOpen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EtudeColors.ink3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EtudeColors.inkLine),
        ),
        child: Text(
          (index + 1).toString().padLeft(2, '0'),
          style: const TextStyle(
            fontFamily: 'ShipporiMincho',
            color: EtudeColors.brassSoft,
          ),
        ),
      ),
      title: Text(
        piece.title,
        style: const TextStyle(fontFamily: 'ShipporiMincho', fontSize: 15),
      ),
      subtitle: Text(
        piece.composer,
        style: const TextStyle(fontSize: 11, color: EtudeColors.ivory3),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stars,
            style: const TextStyle(color: EtudeColors.brass, fontSize: 10),
          ),
          IconButton(
            tooltip: '編集',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
