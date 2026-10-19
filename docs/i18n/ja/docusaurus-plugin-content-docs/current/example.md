---
id: example
slug: /example
title: サンプルアプリ
sidebar_label: サンプルアプリ
---

リポジトリには、MFMの表示例を閲覧し、自分で本文を編集して試せるネイティブのFlutterアプリを同梱しています。現在の画面は**日本語UI**です。

## 起動する

開発ブランチを新しいディレクトリへcloneするか、既存のチェックアウトを利用します。

```bash
git clone --branch develop https://github.com/LibraryLibrarian/misskey_mfm_renderer.git
cd misskey_mfm_renderer/example
```

リポジトリで固定しているFlutter SDKを使用します（`flutter`は`fvm flutter`に置き換えられます）。端末一覧からネイティブの実行先を選んでください。まずはオンラインのカスタム絵文字サービスを初期化せずにカタログを閲覧できる、次の起動方法を推奨します。

```bash
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=MFM_EXAMPLE_OFFLINE=true
```

`<device-id>`を選択した端末のIDに置き換えてください。Web向けのデモではありません。

:::note 開発中のソースを使用します

サンプルは`path: ../`で親ディレクトリのパッケージを参照します。未リリース機能を含むチェックアウト中のソースを表示するため、pub.devの最新公開版と同じ機能とは限りません。[CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)も確認してください。

:::

## 閲覧と編集の流れ

1. **Catalog**：テキスト整形や`fn`関数などのカテゴリを選びます。関連する例は同じページにまとめています。
2. **この設定で試す**：サンプルのアクションから、本文と設定をPlaygroundへ渡します。この操作はアイコンで表示され、読み上げ用の説明とツールチップがあります。
3. **Playground**：MFMの本文を編集し、表示結果を確認します。クリア操作で本文を消去できます。
4. **表示設定**：設定画面を開き、共通の表示オプションを変更します。猫語変換には詳細画面があり、変換モードとサンプルの投稿者の猫設定を説明しています。

サンプル内の猫設定は実アカウントを変更しません。リンク、メンション、ハッシュタグ、clickable、検索の操作ではSnackBarを表示し、ブラウザーを開いたり検索リクエストを送ったりしません。

## オフラインとオンラインの違い

`MFM_EXAMPLE_OFFLINE=true`を指定しない場合は、起動時にmisskey.ioのカスタム絵文字設定を初期化します。設定画面では、オンライン初期化の成功、意図的なオフライン起動、初期化の失敗を区別して表示します。

オフライン指定時はカスタム絵文字の初期化を省略します。オンライン専用のリモート投稿者・`emojiUrls`の操作は無効になります。通常のサーバー絵文字はショートコードで表示されますが、ローカルデータを明示したフォールバック、アバター、Twemojiの例は確認できます。

この指定が制御するのはアプリ起動時の挙動です。依存関係の解決やSQLiteのビルドフックには通信が必要な場合があり、Web対応を追加するものでもありません。

## 詳しい説明

カタログ、設定、ローカルデータ、プラットフォームごとの準備については、[サンプルのREADME](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md)に説明があります。自分のアプリへライブラリを組み込む場合は、[インストールと最初の表示](getting-started.md)から始めてください。
