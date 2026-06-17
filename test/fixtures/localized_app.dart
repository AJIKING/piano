import 'package:etude/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// テスト用に [AppLocalizations] を提供する `MaterialApp`。
///
/// ロケールは既定で日本語に固定する(テスト環境の既定ロケール=en に流されず、
/// 既存の日本語マッチャがそのまま使えるようにするため)。多言語の検証では
/// [locale] を切り替える。
MaterialApp localizedApp({
  required Widget home,
  Locale locale = const Locale('ja'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
