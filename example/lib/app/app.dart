import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import 'home_page.dart';
import 'theme/app_theme.dart';

class MfmExampleApp extends StatelessWidget {
  const MfmExampleApp({super.key, this.config});

  final MfmRenderConfig? config;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'MFM Renderer Example',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
    );

    if (config == null) {
      return app;
    }
    return MfmConfig(
      config: config!,
      child: app,
    );
  }
}
