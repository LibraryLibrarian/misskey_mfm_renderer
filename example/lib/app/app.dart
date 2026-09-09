import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../core/callbacks/example_callbacks.dart';
import '../core/settings/example_settings.dart';
import 'home_page.dart';
import 'theme/app_theme.dart';

class MfmExampleApp extends StatefulWidget {
  const MfmExampleApp({super.key, this.config});

  final MfmRenderConfig? config;

  @override
  State<MfmExampleApp> createState() => _MfmExampleAppState();
}

class _MfmExampleAppState extends State<MfmExampleApp> {
  final _settings = ExampleSettings();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final ExampleCallbacks _callbacks;
  late MfmRenderConfig _baseConfig;
  late MfmRenderConfig _renderConfig;

  @override
  void initState() {
    super.initState();
    _callbacks = ExampleCallbacks(_scaffoldMessengerKey);
    _baseConfig = widget.config ?? const MfmRenderConfig();
    _renderConfig = buildRenderConfig(_settings, _baseConfig, _callbacks);
    _settings.addListener(_updateRenderConfig);
  }

  @override
  void didUpdateWidget(covariant MfmExampleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _baseConfig = widget.config ?? const MfmRenderConfig();
      _renderConfig = buildRenderConfig(_settings, _baseConfig, _callbacks);
    }
  }

  @override
  void dispose() {
    _settings
      ..removeListener(_updateRenderConfig)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExampleSettingsScope(
      settings: _settings,
      child: MfmConfig(
        config: _renderConfig,
        child: MaterialApp(
          title: 'MFM Renderer Example',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _settings.themeMode,
          scaffoldMessengerKey: _scaffoldMessengerKey,
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
        ),
      ),
    );
  }

  void _updateRenderConfig() {
    setState(() {
      _renderConfig = buildRenderConfig(_settings, _baseConfig, _callbacks);
    });
  }
}
