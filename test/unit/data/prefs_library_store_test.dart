import 'dart:convert';

import 'package:etude/src/data/prefs_library_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/fixture_pieces.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('未保存は null(初回起動)', () async {
    expect(await PrefsLibraryStore().load(), isNull);
  });

  test('save → load で往復できる', () async {
    await PrefsLibraryStore().save([twoBeatMelody()]);

    final loaded = await PrefsLibraryStore().load();
    expect(loaded, isNotNull);
    expect(loaded!.single.id, 'fixture-two-beat');
    expect(loaded.single.notes, hasLength(2));
  });

  test('壊れた JSON は null(初回起動扱い)', () async {
    SharedPreferences.setMockInitialValues({
      PrefsLibraryStore.storageKey: 'not json',
    });
    expect(await PrefsLibraryStore().load(), isNull);
  });

  test('pieces キー欠落は null', () async {
    SharedPreferences.setMockInitialValues({
      PrefsLibraryStore.storageKey: '{"foo": 1}',
    });
    expect(await PrefsLibraryStore().load(), isNull);
  });

  test('一部の曲が壊れていても残りは復元する(全消失しない)', () async {
    final raw = jsonEncode({
      'pieces': [
        twoBeatMelody().toJson(),
        {'bad': true}, // id/title 等が無く fromJson が throw する
      ],
    });
    SharedPreferences.setMockInitialValues({PrefsLibraryStore.storageKey: raw});

    final loaded = await PrefsLibraryStore().load();
    expect(loaded, hasLength(1));
    expect(loaded!.single.id, 'fixture-two-beat');
  });
}
