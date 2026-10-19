---
id: interactions
slug: /interactions
title: 操作とコールバック
sidebar_label: 操作とコールバック
---

レンダラーは操作を通知し、その意味はアプリ側で決定します。URLの起動、プロフィールへの遷移、検索リクエストの送信は**自動では行いません**。

## ローカルで操作を確認する例

[導入ページ](getting-started.md)と同じように、`MaterialApp`配下の`Scaffold`内へ配置してください。すべての操作はローカルのSnackBarを表示するだけで、URL起動用の依存や実アカウントは不要です。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class InteractionExample extends StatelessWidget {
  const InteractionExample({super.key});

  @override
  Widget build(BuildContext context) {
    void show(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return MfmText(
      text: '[Example](https://example.com) @alice #flutter\n'
          'Flutter Search\n'
          r'$[clickable.ev=demo Tap me]',
      config: MfmRenderConfig(
        localHost: 'example.com',
        onLinkTap: (url) => show('Link: $url'),
        onMentionTap: (acct) => show('Mention: $acct'),
        onHashtagTapDetails: (details) => show('Tag path: ${details.path}'),
        onSearchTap: (query) => show('Search: $query'),
        onClickableEvent: (eventId) => show('Event: $eventId'),
        onCodeCopied: (code) => show('Copied ${code.length} characters'),
        codeCopyTooltip: 'Copy code',
      ),
    );
  }
}
```

## コールバックの契約

| コールバック | 値と挙動 |
| --- | --- |
| `onLinkTap` | 元のURL。信頼済み・検証済みの遷移先ではありません。未設定なら自動起動しません。 |
| `onMentionTap` | 正規化したアカウント。ホストはメンション内の明示値、`author.host`、`localHost`の順で解決し、なければ元のアカウント表記を維持します。 |
| `onHashtagTapDetails` | タグ、`isNote`、エンコード済みの遷移パス。`onHashtagTap`より優先されます。 |
| `onHashtagTap` | 詳細コールバックがない場合の、タグのみを受け取る通知です。 |
| `onSearchTap` | 検索語句。公開版の検索表示は、開発版exampleの編集可能な入力欄とは異なります。 |
| `onClickableEvent` | `$[clickable.ev=demo ...]`の`ev`値。省略時は空文字列です。このコールバックがなければ通常のテキストとして表示します。 |
| `onCodeCopied` | クリップボードへコピーした後のコード全文。既定の成功SnackBarを置き換え、コピー処理自体は置き換えません。 |

ハッシュタグは`isNote: true`で`/tags/<encoded-tag>`、`false`で`/user-tags/<encoded-tag>`になります。相対パスであり、サーバーやNavigatorの自動選択は行いません。

## URLとイベントの方針はアプリ側で決める

通知される値は信頼できない投稿内容として扱ってください。起動前にアプリの方針に沿ってURIのschemeや遷移先を検証し、任意のschemeをそのままlauncherへ渡さないでください。プロフィール・サーバーの選択、認証、外部遷移の確認、clickableの許可イベントIDもアプリ側の責任です。イベントIDを実行可能なコードとして解釈しないでください。

## コピー完了の通知とアクセシビリティ

コピーボタンは既定で表示します。`showCodeBlockCopyButton: false`で非表示にできます。`codeCopyTooltip`はボタンの**Semanticsラベル**であり、ホバー時の視覚的なツールチップではありません。`onCodeCopied`がなければ、`ScaffoldMessenger`がある場合のみ既定の成功SnackBarを表示し、`codeCopiedMessage`で文面を変更できます。既定値は日本語／その他のロケールに応じて切り替わります。

組み込みのMaterialアイコングリフを使う場合は、アプリのFlutter設定で`uses-material-design: true`を維持してください。操作用ウィジェットを独自に置き換える場合も、対応するラベルとフォーカス操作を用意してください。

## よくある問題

タップしても反応しない場合は対応するコールバックと、`simple`／`plain`ではない完全な解析を使っているかを確認してください。ハッシュタグの両コールバックを設定した場合、詳細側だけが呼ばれます。メンションの遷移ホストが違う場合は、表示文字列から推測せず投稿ごとの`author`と共有の`localHost`を確認してください。

次へ：[設定](configuration.md) · [カスタム絵文字](custom-emoji.md) · [アニメーションとアクセシビリティ](animation-accessibility.md)
