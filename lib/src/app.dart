import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'application/dependencies.dart';
import 'ui/app_shell.dart';
import 'ui/theme/etude_theme.dart';

/// アプリのルート。差し替え境界([Dependencies])を受け取り、テーマと骨格
/// ([AppShell])を組み立てる。画面横断の状態は [AppShell] が所有する。
class EtudeApp extends StatelessWidget {
  const EtudeApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: EtudeTheme.dark(),
      // 端末のロケールに自動追従(日本語 / 英語 / 簡体字中国語)。
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(dependencies: dependencies),
    );
  }
}
