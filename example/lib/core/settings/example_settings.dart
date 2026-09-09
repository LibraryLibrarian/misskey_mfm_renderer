import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../callbacks/example_callbacks.dart';

class ExampleSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useCustomColorScheme = false;
  bool _enableAdvancedMfm = true;
  bool _enableAnimation = true;
  MfmNyaizeMode _nyaizeMode = MfmNyaizeMode.disabled;
  bool _authorIsCat = false;
  bool _remoteAuthor = false;
  bool _useEmojiUrls = false;
  bool _showEmojiContext = false;
  bool _plain = false;
  bool _nowrap = false;
  double _rootScale = 1;
  bool _isNote = true;
  bool _showCodeBlockCopyButton = true;

  ThemeMode get themeMode => _themeMode;
  bool get useCustomColorScheme => _useCustomColorScheme;
  bool get enableAdvancedMfm => _enableAdvancedMfm;
  bool get enableAnimation => _enableAnimation;
  MfmNyaizeMode get nyaizeMode => _nyaizeMode;
  bool get authorIsCat => _authorIsCat;
  bool get remoteAuthor => _remoteAuthor;
  bool get useEmojiUrls => _useEmojiUrls;
  bool get showEmojiContext => _showEmojiContext;
  bool get plain => _plain;
  bool get nowrap => _nowrap;
  double get rootScale => _rootScale;
  bool get isNote => _isNote;
  bool get showCodeBlockCopyButton => _showCodeBlockCopyButton;

  set themeMode(ThemeMode value) => _update(_themeMode, value, () {
    _themeMode = value;
  });

  set useCustomColorScheme(bool value) =>
      _update(_useCustomColorScheme, value, () {
        _useCustomColorScheme = value;
      });

  set enableAdvancedMfm(bool value) => _update(_enableAdvancedMfm, value, () {
    _enableAdvancedMfm = value;
  });

  set enableAnimation(bool value) => _update(_enableAnimation, value, () {
    _enableAnimation = value;
  });

  set nyaizeMode(MfmNyaizeMode value) => _update(_nyaizeMode, value, () {
    _nyaizeMode = value;
  });

  set authorIsCat(bool value) => _update(_authorIsCat, value, () {
    _authorIsCat = value;
  });

  set remoteAuthor(bool value) => _update(_remoteAuthor, value, () {
    _remoteAuthor = value;
  });

  set useEmojiUrls(bool value) => _update(_useEmojiUrls, value, () {
    _useEmojiUrls = value;
  });

  set showEmojiContext(bool value) => _update(_showEmojiContext, value, () {
    _showEmojiContext = value;
  });

  set plain(bool value) => _update(_plain, value, () {
    _plain = value;
  });

  set nowrap(bool value) => _update(_nowrap, value, () {
    _nowrap = value;
  });

  set rootScale(double value) => _update(_rootScale, value, () {
    _rootScale = value;
  });

  set isNote(bool value) => _update(_isNote, value, () {
    _isNote = value;
  });

  set showCodeBlockCopyButton(bool value) =>
      _update(_showCodeBlockCopyButton, value, () {
        _showCodeBlockCopyButton = value;
      });

  void reset() {
    if (_themeMode == ThemeMode.system &&
        !_useCustomColorScheme &&
        _enableAdvancedMfm &&
        _enableAnimation &&
        _nyaizeMode == MfmNyaizeMode.disabled &&
        !_authorIsCat &&
        !_remoteAuthor &&
        !_useEmojiUrls &&
        !_showEmojiContext &&
        !_plain &&
        !_nowrap &&
        _rootScale == 1 &&
        _isNote &&
        _showCodeBlockCopyButton) {
      return;
    }

    _themeMode = ThemeMode.system;
    _useCustomColorScheme = false;
    _enableAdvancedMfm = true;
    _enableAnimation = true;
    _nyaizeMode = MfmNyaizeMode.disabled;
    _authorIsCat = false;
    _remoteAuthor = false;
    _useEmojiUrls = false;
    _showEmojiContext = false;
    _plain = false;
    _nowrap = false;
    _rootScale = 1;
    _isNote = true;
    _showCodeBlockCopyButton = true;
    notifyListeners();
  }

  void _update<T>(T current, T next, VoidCallback apply) {
    if (current == next) return;
    apply();
    notifyListeners();
  }
}

class ExampleSettingsScope extends InheritedNotifier<ExampleSettings> {
  const ExampleSettingsScope({
    super.key,
    required ExampleSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static ExampleSettings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ExampleSettingsScope>()
        ?.notifier;
  }

  static ExampleSettings of(BuildContext context) {
    final settings = maybeOf(context);
    assert(settings != null, 'No ExampleSettingsScope found in context');
    return settings!;
  }
}

MfmRenderConfig buildRenderConfig(
  ExampleSettings settings,
  MfmRenderConfig base,
  ExampleCallbacks callbacks,
) {
  final baseBuilder = base.emojiBuilder;
  final emojiBuilder = settings.showEmojiContext && baseBuilder != null
      ? (String name, MfmEmojiContext context) => Tooltip(
          message:
              'fontSize=${context.fontSize} '
              'scale=${context.scale} '
              'normal=${context.normal} '
              'host=${context.host ?? '-'} '
              'url=${context.url ?? '-'}',
          child: baseBuilder(name, context),
        )
      : null;

  return base.copyWith(
    enableAdvancedMfm: settings.enableAdvancedMfm,
    enableAnimation: settings.enableAnimation,
    nyaizeMode: settings.nyaizeMode,
    author: MfmAuthorContext(
      host: settings.remoteAuthor ? 'misskey.example' : null,
      isCat: settings.authorIsCat,
    ),
    emojiUrls: settings.useEmojiUrls ? _emojiUrls : null,
    clearEmojiUrls: !settings.useEmojiUrls,
    emojiBuilder: emojiBuilder,
    onLinkTap: callbacks.onLinkTap,
    onMentionTap: callbacks.onMentionTap,
    onHashtagTapDetails: callbacks.onHashtagTapDetails,
    onSearchTap: callbacks.onSearchTap,
    onClickableEvent: callbacks.onClickableEvent,
    lightColorScheme: settings.useCustomColorScheme
        ? _customLightColorScheme
        : null,
    darkColorScheme: settings.useCustomColorScheme
        ? _customDarkColorScheme
        : null,
    showCodeBlockCopyButton: settings.showCodeBlockCopyButton,
  );
}

const Map<String, String> _emojiUrls = {
  'ai_smile_misskeyio': 'https://misskey.io/emoji/ai_smile_misskeyio.webp',
  'pudding_cat': 'https://misskey.io/emoji/pudding_cat.webp',
};

final MfmColorScheme _customLightColorScheme = const MfmColorScheme.light()
    .copyWith(
      accent: const Color(0xFF7C3AED),
      link: const Color(0xFF6D28D9),
      hashtag: const Color(0xFFBE185D),
      mention: const Color(0xFF8B5CF6),
      mentionMe: const Color(0xFF4C1D95),
      fg: const Color(0xFF3B2F52),
      bg: const Color(0xFFF8F5FF),
      divider: const Color(0xFFE9D5FF),
      panel: const Color(0xFFFFFFFF),
    );

final MfmColorScheme _customDarkColorScheme = const MfmColorScheme.dark()
    .copyWith(
      accent: const Color(0xFFC4B5FD),
      link: const Color(0xFFA78BFA),
      hashtag: const Color(0xFFF9A8D4),
      mention: const Color(0xFFC4B5FD),
      mentionMe: const Color(0xFFE9D5FF),
      fg: const Color(0xFFEDE9FE),
      bg: const Color(0xFF20152F),
      divider: const Color(0xFF4C3A62),
      panel: const Color(0xFF2D1F42),
    );
