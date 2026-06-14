import 'package:flutter/material.dart';

import '../../application/library_controller.dart';
import '../../domain/score/piece.dart';
import '../theme/etude_theme.dart';
import 'now_practicing_card.dart';

/// ライブラリ画面(レールの「楽譜」タブ)。「今練習中」カード＋マイ楽譜一覧＋作成。
///
/// 画面遷移は持たず、曲を開く操作は [onOpenPractice] / [onOpenEditor] に委ねる
/// (シェルがタブを切り替える)。
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.controller,
    required this.onOpenPractice,
    required this.onOpenEditor,
  });

  final LibraryController controller;
  final void Function(Piece piece) onOpenPractice;
  final void Function(Piece piece) onOpenEditor;

  Future<void> _create() async {
    final piece = await controller.createPiece();
    onOpenEditor(piece);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ライブラリ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
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
                onResume: () => onOpenPractice(controller.featured),
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
                  onOpen: () => onOpenPractice(piece),
                  onEdit: () => onOpenEditor(piece),
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
      trailing: IconButton(
        tooltip: '編集',
        icon: const Icon(Icons.edit_outlined, size: 18),
        onPressed: onEdit,
      ),
    );
  }
}
