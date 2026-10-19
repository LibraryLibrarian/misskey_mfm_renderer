---
id: getting-started
slug: /getting-started
title: インストールと最初の表示
sidebar_label: インストールと最初の表示
---

Flutter **3.38.1以上**、Dart **3.10.0以上**を使用するFlutterアプリを用意してください。実行先には対応するネイティブ環境を選びます。ChromeなどのWebターゲットは対象外です。

## パッケージを追加する

アプリの`pubspec.yaml`で、Flutter SDKの依存指定を残したまま次の項目を追加します。

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

アプリのディレクトリで依存関係を取得します。

```bash
flutter pub get
```

これは公開パッケージへの依存指定です。リポジトリの`develop`ブランチにある未リリースのソースは使用しません。

## MFMを表示する

新規または検証用のアプリで、次のコードを`lib/main.dart`として使用します。既存アプリへ組み込む場合は、エントリーポイントを置き換えず、表示したい画面へ`MfmText`を追加してください。

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

「Hello from MFM!」のうち、**Hello**が太字、*MFM*が斜体で表示されます。`MfmText`が元の文字列を解析し、指定された装飾を適用します。

端末一覧からネイティブの実行先を選び、次の`<device-id>`をそのIDに置き換えます。

```bash
flutter devices
flutter run -d <device-id>
```

この例はカスタム絵文字用のクライアントや永続ストアを初期化せず、本文の描画のためにサーバーへ接続しません。ただし、パッケージの取得やネイティブのビルドフックには通信が必要な場合があります。完全なオフラインビルドを保証する手順ではありません。

## カスタム絵文字を使う場合

`:custom_emoji:`のようなショートコードを書くだけでは、サーバーの設定や画像の解決は行われません。最小例ではその設定を省いており、利用側から`misskey_client`への直接依存を追加する必要もありません。

カスタム絵文字の設定は、既存の[READMEのクイックスタート](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/README.ja.md#クイックスタート)を参照してください。設定ハンドルの所有者と破棄の説明も含まれています。このREADMEは開発中のソースに追従するため、利用するバージョンと[CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)を照合してください。

## 次に試すこと

[サンプルアプリ](example.md)でMFMの機能を閲覧し、本文や表示設定を変更してみてください。引数の定義は[APIリファレンス](https://pub.dev/documentation/misskey_mfm_renderer/latest/)で確認できます。
