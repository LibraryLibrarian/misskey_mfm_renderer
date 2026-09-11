import 'package:example/core/callbacks/example_callbacks.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  final callbacks = ExampleCallbacks(GlobalKey<ScaffoldMessengerState>());

  test('設定を MfmRenderConfig へ写像する', () {
    final settings = ExampleSettings()
      ..enableAdvancedMfm = false
      ..enableAnimation = false
      ..nyaizeMode = MfmNyaizeMode.respectAuthor
      ..authorIsCat = true
      ..remoteAuthor = true
      ..useEmojiUrls = true
      ..useCustomColorScheme = true
      ..showCodeBlockCopyButton = false;

    final config = buildRenderConfig(
      settings,
      const MfmRenderConfig(),
      callbacks,
    );

    expect(config.enableAdvancedMfm, isFalse);
    expect(config.enableAnimation, isFalse);
    expect(config.nyaizeMode, MfmNyaizeMode.respectAuthor);
    expect(
      config.author,
      const MfmAuthorContext(host: 'misskey.example', isCat: true),
    );
    expect(
      config.emojiUrls,
      {
        'ai_smile_misskeyio':
            'https://misskey.io/emoji/ai_smile_misskeyio.webp',
        'pudding_cat': 'https://misskey.io/emoji/pudding_cat.webp',
      },
    );
    expect(config.lightColorScheme?.accent, const Color(0xFF7C3AED));
    expect(config.darkColorScheme?.accent, const Color(0xFFC4B5FD));
    expect(config.showCodeBlockCopyButton, isFalse);
  });

  test('emojiUrls は解除し、ローカル投稿の author を保持する', () {
    final settings = ExampleSettings()..authorIsCat = true;
    final config = buildRenderConfig(
      settings,
      const MfmRenderConfig(emojiUrls: {'old': 'https://example.org/old.webp'}),
      callbacks,
    );

    expect(config.emojiUrls, isNull);
    expect(config.author, const MfmAuthorContext(isCat: true));
  });

  test('reset は既定値へ戻す', () {
    final settings = ExampleSettings()
      ..themeMode = ThemeMode.dark
      ..useCustomColorScheme = true
      ..enableAdvancedMfm = false
      ..enableAnimation = false
      ..nyaizeMode = MfmNyaizeMode.enabled
      ..authorIsCat = true
      ..remoteAuthor = true
      ..useEmojiUrls = true
      ..showEmojiContext = true
      ..plain = true
      ..nowrap = true
      ..rootScale = 3
      ..isNote = false
      ..showCodeBlockCopyButton = false
      ..reset();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.useCustomColorScheme, isFalse);
    expect(settings.enableAdvancedMfm, isTrue);
    expect(settings.enableAnimation, isTrue);
    expect(settings.nyaizeMode, MfmNyaizeMode.disabled);
    expect(settings.authorIsCat, isFalse);
    expect(settings.remoteAuthor, isFalse);
    expect(settings.useEmojiUrls, isFalse);
    expect(settings.showEmojiContext, isFalse);
    expect(settings.plain, isFalse);
    expect(settings.nowrap, isFalse);
    expect(settings.rootScale, 1);
    expect(settings.isNote, isTrue);
    expect(settings.showCodeBlockCopyButton, isTrue);
  });

  test('絵文字ビルダーがない base では文脈表示が無害', () {
    final settings = ExampleSettings()..showEmojiContext = true;
    final config = buildRenderConfig(
      settings,
      const MfmRenderConfig(),
      callbacks,
    );

    expect(config.emojiBuilder, isNull);
  });
}
