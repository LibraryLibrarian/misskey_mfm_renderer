import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fromResolver builds MfmCustomEmoji', () {
    Future<EmojiImage?> resolver(String _) async => EmojiImage(
      url: Uri.parse('https://example.com/emoji.png'),
      animated: false,
      isSensitive: false,
    );

    final config = MfmEmojiConfig.fromResolver(
      resolver: resolver,
      emojiSize: 20,
    );

    expect(config.emojiBuilder, isNotNull);
    final widget = config.emojiBuilder!.call('test');
    expect(widget, isA<MfmCustomEmoji>());
    final custom = widget as MfmCustomEmoji;
    expect(custom.name, 'test');
    expect(custom.size, 20);
  });

  test('quickSetup returns config with emojiBuilder', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_quick');
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final config = await MfmEmojiConfig.quickSetup(
      serverUrl: 'https://example.com',
      storagePath: dir.path,
      autoSync: false,
    );

    expect(config.emojiBuilder, isNotNull);
  });

  test('createDefault returns config with emojiBuilder', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_default');
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final config = await MfmEmojiConfig.createDefault(
      serverUrl: Uri.parse('https://example.com'),
      storagePath: dir.path,
      autoSync: false,
    );

    expect(config.emojiBuilder, isNotNull);
  });
}
