import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/library/library_store.dart';
import '../domain/score/piece.dart';

/// `LibraryStore` の永続化実装(ADR 0001: shared_preferences + 単一 JSON キー)。
class PrefsLibraryStore implements LibraryStore {
  /// テストでは初期化済みの [SharedPreferences] を渡せる。未指定なら遅延取得する。
  PrefsLibraryStore({SharedPreferences? prefs})
    : _prefs = prefs; // ignore: prefer_initializing_formals

  /// スキーマバージョン付きキー。スキーマ変更時は新キーを切り、旧キーから移行する。
  static const String storageKey = 'library_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<List<Piece>?> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    // 全体が壊れた JSON・形が違う場合は null(初回起動扱い)。アプリは必ず起動できる。
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map || decoded['pieces'] is! List) return null;

    // 1 件壊れていても残りは活かす(部分破損で全データを失わない)。
    final pieces = <Piece>[];
    for (final entry in decoded['pieces'] as List) {
      try {
        pieces.add(Piece.fromJson((entry as Map).cast<String, Object?>()));
      } catch (_) {
        // 壊れた 1 件はスキップ。
      }
    }
    return pieces;
  }

  @override
  Future<void> save(List<Piece> pieces) async {
    final prefs = await _instance;
    final raw = jsonEncode({'pieces': pieces.map((p) => p.toJson()).toList()});
    await prefs.setString(storageKey, raw);
  }
}
