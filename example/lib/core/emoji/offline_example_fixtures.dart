import 'package:flutter/widgets.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

final MfmRenderConfig _missingEmojiConfig = MfmEmojiConfig.fromResolver(
  resolver: _resolveMissingEmoji,
);

Future<EmojiImage?> _resolveMissingEmoji(String name) async => null;

/// 標準のMfmCustomEmoji fallbackを、通信せずに表示する。
Widget offlineMissingEmoji(String name, MfmEmojiContext context) =>
    _missingEmojiConfig.emojiBuilder!(name, context);

/// 同梱Twemojiをデモ用アバターに使用。実ユーザーの画像ではない。
ImageProvider<Object>? offlineMentionAvatar(String acct) =>
    acct == '@alice' || acct == '@alice@local.test'
    ? const AssetImage('assets/twemoji/1f600.png')
    : null;
