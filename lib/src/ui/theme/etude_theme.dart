import 'package:flutter/material.dart';

/// デザイントークン。プロトタイプ `docs/prototype/etude-piano-app.html` の
/// `:root` 定義に対応する。基調はダーク(夜想曲モチーフ)。
abstract final class EtudeColors {
  static const ink = Color(0xFF141019);
  static const ink2 = Color(0xFF1D1726);
  static const ink3 = Color(0xFF28202F);
  static const inkLine = Color(0xFF352B40);

  static const ivory = Color(0xFFF2EAD9);
  static const ivory2 = Color(0xB8F2EAD9); // 約 72% 不透明
  static const ivory3 = Color(0x75F2EAD9); // 約 46% 不透明

  static const brass = Color(0xFFD6A94C);
  static const brassSoft = Color(0xFFECCA84);
  static const rose = Color(0xFFB67C86);
}

/// アプリ全体のテーマ。見出しは明朝(Shippori Mincho)、本文はゴシック
/// (Zen Kaku Gothic New)、数字・ラベルは等幅(IBM Plex Mono)を既定にする。
abstract final class EtudeTheme {
  static const _serif = 'ShipporiMincho';
  static const _sans = 'ZenKakuGothicNew';
  static const mono = 'IBMPlexMono';

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: EtudeColors.brass,
          brightness: Brightness.dark,
        ).copyWith(
          surface: EtudeColors.ink,
          primary: EtudeColors.brass,
          secondary: EtudeColors.rose,
          onSurface: EtudeColors.ivory,
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: EtudeColors.ink,
      canvasColor: EtudeColors.ink,
      textTheme: base.textTheme
          .apply(
            bodyColor: EtudeColors.ivory,
            displayColor: EtudeColors.ivory,
            fontFamily: _sans,
          )
          .copyWith(
            displaySmall: const TextStyle(fontFamily: _serif),
            headlineMedium: const TextStyle(fontFamily: _serif),
            headlineSmall: const TextStyle(fontFamily: _serif),
            titleLarge: const TextStyle(fontFamily: _serif),
          ),
    );
  }
}
