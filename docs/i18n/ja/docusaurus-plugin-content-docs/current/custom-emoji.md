---
id: custom-emoji
slug: /custom-emoji
title: カスタム絵文字
sidebar_label: カスタム絵文字
---

サーバー固有の`:shortcode:`には絵文字設定が必要です。builderがなければ文字列のまま表示します。レンダラーの導入は[インストールと最初の表示](getting-started.md)を参照してください。

## 既定のカタログとストレージ

`MfmEmojiConfig.createDefault`は呼出側所有の`MisskeyClient`を永続カタログ、resolver、画像builderへ接続します。戻り値は単なるconfigではなく**ハンドル**です。既定の保存先はアプリのdocumentsディレクトリで、`storagePath`で変更できます。既定ストアはSQLite／Driftを使います。タイムラインのノートごとではなく、画面・アプリの単位でハンドルを保持してください。

次の例は作成済みクライアントを受け取ります。`misskey_client`を直接importするため、アプリの直接依存にも追加してください（古いbeta.5ではなく`^1.0.0-beta.6`互換）。既定ではオンラインのバックグラウンド同期を行います。その通信を意図する場合に限り、対象サーバーを明示的に選んだクライアントを渡してください。

導入ページのアプリ配下で使用します。ウィジェットの生存中はclientを固定し、サーバー変更時は新しいkeyでウィジェットを置き換えてください。非同期のハンドル破棄が完了するまでclientを有効に保つ必要があります。アプリ全体の終了処理などで順序をawaitする必要がある場合は、Stateの外でハンドルを所有し、ハンドル破棄をawaitしてからclientを閉じてください。

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class EmojiExample extends StatefulWidget {
  const EmojiExample({super.key, required this.client});

  final MisskeyClient client;

  @override
  State<EmojiExample> createState() => _EmojiExampleState();
}

class _EmojiExampleState extends State<EmojiExample> {
  late final Future<MfmEmojiConfigHandle> _pending;
  MfmEmojiConfigHandle? _handle;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _pending = MfmEmojiConfig.createDefault(client: widget.client);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final handle = await _pending;
      if (mounted) setState(() => _handle = handle);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _close() async {
    MfmEmojiConfigHandle handle;
    try {
      handle = await _pending;
    } catch (_) {
      return; // Initialization failed; no handle was returned.
    }
    try {
      await handle.dispose();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('while disposing the emoji handle'),
      ));
    }
  }

  @override
  void dispose() {
    unawaited(_close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return const Text('Emoji initialization failed');
    final handle = _handle;
    if (handle == null) return const CircularProgressIndicator();
    return MfmText(text: ':smile:', config: handle);
  }
}
```

## 所有権と非同期の後始末

この例は初期化完了前にウィジェットが取り除かれた場合も完了を待ち、戻ったハンドルを破棄します。Flutterの`State.dispose`は非同期にできないため、後始末を別途実行し、破棄エラーを報告します。初期化Futureを捨てて、後から生成されたハンドルを失わないようにしてください。

- `await handle.dispose()`は冪等で、バックグラウンド同期の終了を待ってからカタログ・ストアを閉じます。
- **呼出側のclientは破棄しません**。
- `handle.copyWith(...)`のコピーはライフサイクルを共有します。いずれかを破棄すると共有リソースも破棄されるため、ノートごとにdisposeしないでください。
- `autoSync: false`で初回のバックグラウンド同期を無効化します。`onSyncError`で同期失敗を観測できます。ハンドル生成の成功だけではサーバー同期の成功は確認できません。
- `emojiRefreshListenable`でカタログ更新を描画へ通知できます。既定のauto-syncも更新を通知します。

## リモート投稿のコンテキスト

`handle`から投稿ごとの設定を派生させ、`author: MfmAuthorContext(host: 'remote.example')`と、投稿の絵文字名から画像URLへのmapである`emojiUrls`を渡します。ローカル投稿者のhostはnullです。helperの`localHost`はclientのoriginから設定します。

mapは不変として扱い、内容が変わる場合は置き換えてください。**mapが存在するのに対象ショートコードがない場合は文字列へフォールバック**します。map未指定とは同じではありません。設定の再利用時には[公開済みのclearフラグ](configuration.md)で古い投稿情報を除いてください。

## 既存resolver・独自builder

アプリがカタログ／resolverを所有している場合は`MfmEmojiConfig.fromResolver(resolver: ..., serverBaseUrl: ...)`を使えます。所有ハンドルではなくconfigを返すため、カタログ・ストアは呼出側で破棄します。`serverBaseUrl`は直接URLがないリモート絵文字のフォールバックURLを有効にし、未指定では未解決のリモート絵文字がショートコードのままになります。

すべてを制御する場合、`emojiBuilder`は`(String name, MfmEmojiContext context)`を受け取ります。`unicodeEmojiBuilder`はUnicode文字列と同じcontextを受け取ります。Widgetを返し、読み込み・エラー・semanticsの挙動を実装してください。公開版のcontextには`fontSize`、`scale`、`normal`、`host`、`url`、`useOriginalSize`があり、開発版の`textStyle`は**ありません**。独自resolverや直接URLは通信先に関わるため、アプリのメディア・ホスト方針を適用してください。

## サイズ・ベースライン・キャッシュ

- helperの既定の高さは**2em**、normal／plainのcontextでは**1.25em**です。`emojiSize`は最小値ではなく固定の高さです。単独の`MfmCustomEmoji.size`は既定24です。
- helperに合わせるbuilderのベースラインoffsetは`size / 2 - context.fontSize * 0.25`、normal／plainでは`context.fontSize * 0.25`です。外側の描画変形が倍率を適用するため、画像へさらに`context.scale`を掛けないでください。
- `emojiMaxWidth`で幅を制限します。`useOriginalSize`は独自builder向けのヒントです。resolverが原寸・サムネイルURLを区別しない場合、helperでは自動選択できません。
- URLとアスペクト比のキャッシュはプロセス全体で各256件のLRUです。`cacheScope`で識別範囲を分けます。既定ではresolverの同一性または直接URLを使うため、buildごとのresolverクロージャ再作成は再利用を妨げます。

## プラットフォームとよくある問題

ネイティブのAndroid／iOS／macOS／Linux／Windowsが対象で、Webは非対応です。保存先・通信の準備は[example README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md)を参照してください。ビルド時のSQLiteや依存の取得と、実行時の同期は別です。

ショートコードが残る場合は、resolver、サーバーorigin、投稿のhost／map、同期エラー、画像の有無、OSの通信権限を確認してください。トークンをログへ出したり、文字列へのフォールバックだけで認証エラーと断定したりしないでください。再現可能なローカルテストではauto-syncを無効化し、fakeストア／resolverを注入できますが、実サーバーとの同期を検証したことにはなりません。

次へ：[設定](configuration.md) · [操作とコールバック](interactions.md) · [MfmEmojiConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmEmojiConfig-class.html)
