import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import 'app/app.dart';
import 'core/emoji/emoji_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MfmRenderConfig? config;
  try {
    config = await EmojiService.instance.initialize();
  } on Exception catch (e) {
    // Allow app start even if emoji init fails.
    debugPrint('EmojiService initialization failed: $e');
  }

  runApp(MfmExampleApp(config: config));
}
