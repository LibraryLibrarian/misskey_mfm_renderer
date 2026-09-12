import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../../core/settings/example_settings.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key, required this.emojiInitialized});

  final bool emojiInitialized;

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsScope.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ListTile(
              title: const Text('表示設定'),
              subtitle: Text(
                emojiInitialized
                    ? '絵文字: misskey.io と同期済み'
                    : '絵文字: 初期化に失敗（ネットワークが必要。カスタム絵文字はショートコード表示）',
              ),
              trailing: IconButton(
                tooltip: 'リセット',
                icon: const Icon(Icons.restart_alt),
                onPressed: settings.reset,
              ),
            ),
            const Divider(),
            _Section(
              title: '表示',
              child: Column(
                children: [
                  _SegmentedSetting<ThemeMode>(
                    title: 'テーマ',
                    subtitle: 'アプリと MFM の明暗を切り替えます',
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) {
                      settings.themeMode = selection.single;
                    },
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('システム'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('ライト'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('ダーク'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('カスタム配色'),
                    subtitle: const Text('リンクやメンションなどを紫系の配色に上書きします'),
                    value: settings.useCustomColorScheme,
                    onChanged: (value) {
                      settings.useCustomColorScheme = value;
                    },
                  ),
                ],
              ),
            ),
            _Section(
              title: 'MFM',
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('enableAdvancedMfmSwitch'),
                    title: const Text('Advanced MFM'),
                    subtitle: const Text(
                      'オフにすると x2〜x4 の拡大、scale、アニメーションが無効になります'
                      '（tada の 150% 拡大は残ります）',
                    ),
                    value: settings.enableAdvancedMfm,
                    onChanged: (value) {
                      settings.enableAdvancedMfm = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('アニメーション'),
                    subtitle: const Text(
                      'Advanced MFM がオンのときだけ有効。オフでは rainbow が静的な虹色になります',
                    ),
                    value: settings.enableAnimation,
                    onChanged: (value) {
                      settings.enableAnimation = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('コードコピーボタン'),
                    subtitle: const Text('コードブロック右上のコピーボタンを表示します'),
                    value: settings.showCodeBlockCopyButton,
                    onChanged: (value) {
                      settings.showCodeBlockCopyButton = value;
                    },
                  ),
                ],
              ),
            ),
            _Section(
              title: '投稿文脈',
              child: Column(
                children: [
                  _SegmentedSetting<MfmNyaizeMode>(
                    title: 'nyaize モード',
                    subtitle: '投稿本文の語尾を猫らしい表現へ変換する方法です',
                    selected: {settings.nyaizeMode},
                    onSelectionChanged: (selection) {
                      settings.nyaizeMode = selection.single;
                    },
                    segments: const [
                      ButtonSegment(
                        value: MfmNyaizeMode.disabled,
                        label: Text('オフ'),
                      ),
                      ButtonSegment(
                        value: MfmNyaizeMode.enabled,
                        label: Text('オン'),
                      ),
                      ButtonSegment(
                        value: MfmNyaizeMode.respectAuthor,
                        label: Text('投稿者'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('投稿者は猫'),
                    subtitle: const Text('nyaize の「投稿者」モードで変換を有効にします'),
                    value: settings.authorIsCat,
                    onChanged: (value) {
                      settings.authorIsCat = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('リモート投稿として扱う'),
                    subtitle: const Text(
                      'author.host を misskey.example にします。カスタム絵文字は emojiUrls '
                      'かリモート絵文字エンドポイントで解決されます',
                    ),
                    value: settings.remoteAuthor,
                    onChanged: emojiInitialized
                        ? (value) {
                            settings.remoteAuthor = value;
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('emojiUrls を渡す'),
                    subtitle: const Text(
                      'ai_smile_misskeyio と pudding_cat の URL を渡します。他の絵文字は'
                      'ショートコードのまま表示されます（リモート投稿時のみ有効）',
                    ),
                    value: settings.useEmojiUrls,
                    onChanged: emojiInitialized
                        ? (value) {
                            settings.useEmojiUrls = value;
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('絵文字の文脈を表示'),
                    subtitle: const Text(
                      '絵文字にホバー/長押しで fontSize・scale・normal・host・url を表示します',
                    ),
                    value: settings.showEmojiContext,
                    onChanged: (value) {
                      settings.showEmojiContext = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('isNote'),
                    subtitle: const Text(
                      'ハッシュタグの遷移先 path が /tags と /user-tags で切り替わります（コールバックの SnackBar で確認）',
                    ),
                    value: settings.isNote,
                    onChanged: (value) {
                      settings.isNote = value;
                    },
                  ),
                ],
              ),
            ),
            _Section(
              title: 'MfmText',
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('plain'),
                    subtitle: const Text('構文を解釈せず、改行を空白にします'),
                    value: settings.plain,
                    onChanged: (value) {
                      settings.plain = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('nowrap'),
                    subtitle: const Text('1 行に省略表示します（タイムラインのプレビュー向け）'),
                    value: settings.nowrap,
                    onChanged: (value) {
                      settings.nowrap = value;
                    },
                  ),
                  ListTile(
                    title: const Text('rootScale'),
                    subtitle: const Text(
                      'emojiBuilder に渡る scale の初期値。既定のビルダーでは見た目は変わりません'
                      '（文脈表示で確認できます）',
                    ),
                    trailing: DropdownButton<double>(
                      value: settings.rootScale,
                      onChanged: (value) {
                        if (value != null) settings.rootScale = value;
                      },
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1.0')),
                        DropdownMenuItem(value: 2, child: Text('2.0')),
                        DropdownMenuItem(value: 3, child: Text('3.0')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _SegmentedSetting<T> extends StatelessWidget {
  const _SegmentedSetting({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelectionChanged,
    required this.segments,
  });

  final String title;
  final String subtitle;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final List<ButtonSegment<T>> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              segments: segments,
              selected: selected,
              showSelectedIcon: false,
              onSelectionChanged: onSelectionChanged,
            ),
          ),
        ],
      ),
    );
  }
}
