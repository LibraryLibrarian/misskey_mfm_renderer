---
id: overview
slug: /
title: 概要
sidebar_label: 概要
---

# misskey_mfm_renderer

`MfmText`を使って、[Misskey Flavored Markdown（MFM）](https://misskey-hub.net/ja/docs/for-users/features/mfm/)をFlutterで表示するライブラリです。MFMは一般的な文字装飾に加え、カスタム絵文字、変形、アニメーションなどの表現を持ちます。

このライブラリはMFMの文字列や解析済みノードをFlutterのウィジェットとして描画します。タイムラインの取得やMisskeyアプリ全体を提供するものではありません。表示する本文、描画設定、タップ時などの処理は利用側のアプリで用意します。

## はじめに読むページ

- [インストールと最初の表示](getting-started.md)：サーバー接続を設定せずにMFMを表示します。
- [サンプルアプリ](example.md)：カタログを閲覧し、Playgroundで本文や設定を試します。
- [MFMの描画](rendering.md)：入力、表示モード、対応構文と制限を確認します。
- [設定](configuration.md)：共有スタイル、配色、フォント、猫語変換を設定します。
- [カスタム絵文字](custom-emoji.md)：初期化、所有権、リモート投稿、独自builderを扱います。
- [操作とコールバック](interactions.md)：コールバックとアプリの遷移方針を確認します。
- [アニメーションとアクセシビリティ](animation-accessibility.md)：動きを減らす設定と読み上げの制限を確認します。
- [APIリファレンス](https://pub.dev/documentation/misskey_mfm_renderer/latest/)：最新の公開パッケージから生成されたAPI定義を確認します。

コピー可能なガイドの例は導入ページの公開済みパッケージを対象にしています。開発版限定の機能・画像はサンプルアプリのページで区別しています。

## 表示できるもの

- 文字装飾、引用、コード、リンク、メンション、ハッシュタグ
- Unicode絵文字と、解決方法や描画方法を設定できるカスタム絵文字
- サイズ、変形、スタイル、アニメーションを扱うMFMの`fn`関数

色、文字スタイル、コールバック、アニメーション設定などで表示を調整できます。対応する関数と制約は[描画ガイド](rendering.md)を参照してください。Misskeyのすべての機能を実装しているという意味ではありません。

## 対応環境

**Android・iOS・macOS・Linux・Windows**に対応しています。Flutter **3.38.1以上**、Dart **3.10.0以上**が必要です。

**Webは非対応です。** Web向けにコンパイルできる場合でも、標準のカスタム絵文字設定にはWeb用ストアがなく、Web上の描画も検証していません。このサイトはドキュメントであり、Flutterサンプルのブラウザー版ではありません。

描画した本文の文字選択には対応していません。コピー機能が必要な場合は、アプリ側で元のMFM文字列を利用してください。

カスタム絵文字には、同梱の`misskey_emoji`を利用します。標準の設定は永続化用のSQLiteストアを所有し、初期化と破棄が必要です。[最小のテキスト表示例](getting-started.md)では、この設定は不要です。ストレージや画像読み込みを設定する際は、[カスタム絵文字ガイド](custom-emoji.md)も確認してください。

## 公開パッケージと開発中のサンプル

導入ページでは公開パッケージを依存関係に指定します。一方、リポジトリの`develop`ブランチ、README、同梱のサンプルには未リリースの変更が含まれる場合があります。未リリースと記載された機能を利用する前に、[CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)を確認してください。
