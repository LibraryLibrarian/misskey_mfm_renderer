# misskey_mfm_renderer

[![pub package](https://img.shields.io/pub/v/misskey_mfm_renderer.svg)](https://pub.dev/packages/misskey_mfm_renderer)

[English](README.md) | 日本語

Misskey MFM（Misskey Flavored Markdown）を描画するFlutterウィジェットライブラリです。
`misskey_emoji` によるカスタム絵文字連携を提供します。

**ドキュメント：** [English](https://librarylibrarian.github.io/misskey_mfm_renderer/) ·
[日本語](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/) ·
[简体中文](https://librarylibrarian.github.io/misskey_mfm_renderer/zh-Hans/) ·
[Deutsch](https://librarylibrarian.github.io/misskey_mfm_renderer/de/) ·
[Français](https://librarylibrarian.github.io/misskey_mfm_renderer/fr/) ·
[한국어](https://librarylibrarian.github.io/misskey_mfm_renderer/ko/)

上記は公開先URLです。まだサイトを利用できない場合は、
[ガイドのソース](https://github.com/LibraryLibrarian/misskey_mfm_renderer/tree/develop/docs/i18n/ja/docusaurus-plugin-content-docs/current)
または[公開版APIリファレンス](https://pub.dev/documentation/misskey_mfm_renderer/latest/)を参照してください。

## 機能

- MFMの文字装飾、引用、コードのハイライト、リンク、メンション、ハッシュタグ。
- カスタム絵文字の解決、リモート投稿の絵文字URL、画像キャッシュ。
- MFM関数とアニメーション制御、ライト／ダーク配色、設定の継承。
- アプリ側で処理するリンク、メンション、ハッシュタグ、検索、コピーのコールバック。

カスタム絵文字構文はMFMの一部です。`misskey_emoji` を内包していますが、
サーバーの絵文字を描画するにはresolverの設定とライフサイクル管理が必要です。
[高度なカスタム絵文字の設定](#高度なカスタム絵文字の設定)を参照してください。
数式は等幅テキストとして表示し、LaTeXとしては描画しません。Webと描画後のテキスト選択には
対応していません。構文と制約の詳細は[描画ガイド](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/rendering/)にまとめています。

## インストール

**Flutter 3.38.1以上**、**Dart 3.10.0以上**が必要です。リポジトリの開発SDKは
Flutter 3.38.7です。Webではなく、Android、iOS、macOS、Linux、Windowsを使用してください。

アプリの `pubspec.yaml` に公開パッケージを追加します。

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

```bash
flutter pub get
```

## クイックスタート

新規または使い捨てのFlutterアプリでは、以下を `lib/main.dart` として使用できます。
既存アプリではエントリーポイントを置き換えず、画面に `MfmText` を追加してください。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  runApp(const MfmDemoApp());
}

class MfmDemoApp extends StatelessWidget {
  const MfmDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: MfmText(text: '**Hello** from *MFM*!'),
          ),
        ),
      ),
    );
  }
}
```

この例は公開版の依存関係を使い、`develop` へのローカルpath依存を使いません。
ネイティブ端末での実行手順は[はじめに](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/getting-started/)を参照してください。

## ドキュメント

| ガイド | 内容 |
| --- | --- |
| [概要](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/) | 対象範囲、依存関係、制約 |
| [はじめに](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/getting-started/) | 導入と最初の描画 |
| [描画](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/rendering/) | 構文、パース、レイアウト |
| [設定](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/configuration/) | 継承、テーマ、clearフラグ |
| [カスタム絵文字](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/custom-emoji/) | 初期化、所有権、リモート投稿、サイズ |
| [インタラクション](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/interactions/) | コールバック、検索、コピー |
| [アニメーションとアクセシビリティ](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/animation-accessibility/) | 動きの設定とアクセシビリティの制約 |
| [example](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/example/) | 開発版アプリ、画面例、検証範囲 |

### 高度なカスタム絵文字の設定

`MfmEmojiConfig.createDefault`、`fromResolver`、リモート絵文字、独自ビルダーについては
[カスタム絵文字ガイド](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/custom-emoji/)を参照してください。
`misskey_client` を直接importする場合は、ガイドに示す依存関係も宣言してください。

`createDefault` は、`MfmRenderConfig` としてそのまま渡せる `MfmEmojiConfigHandle` を返します。
永続ストアを所有するため、所有者が使い終えたら `dispose()` の完了を待ってください。
`copyWith` のコピーはライフサイクルを共有し、どれかを破棄するとすべてが破棄されます。
渡した `MisskeyClient` は引き続きアプリが所有します。`fromResolver` はresolverの所有権を取得しません。

テストでは `emojiStoreFactory` を注入してSQLiteを開かずに検証できます。独自の `EmojiStore` は
`load`、`save`、`clear`、`count`、`sizeInBytes` を実装してください。既定ストアは
`MisskeyClient.baseUrl` ごとに分割されます。既存ハンドルが保持している同じサーバー・ディレクトリを
再度開くと `StateError` になります。異なる `storagePath` なら同時に開けます。

### MkMfm互換のドキュメントプロパティ

以下は `MfmRenderConfig` ではなく `MfmText` に指定します。

- `plain`：simple parserを使い、CRLF/CR/LFを空白へ正規化します（`parsedNodes` を渡す場合も適用）。
  `MfmEmojiContext.normal` が有効になり、組み込み絵文字設定は高さ1.25em、descent 0.25emを使います。
  一方、`simple: true` だけでは改行と通常の絵文字サイズを維持します。
- `nowrap`：折り返さず1行にして、はみ出しを省略記号で示します。引用はmargin、左罫線、opacityを
  維持し、自然なインライン幅で表示します。
- `rootScale`：有限の正数で指定する走査開始時の倍率です。ルートの文字サイズや描画変形は変更しません。
- `isNote`：詳細ハッシュタグコールバックのパスを `/tags/...` と `/user-tags/...` で切り替えます。
  画面遷移はアプリ側が担当し、`onHashtagTapDetails` は `onHashtagTap` より優先されます。

## 技術的な注意事項

### プラットフォームに関する注記

Webには対応していません。`misskey_emoji` は `MfmEmojiConfig.createDefault` 用のWebストアを
提供しておらず、Web上での描画も検証していません。

絵文字メタデータはDrift経由でSQLiteに保存します。`sqlite3` 3.xのbuild hooksは、
キャッシュのないビルドでGitHub Releasesからネイティブバイナリを取得します。
オフラインビルドや社内ミラーでは、アプリの `pubspec.yaml`（pub workspaceではworkspaceルート）に
`hooks.user_defines` を設定してください。設定項目は
[`misskey_emoji` のドキュメント](https://pub.dev/packages/misskey_emoji)を参照してください。

macOSのApp Sandboxを使う場合、`MfmEmojiConfig` と画像取得のために
`com.apple.security.network.client` entitlementが必要です。Windowsでは
Microsoft Visual C++ Runtime（`VCRUNTIME140.dll`）が必要です。

### Isarのキャッシュファイルからの移行

`misskey_emoji` 2.0.0-beta.1以前に依存するバージョンはIsarを使用していました。
現行ストアはサーバーごとの `misskey_emoji_<serverKey>_<hash8>.sqlite` を使い、旧ファイルを
読み込みません。初回同期でメタデータを再取得し、旧ファイルはディスク容量を占めるだけです。

削除する場合は、**古いハンドルをすべて破棄した後**、`MfmEmojiConfig.createDefault` に渡した
`storagePath`（省略時はアプリのドキュメントディレクトリ）から、次のファイルだけを削除してください。

```text
<directory>/misskey_emoji_*.isar
<directory>/misskey_emoji_*.isar-lck
```

**必ず `misskey_emoji_` の接頭辞で絞り込んでください。** 同じ場所にあるアプリ独自の
無関係なIsarデータベースを削除しないでください。

### テキスト選択について

描画後のテキストは選択できません。コピー機能は元のMFMソースからアプリ側で実装してください。
`InlineSpan.toPlainText()` は意味を保ったテキスト出力を保証しません。
[インタラクション](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/interactions/)と
[アクセシビリティの制約](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/animation-accessibility/)も参照してください。

### スケールの制限

`scale` 関数は最大5倍です。`enableAdvancedMfm: false` の場合は描画時の変形も
`MfmEmojiContext.scale` への倍率伝播も行わず、外側のx系関数から継承した倍率を維持します。
静的な `TextSpan` の子要素は、本家の空のinline-blockによる行レイアウトの境界までは再現しません。

### サイズ関数の入れ子

`x2`、`x3`、`x4` は混在時も共通のネスト深さを使います。advanced MFM有効時のサイズは、
親の実効フォントサイズに対する相対値です。

- 1階層目：順に200%、400%、600%。
- 2階層目：内側の関数の `zoom / 2 + 50%`（150%、250%、350%）。
- 3階層目以降：100%で、追加の拡大なし。

基準14pxの `$[x2 $[x2 A]]` は外側28px・内側42px、`$[x2 $[x3 A]]` は内側70pxです。
他のノードは深さを増やさず継承します。`enableAdvancedMfm: false` の場合は全階層で文字サイズを
維持しつつ、公称倍率2/3/4は伝播します。後者の例は14pxのままscale 6を渡します。
`enableAnimation` だけを無効にしてもサイズ関数の動作は変わりません。

### borderのクリッピング

`border` 関数の `noclip` 引数は子要素の描画クリッピングを無効にしますが、祖先のヒット領域は
拡大しません。borderのスタイル、数値・色のパース、クリッピングにはさらに**未公開の変更**があります。
開発版の動作が公開版に含まれると考えず、以下の移行情報を確認してください。

## 開発版と未公開の変更

ガイドとインストール例は公開パッケージを対象にしています。`develop` のソースとexampleアプリは
新しい動作を含む場合があります。
[CHANGELOGのUnreleased](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md#unreleased)に、
編集可能な検索、ラベル付きリンク、border、unixtime、メンションカプセル、絵文字fallbackの移行情報と、
任意利用のTwemoji対応を記載しています。

[開発版example](https://github.com/LibraryLibrarian/misskey_mfm_renderer/tree/develop/example)は、
公開パッケージの動作保証ではありません。
[サイト移行前の開発版リファレンス](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/8e530138d977a67bd3b91e69ecd7fbbd9751bd7a/README.ja.md)には
従来の詳細例を履歴として保存しています。未公開APIを含む過去のスナップショットであり、
現行の公開版APIリファレンスではありません。

## 追加情報

- [APIドキュメント](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM仕様](https://misskey-hub.net/ja/docs/for-users/features/mfm/)
- [Issues](https://github.com/LibraryLibrarian/misskey_mfm_renderer/issues)

## ライセンス

3-Clause BSD License - [LICENSE](LICENSE) を参照
