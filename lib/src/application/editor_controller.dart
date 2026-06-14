import 'package:flutter/foundation.dart';

import '../domain/score/note.dart';
import '../domain/score/piece.dart';

/// 楽譜エディタの編集状態。音符の追加・選択・削除、音価/♯ ツール、曲名を扱う。
/// 旋律は常に `beat` 昇順に保たれる。pure な編集ロジックなので unit test で守る。
class EditorController extends ChangeNotifier {
  EditorController({required Piece piece})
    : _piece = piece,
      _title = piece.title,
      _notes = List<Note>.of(piece.notes) {
    _notes.sort((a, b) => a.beat.compareTo(b.beat));
    _insertBeat = contentEnd;
  }

  final Piece _piece;
  String _title;
  final List<Note> _notes;
  double _currentDuration = 1;
  bool _currentSharp = false;
  int? _selectedIndex;
  double _insertBeat = 0;

  String get title => _title;

  /// 編集中の旋律(beat 昇順)。
  List<Note> get notes => List.unmodifiable(_notes);
  int get noteCount => _notes.length;
  double get currentDuration => _currentDuration;
  bool get currentSharp => _currentSharp;

  /// 選択中の音符インデックス([notes] と同じ並び)。無選択なら null。
  int? get selectedIndex => _selectedIndex;

  /// 次の音符を挿入するキャレット位置(拍)。
  double get insertBeat => _insertBeat;

  /// 旋律の終端拍。
  double get contentEnd => Piece.contentEndOf(_notes);

  /// 編集結果を反映した曲(作曲者・難易度などは元の値を保つ)。
  Piece get currentPiece =>
      _piece.copyWith(title: _title, notes: List<Note>.of(_notes));

  void _sortAndSelect(Note note) {
    _notes.sort((a, b) => a.beat.compareTo(b.beat));
    _selectedIndex = _notes.indexOf(note);
  }

  /// 曲名を変更する。空 / 空白のみは「無題の楽譜」にする。
  void setTitle(String value) {
    _title = value.trim().isEmpty ? '無題の楽譜' : value;
    notifyListeners();
  }

  /// 音価ツールを変更する。選択中の音符があればその音価も変える。
  void setDuration(double duration) {
    _currentDuration = duration;
    final i = _selectedIndex;
    if (i != null) _notes[i] = _notes[i].copyWith(duration: duration);
    notifyListeners();
  }

  /// ♯ ツールをトグルする。選択中の音符が黒鍵を持つ音名ならその ♯ も切り替える。
  void toggleSharp() {
    _currentSharp = !_currentSharp;
    final i = _selectedIndex;
    if (i != null && _notes[i].isSharpable) {
      final hasSharp = _notes[i].pitch.contains('#');
      _notes[i] = _notes[i].copyWith(
        pitch: Note.withAccidental(_notes[i].pitch, sharp: !hasSharp),
      );
    }
    notifyListeners();
  }

  /// 鍵盤からの追加: キャレット位置にその音高を置き、キャレットを進める。
  void addNoteFromKeyboard(String pitch) {
    final note = Note(
      pitch: pitch,
      beat: _insertBeat,
      duration: _currentDuration,
    );
    _notes.add(note);
    _sortAndSelect(note);
    _insertBeat += _currentDuration;
    notifyListeners();
  }

  /// 譜面タップからの追加: スナップ済みの [beat] と五線位置 [step] から音高を作る。
  void addNoteAtStep({required double beat, required int step}) {
    final safeBeat = beat < 0 ? 0.0 : beat;
    final note = Note(
      pitch: Note.pitchForStep(step, sharp: _currentSharp),
      beat: safeBeat,
      duration: _currentDuration,
    );
    _notes.add(note);
    _sortAndSelect(note);
    _insertBeat = safeBeat + _currentDuration;
    notifyListeners();
  }

  /// 譜面上の音符を選択する。キャレットをその音符の直後へ移す。
  void selectNote(int index) {
    _selectedIndex = index;
    _insertBeat = _notes[index].beat + _notes[index].duration;
    notifyListeners();
  }

  /// 選択中の音符を削除。無選択なら末尾を削除する。
  void deleteSelected() {
    final i = _selectedIndex;
    if (i != null) {
      _notes.removeAt(i);
      _selectedIndex = null;
    } else if (_notes.isNotEmpty) {
      _notes.removeLast();
    }
    _insertBeat = contentEnd;
    notifyListeners();
  }

  /// すべて消去し、キャレットと選択をリセットする。
  void clearAll() {
    _notes.clear();
    _selectedIndex = null;
    _insertBeat = 0;
    notifyListeners();
  }
}
