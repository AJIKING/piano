import 'package:etude/src/domain/library/library_store.dart';
import 'package:etude/src/domain/score/piece.dart';

/// プロセス内にのみ保持するインメモリ `LibraryStore`。保存内容の検証に使う。
class InMemoryLibraryStore implements LibraryStore {
  InMemoryLibraryStore([this._saved]);

  List<Piece>? _saved;

  /// 保存回数(永続化が呼ばれたかの検証用)。
  int saveCount = 0;

  /// 最後に保存されたコレクション(null なら未保存)。
  List<Piece>? get saved => _saved;

  @override
  Future<List<Piece>?> load() async => _saved;

  @override
  Future<void> save(List<Piece> pieces) async {
    _saved = List.of(pieces);
    saveCount++;
  }
}
