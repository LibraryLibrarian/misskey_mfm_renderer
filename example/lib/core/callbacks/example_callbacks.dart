import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class ExampleCallbacks {
  const ExampleCallbacks(this.scaffoldMessengerKey);

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  void onLinkTap(String url) => _show('リンク: $url');

  void onMentionTap(String acct) => _show('メンション: $acct');

  void onHashtagTapDetails(MfmHashtagTapDetails details) {
    _show(
      'ハッシュタグ: #${details.tag}（isNote=${details.isNote}, path=${details.path}）',
    );
  }

  void onSearchTap(String query) => _show('検索: $query');

  void onClickableEvent(String eventId) => _show('clickable: $eventId');

  void _show(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
