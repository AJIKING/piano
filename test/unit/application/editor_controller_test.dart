import 'package:etude/src/application/editor_controller.dart';
import 'package:etude/src/domain/score/note.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixture_pieces.dart';

void main() {
  EditorController fromEmpty() => EditorController(piece: emptyUserPiece());
  EditorController fromTwoBeat() => EditorController(piece: twoBeatMelody());

  group('初期状態', () {
    test('空の曲はキャレット 0・音符なし', () {
      final c = fromEmpty();
      expect(c.noteCount, 0);
      expect(c.insertBeat, 0);
      expect(c.selectedIndex, isNull);
    });

    test('既存曲はキャレットが終端拍', () {
      expect(fromTwoBeat().insertBeat, 2);
    });
  });

  group('鍵盤からの追加', () {
    test('キャレット位置に置き、選択し、キャレットを進める', () {
      final c = fromEmpty();
      c.addNoteFromKeyboard('C4');
      expect(c.noteCount, 1);
      expect(c.notes.first, const Note(pitch: 'C4', beat: 0, duration: 1));
      expect(c.selectedIndex, 0);
      expect(c.insertBeat, 1);

      c.addNoteFromKeyboard('E4');
      expect(c.notes[1].beat, 1);
      expect(c.insertBeat, 2);
    });
  });

  group('譜面タップからの追加', () {
    test('step と ♯ ツールから音高を作る', () {
      final c = fromEmpty();
      c.toggleSharp(); // currentSharp = true
      c.addNoteAtStep(beat: 1, step: 0); // step0 = E4(E は黒鍵なし→♯付かない)
      expect(c.notes.single.pitch, 'E4');

      c.addNoteAtStep(beat: 2, step: -2); // step-2 = C4(C は黒鍵あり→♯)
      expect(c.notes.last.pitch, 'C#4');
    });

    test('beat 昇順に整列して挿入する', () {
      final c = fromEmpty();
      c.addNoteAtStep(beat: 2, step: 0);
      c.addNoteAtStep(beat: 0, step: 0);
      expect(c.notes.map((n) => n.beat), [0, 2]);
    });

    test('負の拍は 0 にクランプ', () {
      final c = fromEmpty();
      c.addNoteAtStep(beat: -3, step: 0);
      expect(c.notes.single.beat, 0);
    });
  });

  group('選択とツール', () {
    test('selectNote でキャレットがその音符直後へ', () {
      final c = fromTwoBeat();
      c.selectNote(0);
      expect(c.selectedIndex, 0);
      expect(c.insertBeat, 1); // C4@0 d1 の直後
    });

    test('setDuration は選択中の音符の音価も変える', () {
      final c = fromTwoBeat();
      c.selectNote(1);
      c.setDuration(2);
      expect(c.currentDuration, 2);
      expect(c.notes[1].duration, 2);
    });

    test('toggleSharp は黒鍵を持つ選択音符の ♯ を切り替える', () {
      final c = fromTwoBeat(); // [C4, E4]
      c.selectNote(0); // C4(♯ 可)
      c.toggleSharp();
      expect(c.notes[0].pitch, 'C#4');
      c.toggleSharp();
      expect(c.notes[0].pitch, 'C4');
    });

    test('toggleSharp は黒鍵の無い音名(E)を変えない', () {
      final c = fromTwoBeat();
      c.selectNote(1); // E4(♯ 不可)
      c.toggleSharp();
      expect(c.notes[1].pitch, 'E4');
    });
  });

  group('和音(同 beat の音符)', () {
    test('同 beat は音高順に安定整列する', () {
      final c = fromEmpty();
      c.addNoteAtStep(beat: 0, step: 2); // G4
      c.addNoteAtStep(beat: 0, step: 0); // E4
      c.addNoteAtStep(beat: 0, step: -2); // C4
      expect(c.notes.map((n) => n.pitch), ['C4', 'E4', 'G4']);
    });

    test('選択音符の音価変更後も選択が同じ音符を指し続ける', () {
      final c = fromEmpty();
      c.addNoteAtStep(beat: 0, step: 2); // G4
      c.addNoteAtStep(beat: 0, step: 0); // E4(選択。E4<G4 で index 0)
      expect(c.notes[c.selectedIndex!].pitch, 'E4');

      c.setDuration(2);
      expect(c.notes[c.selectedIndex!].pitch, 'E4');
      expect(c.notes[c.selectedIndex!].duration, 2);
    });

    test('選択音符の ♯ 付与後も選択が追従する', () {
      final c = fromEmpty();
      c.addNoteAtStep(beat: 0, step: 0); // E4
      c.addNoteAtStep(beat: 0, step: -2); // C4(選択。C4<E4 で index 0)
      expect(c.notes[c.selectedIndex!].pitch, 'C4');

      c.toggleSharp(); // C4 → C#4(midi 61、E4 64 の手前のまま)
      expect(c.notes[c.selectedIndex!].pitch, 'C#4');
    });
  });

  group('削除', () {
    test('選択中はその音符を削除し、選択を解除する', () {
      final c = fromTwoBeat();
      c.selectNote(0);
      c.deleteSelected();
      expect(c.notes.map((n) => n.pitch), ['E4']);
      expect(c.selectedIndex, isNull);
    });

    test('無選択なら末尾を削除する', () {
      final c = fromTwoBeat();
      c.deleteSelected();
      expect(c.notes.map((n) => n.pitch), ['C4']);
    });

    test('全消去でキャレットと選択がリセットされる', () {
      final c = fromTwoBeat();
      c.selectNote(1);
      c.clearAll();
      expect(c.noteCount, 0);
      expect(c.insertBeat, 0);
      expect(c.selectedIndex, isNull);
    });
  });

  group('曲名と currentPiece', () {
    test('空の曲名は無題の楽譜になる', () {
      final c = fromEmpty();
      c.setTitle('   ');
      expect(c.title, '無題の楽譜');
    });

    test('currentPiece は編集結果を反映し、他フィールドは保つ', () {
      final c = fromTwoBeat();
      c.setTitle('練習曲');
      c.addNoteFromKeyboard('G4');
      final piece = c.currentPiece;
      expect(piece.title, '練習曲');
      expect(piece.composer, 'テスト'); // twoBeatMelody の作曲者
      expect(piece.notes, hasLength(3));
    });
  });

  group('戻る / 進む(undo / redo)', () {
    test('追加 → undo で戻り、redo でやり直す', () {
      final c = fromEmpty();
      expect(c.canUndo, isFalse);
      c.addNoteFromKeyboard('C4');
      expect(c.noteCount, 1);
      expect(c.canUndo, isTrue);

      c.undo();
      expect(c.noteCount, 0);
      expect(c.canRedo, isTrue);

      c.redo();
      expect(c.noteCount, 1);
    });

    test('新しい編集をすると redo 履歴は消える', () {
      final c = fromEmpty();
      c.addNoteFromKeyboard('C4');
      c.undo();
      expect(c.canRedo, isTrue);
      c.addNoteFromKeyboard('E4');
      expect(c.canRedo, isFalse);
    });

    test('削除も undo で戻せる', () {
      final c = fromTwoBeat();
      c.deleteSelected(); // 末尾 E4 を削除
      expect(c.notes.map((n) => n.pitch), ['C4']);
      c.undo();
      expect(c.notes.map((n) => n.pitch), ['C4', 'E4']);
    });
  });

  group('末尾へ', () {
    test('moveCaretToEnd でキャレットが末尾・選択解除', () {
      final c = fromTwoBeat();
      c.selectNote(0); // キャレットは C4 直後(1 拍)
      c.moveCaretToEnd();
      expect(c.selectedIndex, isNull);
      expect(c.insertBeat, 2); // contentEnd
    });
  });

  group('初期版へ戻す(resetToOriginal)', () {
    test('収録曲は初期版に戻せる(旋律・曲名)', () {
      final original = twoBeatMelody();
      final c = EditorController(
        piece: original.copyWith(title: '編集後'),
        original: original,
      );
      expect(c.canReset, isTrue);
      c.clearAll();
      expect(c.noteCount, 0);

      c.resetToOriginal();
      expect(c.notes.map((n) => n.pitch), ['C4', 'E4']);
      expect(c.title, original.title);
      expect(c.canUndo, isTrue); // リセットも undo できる
    });

    test('original が無ければ canReset=false・何もしない', () {
      final c = fromEmpty();
      expect(c.canReset, isFalse);
      c.resetToOriginal();
      expect(c.noteCount, 0);
    });
  });

  test('変更で listener に通知する', () {
    final c = fromEmpty();
    var count = 0;
    c.addListener(() => count++);
    c.addNoteFromKeyboard('C4');
    c.setDuration(2);
    expect(count, greaterThanOrEqualTo(2));
  });
}
