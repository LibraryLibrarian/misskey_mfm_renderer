import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fromResolver builds MfmCustomEmoji', () {
    final refreshNotifier = ValueNotifier(0);
    addTearDown(refreshNotifier.dispose);

    Future<EmojiImage?> resolver(String _) async => EmojiImage(
      url: Uri.parse('https://example.com/emoji.png'),
      animated: false,
      isSensitive: false,
    );

    final config = MfmEmojiConfig.fromResolver(
      resolver: resolver,
      emojiSize: 20,
      emojiMaxWidth: 60,
      emojiRefreshListenable: refreshNotifier,
    );

    expect(config.emojiBuilder, isNotNull);
    final widget = config.emojiBuilder!.call('test');
    expect(widget, isA<MfmCustomEmoji>());
    final custom = widget as MfmCustomEmoji;
    expect(custom.name, 'test');
    expect(custom.size, 20);
    expect(custom.maxWidth, 60);
    expect(custom.refreshListenable, same(refreshNotifier));
  });

  test('quickSetup returns config with emojiBuilder', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_quick');
    final store = _FakeEmojiStore();
    Uri? factoryServerUrl;
    String? factoryDirectory;
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final config = await MfmEmojiConfig.quickSetup(
      serverUrl: 'example.com',
      storagePath: dir.path,
      autoSync: false,
      emojiStoreFactory: ({required Uri serverUrl, required String directory}) {
        factoryServerUrl = serverUrl;
        factoryDirectory = directory;
        return store;
      },
    );
    addTearDown(config.dispose);

    expect(config, isA<MfmEmojiConfigHandle>());
    expect(config.emojiBuilder, isNotNull);
    expect(factoryServerUrl, Uri.parse('https://example.com'));
    expect(factoryDirectory, dir.path);

    await config.dispose();
    await config.dispose();

    expect(config.isDisposed, isTrue);
    expect(store.disposeCalls, 1);
  });

  test('copyWith preserves shared lifecycle ownership', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_copy');
    final store = _FakeEmojiStore();
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final config = await MfmEmojiConfig.createDefault(
      serverUrl: Uri.parse('https://example.com'),
      storagePath: dir.path,
      autoSync: false,
      emojiStoreFactory:
          ({required Uri serverUrl, required String directory}) => store,
    );
    addTearDown(config.dispose);

    final copied = config.copyWith(enableAnimation: false);

    expect(copied, isA<MfmEmojiConfigHandle>());
    expect(copied.enableAnimation, isFalse);
    expect(config.enableAnimation, isTrue);

    await copied.dispose();
    await config.dispose();

    expect(copied.isDisposed, isTrue);
    expect(config.isDisposed, isTrue);
    expect(store.disposeCalls, 1);
  });

  test('createDefault returns config with emojiBuilder', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_default');
    final store = _FakeEmojiStore();
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final config = await MfmEmojiConfig.createDefault(
      serverUrl: Uri.parse('https://example.com'),
      storagePath: dir.path,
      autoSync: false,
      emojiStoreFactory:
          ({required Uri serverUrl, required String directory}) => store,
    );
    addTearDown(config.dispose);

    expect(config, isA<MfmEmojiConfigHandle>());
    expect(config.emojiBuilder, isNotNull);

    await config.dispose();

    expect(store.disposeCalls, 1);
  });
}

class _FakeEmojiStore implements EmojiStore {
  int disposeCalls = 0;

  @override
  Future<List<EmojiRecord>> loadAll() async => [];

  @override
  Future<void> saveAll(List<EmojiRecord> all) async {}

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}
