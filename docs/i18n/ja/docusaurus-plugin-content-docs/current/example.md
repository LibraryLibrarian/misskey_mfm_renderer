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

## 開発版との差分

ガイドの対象は導入ページの公開済み依存です。撮影した開発checkoutには次の変更も含まれます。この表は**公開版へコピーして使うAPI例ではありません**。

| 分類 | 開発checkoutの変更（公開版ガイドのAPI対象外） |
| --- | --- |
| メンション | カプセル表示と`MfmMentionOptions`、表示・アバターproviderのオプション。 |
| 日時 | `MfmUnixtimeOptions`、絶対／相対日時の整形、相対ラベルの定期更新。 |
| 絵文字 | `MfmTwemojiBuilder`、絵文字contextの`textStyle`、カスタム絵文字の`fallbackTextStyle`。 |
| 検索・リンク | 編集可能な検索、ラベル付きリンクの外部アイコン（裸のURLのアイコンは公開版にも存在）。 |
| 枠線 | 9種類の枠線、RGBA、クリッピングの拡張。 |

## サンプルの実画面

**開発checkout**のexampleを、新規Androidエミュレーターで撮影した未加工の画像です。オフラインの架空データ・日本語UIを使っています。公開版の描画結果が同じであるという保証ではありません。iOSの表示検証を示す画像でもありません。

<figure className="example-capture">

![Androidの開発checkoutのexample：オフラインの架空データ・日本語UIで表示したテキスト整形カタログ。](/img/example-text-format-android-develop.png)

<figcaption>Androidの開発版example — テキスト整形カタログ。オフラインの架空データ、日本語UI、ライトテーマ、共有設定の初期値で撮影。</figcaption>
</figure>

<figure className="example-capture">

![Androidの開発checkoutのexample：オフラインの架空データ・日本語UIで表示したPlayground。](/img/example-playground-android-develop.png)

<figcaption>Androidの開発版example — Playground。オフラインの架空データ・日本語UIで、カタログのサンプルを設定とともに読み込み、編集せず撮影。</figcaption>
</figure>

撮影revision、元PNGのハッシュ、再現条件はリポジトリの[画像の来歴](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/docs/screenshots.md)に記録しています。

## 詳しい説明

カタログ、設定、ローカルデータ、プラットフォームごとの準備については、[サンプルのREADME](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md)に説明があります。自分のアプリへライブラリを組み込む場合は、[インストールと最初の表示](getting-started.md)から始めてください。
