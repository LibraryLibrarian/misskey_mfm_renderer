---
id: rendering
slug: /rendering
title: MFMの描画
sidebar_label: MFMの描画
---

`MfmText`はMisskey Flavored MarkdownをネイティブのFlutterウィジェットとして描画します。[インストールと最初の表示](getting-started.md)で公開済みパッケージを導入してください。このガイドのコピー可能な例は、開発中のexampleではなく公開版APIを対象にしています。

## 描画領域の幅を制限する

導入ページのMaterialアプリのbodyに配置できるウィジェットです。`$[...]`にはDartの**raw文字列**を使い、`$`が文字列補間として解釈されないようにします。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class RenderExample extends StatelessWidget {
  const RenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      child: MfmText(
        text: r'**Hello** $[fg.color=336699 blue] $[x2 large]',
        config: MfmRenderConfig(enableAnimation: false),
      ),
    );
  }
}
```

## 入力と表示モード

| 入力 | 挙動 |
| --- | --- |
| `text` | MFMの本文。空文字列は何も表示しません。 |
| `parsedNodes` | `misskey_mfm_parser`で解析済みの`List<MfmNode>`。同じ解析結果を再利用でき、`text`より優先されます。アプリでparserをimportする場合は直接依存に追加してください。 |
| `simple: true` | 簡易parserを使用。通常のテキスト、メンション、ハッシュタグ、URLや多くの装飾を完全なMFMとして処理しません。Unicode／カスタム絵文字は扱えます。 |
| `plain: true` | 同じく簡易解析を使い、絵文字へ通常サイズの描画コンテキストを渡します。汎用のHTML／Markdownサニタイザーではありません。 |
| `nowrap: true` | 1行で表示し、あふれた部分を省略記号にします。利用可能な幅を有限にしてください。 |
| `rootScale` | 有限の正数で指定する基準倍率（既定`1.0`）。MFM描画へ作用する値であり、アプリのアクセシビリティ設定の代替ではありません。 |
| `isNote` | 既定`true`。parserではなくハッシュタグの遷移情報に作用します。[操作とコールバック](interactions.md)を参照してください。 |

`text`か`parsedNodes`のいずれかが必要で、コンストラクターでassertします。parserの`FormatException`発生時は本文全体をプレーンテキストで表示します。すべての不正な入力が例外になる、または無害化されるという保証ではありません。投稿ごとのホスト・絵文字情報は[カスタム絵文字](custom-emoji.md)で説明します。

## 対応構文

| 分類 | 例・挙動 |
| --- | --- |
| テキスト | 太字`**text**`、斜体`*text*`、打ち消し`~~text~~`、small `<small>text</small>`、中央寄せ`<center>text</center>`。 |
| 遷移 | URL、`[label](https://example.com)`、`@name`、`#tag`、検索ブロック。遷移処理はコールバックで実装します。 |
| コード・引用 | バッククォートのインラインコード、ハイライト・コピー付きコードブロック、`> quote`。引用には幅が制限されたレイアウトが必要です。 |
| 絵文字 | Unicode絵文字と`:shortcode:`。サーバー絵文字にはbuilder／resolverが必要です。 |
| 数式 | インライン・ブロックとも**等幅テキスト**表示であり、LaTeX描画ではありません。 |
| plain領域 | `<plain>...</plain>`の内部はそのまま表示します。 |

### 関数ブロック

| 関数の分類 | 公開版の挙動 |
| --- | --- |
| `x2`, `x3`, `x4`, `scale`, `position` | サイズ・位置の効果。高度なMFMの設定により適用が変わります。 |
| `fg`, `bg`, `font`, `border` | 文字色・背景色、フォント、枠線。開発版exampleの拡張されたborderオプションが公開版にもあるとは限りません。 |
| `flip`, `rotate` | 静的な変形。 |
| `blur` | 操作で解除できる視覚的なぼかし。セキュリティや機密情報の秘匿には使えません。 |
| `ruby`, `unixtime` | ルビと日時表示。[サンプルアプリ](example.md)の開発版との差分も参照してください。 |
| `clickable` | コールバックへイベントIDを渡します。 |
| `jelly`, `tada`, `jump`, `bounce`, `shake`, `twitch`, `spin`, `rainbow`, `sparkle` | アニメーション・エフェクト。[アニメーションとアクセシビリティ](animation-accessibility.md)で動きの制御を説明します。 |

未知の関数は`$[name ...]`の文字列表記を残して子の内容を描画し、未知の効果は適用しません。対応している関数でもMisskeyのブラウザー描画とピクセル単位で一致する保証はありません。

## 制限とよくある問題

- **Web非対応**、**テキスト選択非対応**です。SelectableTextではなく、ウィジェットを埋め込んだRichTextを使います。
- 引用や長い本文がはみ出す場合は、Row内の`Expanded`など、幅を制限する親を使ってください。
- フォントや字形の有無はOSに依存します。すべてのOSで同じ字体を仮定せず、[文字・フォントの設定](configuration.md)を行ってください。
- 描画後のspanの`toPlainText()`は意味上の本文の書き出しには適しません。埋め込みウィジェットや視覚効果で元の本文と異なり得ます。元の本文を保持するか、アプリの用途に合う変換を定義してください。
- カスタム絵文字のresolverが未設定・解決失敗の場合はショートコードが残ります。MFM解析の失敗とは限りません。

次へ：[設定](configuration.md) · [カスタム絵文字](custom-emoji.md) · [APIリファレンス](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
