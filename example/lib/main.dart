import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/emoji/emoji_service.dart';
import 'core/emoji/example_startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startup = await resolveExampleStartup(
    offline: const bool.fromEnvironment('MFM_EXAMPLE_OFFLINE'),
    online: EmojiService.instance.initialize,
  );
  if (startup.error != null) {
    debugPrint('EmojiService initialization failed: ${startup.error}');
  }

  runApp(MfmExampleApp(config: startup.config, emojiStatus: startup.status));
}
