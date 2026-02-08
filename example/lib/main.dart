import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/emoji/emoji_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await EmojiService.instance.initialize();
  } on Exception catch (e) {
    // Allow app start even if emoji init fails.
    debugPrint('EmojiService initialization failed: $e');
  }

  runApp(const MfmExampleApp());
}
