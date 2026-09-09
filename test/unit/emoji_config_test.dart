import 'dart:io';

import 'package:flutter/widgets.dart';
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
    final widget = config.emojiBuilder!.call(
      'test',
      const MfmEmojiContext(fontSize: 14, scale: 1),
    );
    expect(widget, isA<MfmCustomEmoji>());
    final custom = widget as MfmCustomEmoji;
    expect(custom.name, 'test');
    expect(custom.size, 20);
    // vertical-align: middle相当（20 / 2 - 14 * 0.25）
    expect(custom.baselineOffset, 6.5);
    expect(custom.maxWidth, 60);
    expect(custom.cacheScope, same(resolver));
    expect(custom.refreshListenable, same(refreshNotifier));
  });

  for (final fontSize in [14.0, 28.0, 84.0, 21.0, 11.2]) {
    for (final fixedSize in [null, 24.0]) {
      test('fromResolver uses 2em or fixed size: $fontSize / $fixedSize', () {
        final config = MfmEmojiConfig.fromResolver(
          resolver: (_) async => null,
          emojiSize: fixedSize,
        );
        final custom =
            config.emojiBuilder!(
                  'emoji',
                  MfmEmojiContext(fontSize: fontSize, scale: 1),
                )
                as MfmCustomEmoji;
        final size = fixedSize ?? fontSize * 2;
        expect(custom.size, size);
        expect(custom.baselineOffset, size / 2 - fontSize * 0.25);
      });
    }
  }

  test('fromResolver keeps middle alignment for a fixed emojiSize', () {
    final config = MfmEmojiConfig.fromResolver(
      resolver: (_) async => null,
      emojiSize: 24,
    );
    final custom =
        config.emojiBuilder!(
              'emoji',
              const MfmEmojiContext(fontSize: 14, scale: 1),
            )
            as MfmCustomEmoji;
    expect(custom.size, 24);
    // 24 / 2 - 14 * 0.25 = 8.5
    expect(custom.baselineOffset, 8.5);
  });

  test('fromResolver uses normal 1.25em size and -0.25em baseline', () {
    final config = MfmEmojiConfig.fromResolver(resolver: (_) async => null);
    final custom =
        config.emojiBuilder!(
              'emoji',
              const MfmEmojiContext(fontSize: 14, scale: 1, normal: true),
            )
            as MfmCustomEmoji;
    expect(custom.size, 17.5);
    // normal class has vertical-align: -0.25em, so its descent is 14 * 0.25.
    expect(custom.baselineOffset, 3.5);
  });

  test('normal baseline policy is retained for an explicit emojiSize', () {
    final config = MfmEmojiConfig.fromResolver(
      resolver: (_) async => null,
      emojiSize: 24,
    );
    final custom =
        config.emojiBuilder!(
              'emoji',
              const MfmEmojiContext(fontSize: 14, scale: 1, normal: true),
            )
            as MfmCustomEmoji;
    expect(custom.size, 24);
    expect(custom.baselineOffset, 3.5);
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
    for (final fontSize in [14.0, 28.0, 84.0]) {
      final emoji =
          config.emojiBuilder!(
                'emoji',
                MfmEmojiContext(fontSize: fontSize, scale: 1),
              )
              as MfmCustomEmoji;
      expect(emoji.size, fontSize * 2);
      expect(emoji.baselineOffset, fontSize * 0.75);
    }

    await config.dispose();
    await config.dispose();

    expect(config.isDisposed, isTrue);
    expect(store.disposeCalls, 1);
  });

  test('ハンドルのcopyWithがコードコピー設定を保持し上書きできる', () async {
    final dir = await Directory.systemTemp.createTemp('mfm_emoji_code_copy');
    addTearDown(() => dir.delete(recursive: true));
    final store = _FakeEmojiStore();
    final config = await MfmEmojiConfig.createDefault(
      client: _createClient(),
      storagePath: dir.path,
      autoSync: false,
      emojiStoreFactory:
          ({required Uri serverUrl, required String directory}) => store,
    );
    addTearDown(config.dispose);
    void onCopied(String _) {}
    void onCopiedOverride(String _) {}

    final copied = config.copyWith(
      onCodeCopied: onCopied,
      codeCopyTooltip: 'Copy source',
      codeCopiedMessage: 'Source copied',
    );
    final preserved = copied.copyWith(enableAnimation: false);
    for (final value in [copied, preserved]) {
      expect(value, isA<MfmEmojiConfigHandle>());
      expect(value.onCodeCopied, same(onCopied));
      expect(value.codeCopyTooltip, 'Copy source');
      expect(value.codeCopiedMessage, 'Source copied');
    }
    final overridden = copied.copyWith(
      onCodeCopied: onCopiedOverride,
      codeCopyTooltip: '別のツールチップ',
      codeCopiedMessage: '別のメッセージ',
    );
    expect(overridden.onCodeCopied, same(onCopiedOverride));
    expect(overridden.codeCopyTooltip, '別のツールチップ');
    expect(overridden.codeCopiedMessage, '別のメッセージ');
    expect(config.onCodeCopied, isNull);
    expect(config.codeCopyTooltip, isNull);
    expect(config.codeCopiedMessage, isNull);
  });

  test(
    'handle copyWith preserves and overrides nyaizeMode and hashtag details',
    () async {
      final dir = await Directory.systemTemp.createTemp('mfm_emoji_props');
      addTearDown(() => dir.delete(recursive: true));
      final config = await MfmEmojiConfig.createDefault(
        client: _createClient(),
        storagePath: dir.path,
        autoSync: false,
        emojiStoreFactory:
            ({required Uri serverUrl, required String directory}) =>
                _FakeEmojiStore(),
      );
      addTearDown(config.dispose);
      void details(MfmHashtagTapDetails _) {}
      final copied = config.copyWith(
        nyaizeMode: MfmNyaizeMode.respectAuthor,
        onHashtagTapDetails: details,
      );
      final preserved = copied.copyWith(enableAnimation: false);
      expect(preserved.nyaizeMode, MfmNyaizeMode.respectAuthor);
      expect(preserved.onHashtagTapDetails, same(details));
    },
  );

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
    const lightScheme = MfmColorScheme.light();
    const darkScheme = MfmColorScheme.dark();
    final copied = config.copyWith(
      enableAnimation: false,
      author: author,
      localHost: 'local.example',
      searchButtonLabel: 'Find',
      lightColorScheme: lightScheme,
      darkColorScheme: darkScheme,
    );

    expect(copied, isA<MfmEmojiConfigHandle>());
    expect(copied.enableAnimation, isFalse);
    expect(copied.emojiBuilder, same(config.emojiBuilder));
    expect(identical(copied.author, author), isTrue);
    expect(copied.localHost, 'local.example');
    expect(copied.searchButtonLabel, 'Find');
    expect(copied.lightColorScheme, lightScheme);
    expect(copied.darkColorScheme, darkScheme);
    expect(config.enableAnimation, isTrue);
    expect(config.searchButtonLabel, isNull);
    expect(config.lightColorScheme, isNull);
    expect(config.darkColorScheme, isNull);

    final replaced = copied.copyWith(
      emojiBuilder: (name, context) => copied.emojiBuilder!(name, context),
      unicodeEmojiBuilder: (emoji, context) =>
          copied.emojiBuilder!(emoji, context),
    );
    for (final builder in [
      replaced.emojiBuilder!,
      replaced.unicodeEmojiBuilder!,
    ]) {
      final emoji =
          builder('emoji', const MfmEmojiContext(fontSize: 28, scale: 2))
              as MfmCustomEmoji;
      expect(emoji.size, 56);
      // 56 / 2 - 28 * 0.25 = 21
      expect(emoji.baselineOffset, 21);
    }

    final preserved = copied.copyWith(enableNyaize: true);
    expect(identical(preserved.author, author), isTrue);
    expect(preserved.localHost, 'local.example');
    expect(preserved.lightColorScheme, lightScheme);
    expect(preserved.darkColorScheme, darkScheme);

    final recolored = copied.copyWith(
      lightColorScheme: darkScheme,
      darkColorScheme: lightScheme,
    );
    expect(recolored.lightColorScheme, darkScheme);
    expect(recolored.darkColorScheme, lightScheme);

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
      () =>
          preserved.copyWith(localHost: 'other.example', clearLocalHost: true),
      throwsArgumentError,
    );

    final cleared = preserved.copyWith(clearAuthor: true, clearLocalHost: true);
    expect(cleared, isA<MfmEmojiConfigHandle>());
    expect(cleared.author, isNull);
    expect(cleared.localHost, isNull);

    final localized = copied.copyWith(
      searchButtonLabel: 'Ignored',
      useLocaleSearchButtonLabel: true,
    );
    expect(localized, isA<MfmEmojiConfigHandle>());
    expect(identical(localized.author, author), isTrue);
    expect(localized.localHost, 'local.example');
    expect(localized.searchButtonLabel, isNull);
    expect(localized.useLocaleSearchButtonLabel, isTrue);

    await localized.dispose();
    await config.dispose();

    expect(localized.isDisposed, isTrue);
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

  test(
    'createDefault resolves remote emoji without a direct URL via its origin',
    () async {
      final dir = await Directory.systemTemp.createTemp('mfm_emoji_remote');
      addTearDown(() => dir.delete(recursive: true));
      final config = await MfmEmojiConfig.createDefault(
        client: _createClient(),
        storagePath: dir.path,
        autoSync: false,
        emojiStoreFactory:
            ({required Uri serverUrl, required String directory}) =>
                _FakeEmojiStore(),
      );
      addTearDown(config.dispose);

      final custom =
          config.emojiBuilder!(
                'wave',
                const MfmEmojiContext(
                  fontSize: 14,
                  scale: 1,
                  host: 'remote.example',
                ),
              )
              as MfmCustomEmoji;

      expect(
        custom.url,
        Uri.parse('https://example.com/emoji/wave@remote.example.webp'),
      );
      expect(custom.resolver, isNull);
    },
  );

  test('fromResolver uses serverBaseUrl for a remote endpoint', () {
    var resolveCount = 0;
    final config = MfmEmojiConfig.fromResolver(
      resolver: (_) async {
        resolveCount++;
        return null;
      },
      serverBaseUrl: Uri.parse('http://localhost:3000/misskey/'),
    );

    final custom =
        config.emojiBuilder!(
              'wave',
              const MfmEmojiContext(
                fontSize: 14,
                scale: 1,
                host: 'remote.example',
              ),
            )
            as MfmCustomEmoji;

    expect(
      custom.url,
      Uri.parse('http://localhost:3000/emoji/wave@remote.example.webp'),
    );
    expect(custom.resolver, isNull);
    expect(resolveCount, 0);
  });

  test(
    'fromResolver does not use the local resolver for remote emoji without URL',
    () {
      var resolveCount = 0;
      final config = MfmEmojiConfig.fromResolver(
        resolver: (_) async {
          resolveCount++;
          return null;
        },
      );

      final widget = config.emojiBuilder!(
        'wave',
        const MfmEmojiContext(
          fontSize: 14,
          scale: 1,
          host: 'remote.example',
        ),
      );

      expect(widget, isA<Text>());
      expect((widget as Text).data, ':wave:');
      expect(resolveCount, 0);
    },
  );
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
