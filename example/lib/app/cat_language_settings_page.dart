import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../core/settings/example_settings.dart';

class CatLanguageSettingsPage extends StatelessWidget {
  const CatLanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsScope.of(context);
    final respectsAuthor = settings.nyaizeMode == MfmNyaizeMode.respectAuthor;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('猫語変換')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const PageStorageKey('cat-language-scroll'),
              padding: EdgeInsets.only(
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Text(
                    '本文の「な」を「にゃ」などに変換します。\n'
                    '例：なにかな？ → にゃにかにゃ？',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                RadioGroup<MfmNyaizeMode>(
                  groupValue: settings.nyaizeMode,
                  onChanged: (value) {
                    if (value != null) settings.nyaizeMode = value;
                  },
                  child: const Column(
                    children: [
                      RadioListTile<MfmNyaizeMode>(
                        key: Key('nyaizeDisabledRadio'),
                        value: MfmNyaizeMode.disabled,
                        title: Text('変換しない'),
                        subtitle: Text('投稿者の猫設定に関係なく、変換しません。'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      RadioListTile<MfmNyaizeMode>(
                        key: Key('nyaizeEnabledRadio'),
                        value: MfmNyaizeMode.enabled,
                        title: Text('常に変換'),
                        subtitle: Text('投稿者の猫設定に関係なく、変換します。'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      RadioListTile<MfmNyaizeMode>(
                        key: Key('nyaizeRespectAuthorRadio'),
                        value: MfmNyaizeMode.respectAuthor,
                        title: Text('投稿者に従う'),
                        subtitle: Text('猫設定が有効な投稿者の文章だけ変換します。'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                  child: Semantics(
                    header: true,
                    child: Text(
                      'サンプルの投稿者',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                SwitchListTile(
                  key: const Key('authorIsCatSwitch'),
                  title: const Text('投稿者の猫設定'),
                  subtitle: Text(
                    respectsAuthor
                        ? '猫設定が有効な投稿者を再現します。'
                        : '「投稿者に従う」を選ぶと変更できます。',
                  ),
                  value: settings.authorIsCat,
                  onChanged: respectsAuthor
                      ? (value) => settings.authorIsCat = value
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        key: const Key('catLanguageExplanation'),
                        'Misskeyにはアカウントの「猫」設定があります。'
                        '投稿者は、表示する文章を書いたユーザーのことです。\n\n'
                        'このサンプルでは、上のスイッチで投稿者の状態を再現します。'
                        '実アカウントの設定は変更しません。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
