import 'package:etude/src/domain/score/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note 音高パース', () {
    test('妥当な音名を受け付ける', () {
      expect(Note.isValidPitch('C4'), isTrue);
      expect(Note.isValidPitch('F#5'), isTrue);
      expect(Note.isValidPitch('B0'), isTrue);
    });

    test('不正な音名を弾く', () {
      expect(Note.isValidPitch('H4'), isFalse); // H は無い
      expect(Note.isValidPitch('Cb4'), isFalse); // フラットは扱わない
      expect(Note.isValidPitch('C'), isFalse); // オクターブ無し
      expect(Note.isValidPitch('C10'), isFalse); // 2 桁オクターブは対象外
    });
  });

  group('Note diatonicStep（E4 を 0 とする）', () {
    test('E4 が基準 0', () {
      expect(const Note(pitch: 'E4', beat: 0, duration: 1).diatonicStep, 0);
    });

    test('C4 は E4 の 2 段下', () {
      expect(const Note(pitch: 'C4', beat: 0, duration: 1).diatonicStep, -2);
    });

    test('C5 は 5、オクターブ上で +7', () {
      expect(const Note(pitch: 'C5', beat: 0, duration: 1).diatonicStep, 5);
      expect(const Note(pitch: 'C6', beat: 0, duration: 1).diatonicStep, 12);
    });

    test('不正な音名は FormatException', () {
      expect(
        () => const Note(pitch: 'bad', beat: 0, duration: 1).diatonicStep,
        throwsFormatException,
      );
    });
  });

  group('Note 妥当性と ♯ 可否', () {
    test('音価は許容値のみ妥当', () {
      expect(
        const Note(pitch: 'C4', beat: 0, duration: 1).hasValidDuration,
        isTrue,
      );
      expect(
        const Note(pitch: 'C4', beat: 0, duration: 0.5).hasValidDuration,
        isTrue,
      );
      expect(
        const Note(pitch: 'C4', beat: 0, duration: 1.5).hasValidDuration,
        isFalse,
      );
    });

    test('負の拍は非妥当', () {
      expect(const Note(pitch: 'C4', beat: -1, duration: 1).isValid, isFalse);
      expect(const Note(pitch: 'C4', beat: 0, duration: 1).isValid, isTrue);
    });

    test('黒鍵を持つ音名だけ ♯ 可', () {
      expect(const Note(pitch: 'C4', beat: 0, duration: 1).isSharpable, isTrue);
      expect(
        const Note(pitch: 'E4', beat: 0, duration: 1).isSharpable,
        isFalse,
      );
      expect(
        const Note(pitch: 'B4', beat: 0, duration: 1).isSharpable,
        isFalse,
      );
    });
  });

  group('Note 周波数', () {
    test('A4 は 440Hz、オクターブで 2 倍', () {
      expect(Note.frequencyOf('A4'), closeTo(440, 0.001));
      expect(Note.frequencyOf('A5'), closeTo(880, 0.001));
    });

    test('C4 は約 261.63Hz', () {
      expect(Note.frequencyOf('C4'), closeTo(261.626, 0.01));
    });

    test('midiOf: A4=69, C4=60, F#4=66', () {
      expect(Note.midiOf('A4'), 69);
      expect(Note.midiOf('C4'), 60);
      expect(Note.midiOf('F#4'), 66);
    });
  });

  group('Note.pitchForStep（step → 音名）', () {
    test('step 0 は E4、+7 で 1 オクターブ上', () {
      expect(Note.pitchForStep(0), 'E4');
      expect(Note.pitchForStep(7), 'E5');
      expect(Note.pitchForStep(-2), 'C4');
    });

    test('♯ は黒鍵を持つ音名にのみ付く', () {
      expect(Note.pitchForStep(-2, sharp: true), 'C#4'); // C は黒鍵あり
      expect(Note.pitchForStep(0, sharp: true), 'E4'); // E は黒鍵なし
    });

    test('生成した音名は妥当', () {
      for (var s = -9; s <= 17; s++) {
        expect(Note.isValidPitch(Note.pitchForStep(s)), isTrue, reason: '$s');
      }
    });
  });

  group('Note.solfege（音名 → ドレミ）', () {
    test('オクターブを除いた音階で返す', () {
      expect(Note.solfege('C4'), 'ド');
      expect(Note.solfege('A3'), 'ラ');
      expect(Note.solfege('G5'), 'ソ');
    });

    test('♯ は ♯ 付きで返す', () {
      expect(Note.solfege('F#4'), 'ファ♯');
      expect(Note.solfege('C#2'), 'ド♯');
    });
  });

  group('Note JSON 往復・同値', () {
    test('toJson/fromJson で復元できる', () {
      const note = Note(pitch: 'F#5', beat: 2.5, duration: 0.5);
      expect(Note.fromJson(note.toJson()), note);
    });

    test('値が同じなら等しい', () {
      expect(
        const Note(pitch: 'C4', beat: 1, duration: 1),
        const Note(pitch: 'C4', beat: 1, duration: 1),
      );
    });
  });
}
