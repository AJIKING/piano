import 'package:flutter/foundation.dart';

import '../domain/score/note.dart';
import '../domain/score/piece.dart';

/// 戻る/進む用の状態スナップショット(曲名＋音符)。
typedef _Snapshot = ({String title, List<Note> notes});

/// 楽譜エディタの編集状態。音符の追加・選択・削除、音価/♯ ツール、曲名、
/// 戻る/進む(undo/redo)、初期楽譜へのリセットを扱う。
/// 旋律は常に `beat` 昇順に保たれる。pure な編集ロジックなので unit test で守る。
class EditorController extends ChangeNotifier {
  EditorController({required Piece piece, this._original})
    : _piece = piece,
      _title = piece.title,
      _notes = List<Note>.of(piece.notes) {
    _notes.sort(Piece.compareNotes);
    _insertBeat = contentEnd;
  }

  final Piece _piece;

  /// 収録曲の初期版(あれば「元に戻す」可能)。ユーザー作成曲では null。
  final Piece? _original;

  String _title;
  final List<Note> _notes;
  double _currentDuration = 1;
  bool _currentSharp = false;
  int? _selectedIndex;
  double _insertBeat = 0;

  // 戻る/進む用のスナップショット(曲名＋音符)。
  static const int _historyLimit = 50;
  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];

  String get title => _title;

  /// 編集中の旋律(beat 昇順)。
  List<Note> get notes => List.unmodifiable(_notes);
  int get noteCount => _notes.length;
  double get currentDuration => _currentDuration;
  bool get currentSharp => _currentSharp;
  int? get selectedIndex => _selectedIndex;
  double get insertBeat => _insertBeat;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// 初期版へ戻せるか(収録曲のみ)。
  bool get canReset => _original != null;

  /// 旋律の終端拍。
  double get contentEnd => Piece.contentEndOf(_notes);

  /// 編集結果を反映した曲(作曲者・拍子・既定テンポなどは元の値を保つ)。
  Piece get currentPiece =>
      _piece.copyWith(title: _title, notes: List<Note>.of(_notes));

  // ---- 内部ヘルパ ----

  _Snapshot _snapshot() => (title: _title, notes: List<Note>.of(_notes));

  /// 状態を変更する操作の前に呼び、現在の状態を undo へ積む。
  void _pushUndo() {
    _undo.add(_snapshot());
    if (_undo.length > _historyLimit) _undo.removeAt(0);
    _redo.clear();
  }

  /// スナップショットを適用する(曲名・音符を復元し、選択/キャレットをリセット)。
  void _apply(_Snapshot snapshot) {
    _title = snapshot.title;
    _notes
      ..clear()
      ..addAll(snapshot.notes)
      ..sort(Piece.compareNotes);
    _selectedIndex = null;
    _insertBeat = contentEnd;
  }

  /// 正準順に整列し直し、[note] を選択状態として再特定する。
  void _sortAndSelect(Note note) {
    _notes.sort(Piece.compareNotes);
    _selectedIndex = _notes.indexOf(note);
  }

  // ---- 操作 ----

  /// 曲名を変更する。空 / 空白のみは「無題の楽譜」にする。
  void setTitle(String value) {
    _title = value.trim().isEmpty ? '無題の楽譜' : value;
    notifyListeners();
  }

  /// 音価ツールを変更する。選択中の音符があればその音価も変える。
  void setDuration(double duration) {
    _currentDuration = duration;
    final i = _selectedIndex;
    if (i != null) {
      _pushUndo();
      final updated = _notes[i].copyWith(duration: duration);
      _notes[i] = updated;
      _sortAndSelect(updated);
    }
    notifyListeners();
  }

  /// ♯ ツールをトグルする。選択中の音符が黒鍵を持つ音名ならその ♯ も切り替える。
  void toggleSharp() {
    _currentSharp = !_currentSharp;
    final i = _selectedIndex;
    if (i != null && _notes[i].isSharpable) {
      _pushUndo();
      final hasSharp = _notes[i].pitch.contains('#');
      final updated = _notes[i].copyWith(
        pitch: Note.withAccidental(_notes[i].pitch, sharp: !hasSharp),
      );
      _notes[i] = updated;
      _sortAndSelect(updated);
    }
    notifyListeners();
  }

  /// 鍵盤からの追加: キャレット位置にその音高を置き、キャレットを進める。
  void addNoteFromKeyboard(String pitch) {
    _pushUndo();
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
    _pushUndo();
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

  /// 選択を解除し、キャレットを末尾へ移す(末尾に追加しやすくする)。
  void moveCaretToEnd() {
    _selectedIndex = null;
    _insertBeat = contentEnd;
    notifyListeners();
  }

  /// 選択中の音符を削除。無選択なら末尾を削除する。
  void deleteSelected() {
    if (_selectedIndex == null && _notes.isEmpty) return;
    _pushUndo();
    final i = _selectedIndex;
    if (i != null) {
      _notes.removeAt(i);
      _selectedIndex = null;
    } else {
      _notes.removeLast();
    }
    _insertBeat = contentEnd;
    notifyListeners();
  }

  /// すべて消去する。
  void clearAll() {
    if (_notes.isEmpty) return;
    _pushUndo();
    _notes.clear();
    _selectedIndex = null;
    _insertBeat = 0;
    notifyListeners();
  }

  /// 収録曲の初期版へ戻す(曲名・旋律を元に戻す)。ユーザー作成曲では何もしない。
  void resetToOriginal() {
    final original = _original;
    if (original == null) return;
    _pushUndo();
    _apply((title: original.title, notes: List<Note>.of(original.notes)));
    notifyListeners();
  }

  /// 直前の変更を取り消す(曲名・音符)。
  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_snapshot());
    _apply(_undo.removeLast());
    notifyListeners();
  }

  /// 取り消した変更をやり直す。
  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_snapshot());
    _apply(_redo.removeLast());
    notifyListeners();
  }
}
