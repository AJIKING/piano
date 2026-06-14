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
    // 壊れた JSON・型不一致は例外にせず null(初回起動扱い)。アプリは必ず起動できる。
    try {
      final decoded = jsonDecode(raw);
      final list = (decoded as Map)['pieces'] as List<Object?>;
      return list
          .map((e) => Piece.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(List<Piece> pieces) async {
    final prefs = await _instance;
    final raw = jsonEncode({'pieces': pieces.map((p) => p.toJson()).toList()});
    await prefs.setString(storageKey, raw);
  }
}
