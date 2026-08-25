import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_client/misskey_client.dart';
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
    expect(custom.cacheScope, same(resolver));
    expect(custom.refreshListenable, same(refreshNotifier));
  });

  test('createDefault derives the store scope from client.baseUrl', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_quick');
    final store = _FakeEmojiStore();
    Uri? factoryServerUrl;
    String? factoryDirectory;
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final config = await MfmEmojiConfig.createDefault(
      client: _createClient(),
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
      client: _createClient(),
      storagePath: dir.path,
      autoSync: false,
      emojiStoreFactory:
          ({required Uri serverUrl, required String directory}) => store,
    );
    addTearDown(config.dispose);

    const author = MfmAuthorContext(host: 'remote.example');
    final copied = config.copyWith(
      enableAnimation: false,
      author: author,
      localHost: 'local.example',
      searchButtonLabel: 'Find',
    );

    expect(copied, isA<MfmEmojiConfigHandle>());
    expect(copied.enableAnimation, isFalse);
    expect(identical(copied.author, author), isTrue);
    expect(copied.localHost, 'local.example');
    expect(copied.searchButtonLabel, 'Find');
    expect(config.enableAnimation, isTrue);
    expect(config.searchButtonLabel, isNull);

    final preserved = copied.copyWith(enableNyaize: true);
    expect(identical(preserved.author, author), isTrue);
    expect(preserved.localHost, 'local.example');

    final preservedWithNull = preserved.copyWith(
      // ignore: avoid_redundant_argument_values
      author: null,
      // ignore: avoid_redundant_argument_values
      localHost: null,
    );
    expect(identical(preservedWithNull.author, author), isTrue);
    expect(preservedWithNull.localHost, 'local.example');

    expect(
      () => preserved.copyWith(author: author, clearAuthor: true),
      throwsArgumentError,
    );
    expect(
      () => preserved.copyWith(
        localHost: 'other.example',
        clearLocalHost: true,
      ),
      throwsArgumentError,
    );

    final cleared = preserved.copyWith(
      clearAuthor: true,
      clearLocalHost: true,
    );
    expect(cleared, isA<MfmEmojiConfigHandle>());
    expect(cleared.author, isNull);
    expect(cleared.localHost, isNull);

    await cleared.dispose();
    await config.dispose();

    expect(cleared.isDisposed, isTrue);
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
      client: _createClient(),
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

MisskeyClient _createClient() => MisskeyClient(
  config: MisskeyClientConfig(baseUrl: Uri.parse('https://example.com')),
);

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
