import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../core/emoji/example_startup.dart';
import '../core/settings/example_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.emojiStatus});

  final ExampleEmojiStatus emojiStatus;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _confirmingReset = false;

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsScope.of(context);
    final emojiInitialized = widget.emojiStatus == ExampleEmojiStatus.online;

    return Scaffold(
      appBar: AppBar(title: const Text('表示設定')),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const PageStorageKey('settings-scroll'),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Section(
                  title: '外観',
                  child: Column(
                    children: [
                      _SegmentedSetting<ThemeMode>(
                        key: const Key('themeModeSetting'),
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
                        key: const Key('useCustomColorSchemeSwitch'),
                        title: const Text('カスタム配色'),
                        subtitle: const Text('リンクやメンションなどを紫系の配色に上書きします'),
                        value: settings.useCustomColorScheme,
                        onChanged: (value) =>
                            settings.useCustomColorScheme = value,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'MFMの描画',
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
                        onChanged: (value) =>
                            settings.enableAdvancedMfm = value,
                      ),
                      SwitchListTile(
                        key: const Key('enableAnimationSwitch'),
                        title: const Text('アニメーション'),
                        subtitle: const Text(
                          'Advanced MFM がオンのときだけ有効。オフでは rainbow が静的な虹色になります',
                        ),
                        value: settings.enableAnimation,
                        onChanged: (value) => settings.enableAnimation = value,
                      ),
                      SwitchListTile(
                        key: const Key('showCodeBlockCopyButtonSwitch'),
                        title: const Text('コードコピーボタン'),
                        subtitle: const Text('コードブロック右上のコピーボタンを表示します'),
                        value: settings.showCodeBlockCopyButton,
                        onChanged: (value) =>
                            settings.showCodeBlockCopyButton = value,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '投稿者・猫変換',
                  child: Column(
                    children: [
                      _SegmentedSetting<MfmNyaizeMode>(
                        key: const Key('nyaizeModeSetting'),
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
                        key: const Key('authorIsCatSwitch'),
                        title: const Text('投稿者は猫'),
                        subtitle: const Text('nyaize の「投稿者」モードで変換を有効にします'),
                        value: settings.authorIsCat,
                        onChanged: (value) => settings.authorIsCat = value,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'カスタム絵文字',
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          switch (widget.emojiStatus) {
                            ExampleEmojiStatus.online =>
                              '絵文字: misskey.io と同期済み',
                            ExampleEmojiStatus.offline =>
                              '絵文字: オフライン起動（同期なし。専用例の同梱画像・fallbackを確認できます）',
                            ExampleEmojiStatus.failed =>
                              '絵文字: 初期化に失敗（ネットワークが必要。カスタム絵文字はショートコード表示）',
                          },
                        ),
                      ),
                      SwitchListTile(
                        key: const Key('remoteAuthorSwitch'),
                        title: const Text('リモート投稿として扱う'),
                        subtitle: const Text(
                          'author.host を misskey.example にします。'
                          'カスタム絵文字は emojiUrls かリモート絵文字エンドポイントで解決されます',
                        ),
                        value: settings.remoteAuthor,
                        onChanged: emojiInitialized
                            ? (value) => settings.remoteAuthor = value
                            : null,
                      ),
                      SwitchListTile(
                        key: const Key('useEmojiUrlsSwitch'),
                        title: const Text('emojiUrls を渡す'),
                        subtitle: const Text(
                          'ai_smile_misskeyio と pudding_cat の URL を渡します。他の絵文字は'
                          'ショートコードのまま表示されます（リモート投稿時のみ有効）',
                        ),
                        value: settings.useEmojiUrls,
                        onChanged: emojiInitialized
                            ? (value) => settings.useEmojiUrls = value
                            : null,
                      ),
                      SwitchListTile(
                        key: const Key('showEmojiContextSwitch'),
                        title: const Text('絵文字の文脈を表示'),
                        subtitle: const Text(
                          '共通の絵文字ビルダーにホバー/長押しで fontSize・scale・normal・host・url・textStyle を表示します。'
                          '個別ビルダーを使用する例は対象外です',
                        ),
                        value: settings.showEmojiContext,
                        onChanged: (value) => settings.showEmojiContext = value,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'rootScale',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'emojiBuilder に渡る scale の初期値。既定のビルダーでは見た目は変わりません'
                              '（文脈表示で確認できます）',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            DropdownButton<double>(
                              key: const Key('rootScaleDropdown'),
                              isExpanded: true,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'MfmTextの表示・動作',
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('plainSwitch'),
                        title: const Text('plain'),
                        subtitle: const Text('構文を解釈せず、改行を空白にします'),
                        value: settings.plain,
                        onChanged: (value) => settings.plain = value,
                      ),
                      SwitchListTile(
                        key: const Key('nowrapSwitch'),
                        title: const Text('nowrap'),
                        subtitle: const Text('1 行に省略表示します（タイムラインのプレビュー向け）'),
                        value: settings.nowrap,
                        onChanged: (value) => settings.nowrap = value,
                      ),
                      SwitchListTile(
                        key: const Key('isNoteSwitch'),
                        title: const Text('isNote'),
                        subtitle: const Text(
                          'ハッシュタグの遷移先 path が /tags と /user-tags で切り替わります（コールバックの SnackBar で確認）',
                        ),
                        value: settings.isNote,
                        onChanged: (value) => settings.isNote = value,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: OutlinedButton(
                    key: const Key('resetSettingsButton'),
                    onPressed: _confirmReset,
                    child: const Text('既定値に戻す'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    if (_confirmingReset) return;
    _confirmingReset = true;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('表示設定を既定値に戻しますか？'),
          content: const Text('共通の表示設定をリセットします。編集中の本文や例ごとの個別設定は変更しません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('既定値に戻す'),
            ),
          ],
        ),
      );
      if (mounted && accepted == true) ExampleSettingsScope.of(context).reset();
    } finally {
      _confirmingReset = false;
    }
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
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
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
    super.key,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              return SizedBox(
                width: double.infinity,
                child: SegmentedButton<T>(
                  direction: constraints.maxWidth < 320 * textScale
                      ? Axis.vertical
                      : Axis.horizontal,
                  segments: segments,
                  selected: selected,
                  showSelectedIcon: false,
                  onSelectionChanged: onSelectionChanged,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
