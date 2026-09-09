# misskey_mfm_renderer

[![pub package](https://img.shields.io/pub/v/misskey_mfm_renderer.svg)](https://pub.dev/packages/misskey_mfm_renderer)

[English](README.md) | 日本語

Misskey MFM (Misskey Flavored Markdown) をレンダリングするためのFlutterウィジェットライブラリです。

## MFMとカスタム絵文字について

MFMのカスタム絵文字構文（`:emoji_name:`）は標準仕様の一部であり、
オプション機能ではありません。本パッケージは `misskey_emoji` を内包して、
MFMのカスタム絵文字を含むレンダリングを一通り提供します。

### なぜ misskey_emoji を同梱するのか

カスタム絵文字の描画はMFMの中核機能です。追加の統合作業なしで
MFMを完全に描画できるようにするため、`misskey_emoji` を依存関係として含めています。

## 特徴

### 対応ノードタイプ

| カテゴリ | 要素 | 構文例 | 対応状況 |
|---------|------|--------|:--------:|
| **テキスト整形** | 太字 | `**bold**` | ✅ |
| | 斜体 | `*italic*` / `<i>italic</i>` | ✅ |
| | 取り消し線 | `~~strike~~` | ✅ |
| | 小文字（継承サイズの0.8倍・0.7減光） | `<small>small</small>` | ✅ |
| | プレーン | `<plain>text</plain>` | ✅ |
| **ブロック要素** | 引用 | `> quote` | ✅ |
| | 中央寄せ | `<center>text</center>` | ✅ |
| | コードブロック | ` ```code``` ` | ✅ |
| | インラインコード | `` `code` `` | ✅ |
| | 数式ブロック | `\[ formula \]` | ✅* |
| | インライン数式 | `\( formula \)` | ✅* |
| **リンク・参照** | URL | `https://example.com` | ✅ |
| | リンク | `[label](url)` | ✅ |
| | メンション | `@user@host` | ✅ |
| | ハッシュタグ | `#hashtag` | ✅ |
| | 検索 | `keyword 検索` | ✅ |
| **絵文字** | カスタム絵文字 | `:emoji_name:` | ✅ |
| | Unicode絵文字 | `😀` | ✅ |

*本家MisskeyもLaTeXを描画せず素の`<code>`として表示するため、両方の数式構文を本家準拠の装飾のない等幅テキストとして表示します。周囲の文字スタイルを継承し、背景・余白・強制的なブロック化は追加せず、パース後のTextNodeに含まれる改行を保持します。現在のパーサーは数式ブロック直後の改行を消費しますが、レンダラー側では補完しません。

### 追加の注意事項

**インラインコード**: 周囲の文字サイズ・色・太字などを継承した等幅フォントで表示し、余白（0.1em）と角丸（0.3em）は継承サイズに比例します。

**小文字**: `<small>` はネストするたびに継承サイズを0.8倍にし、0.7減光します。
減光は継承色のalphaだけでなく、`$[fg ...]` やリンク色などの固定色、絵文字などのウィジェットにも適用されるため、子の色指定で減光が打ち消されることはありません。

**引用**: `> quote` は本家の `QUOTE_STYLE` に合わせ、行全幅を使い、四辺8pxのmargin、上下6px・左12px・右0pxのpadding、幅3pxの左罫線で表示します。文字と罫線はルートの未減光文字色を共通のソースとし、引用と `<small>` の各階層で元のalphaに0.7を乗算します。ルート色は `baseTextStyle`、ベーススタイル未指定時は `DefaultTextStyle` から取得します。明示スタイルで色が未指定の場合は、Flutterの文字描画と同じ白を既定とします。
ブロック表示は有限幅の親（例: `SizedBox(width: 300)` や `Row` 内の `Expanded`）を前提とします。`Row` 内の非 `Expanded` 子など幅が無制約の場合は自然幅となり、独立した行になる保証はありません。境界の改行は追加しません。隣接引用のCSS margin collapseやブロック前後の余分な改行の扱いまでは完全再現していません。

**fnのリテラル表示**: 未知のfn、有効なフォント指定のない `font`、`enableAdvancedMfm: false` 時の `position` は、本家Misskeyと同じく子要素の装飾を維持した `$[name 中身]`（引数は省略）として表示されます。

**未実装の機能:**
- **フォントの制限**: `$[font.xxx]` 構文の一部のフォントタイプ（特に `emoji` と `math`）は、プラットフォームの制限によりデフォルトフォントにフォールバックします。代替策を検討中です。

**Nyaize（猫モード相当のテキスト変換）**: `enableNyaize` で有効化されます。
Misskeyの猫モードと同等の挙動で、テキストノードの文字列を猫語に変換します（ja-JP / en-US / ko-KR の3言語）。
`link` / `quote` / `plain` 配下のサブツリーは変換対象外（本家挙動に準拠）。
`nyaize(String)` 純粋関数も公開APIとして利用できます。

### カスタム絵文字対応

`misskey_emoji` ライブラリとの連携により、カスタム絵文字表示に対応しています。

**対応状況**: ✅ `misskey_emoji` 連携で完全対応

**特徴**:
- 絵文字メタデータの自動解決
- `cached_network_image` による画像キャッシュ
- 実効フォントサイズに追随する高さ（既定2em）で、元画像のアスペクト比を維持した表示
- 読み込み済みアスペクト比の再利用によるプレースホルダのレイアウト安定化
- 未取得時のフォールバック表示
- アニメーション絵文字（GIF/APNG/WebP）に対応

`MfmEmojiConfig.createDefault` / `fromResolver` の既定の高さは **2em**
（`context.fontSize * 2`）です。フォント14pxでは28px、`$[x4 :emoji:]` では
168pxとなり、従来の24px固定から変更されています。`emojiSize` の既定値は
`null` になりました。固定の高さを維持する場合は `emojiSize: 24` を指定してください。
直接生成した場合の低レベルAPI `MfmCustomEmoji.size` の既定値は24pxのままです。
サイズ関数・`tada`・`<small>` は実効フォントサイズを変更します。`scale` は
フォントサイズを変更せず描画時の変形として適用されるため、高さに
`context.scale` を重ねて掛けないでください。
x2/x3/x4の視覚的拡大と `scale` の効果には `enableAdvancedMfm: true` が必要です。
falseの場合、x2/x3/x4はフォントサイズを変えませんが、公称倍率2/3/4は
`context.scale` へ伝播します。`scale` は変形も文脈への倍率伝播も行いません。
例えば基準14pxの `$[x4 :emoji:]` の高さは28pxのままで、描画文脈は
`(fontSize: 14, scale: 4)` になります。

カスタム絵文字の幅は既定で元画像の比率に従います。極端に横長な絵文字の幅を
制限する場合は、`MfmEmojiConfig` の `emojiMaxWidth` または
`MfmCustomEmoji` の `maxWidth` を指定してください。
画像比率を別のメタデータから取得済みの場合は、`MfmCustomEmoji` の
`aspectRatio` に渡すことで初回読み込み時のレイアウトも安定します。
比率が未知の場合、真の初回は意図的に幅0から始まるためリフローし得ます。
正確な初期幅が必要な場合は `aspectRatio` を指定してください。
ビルドのたびにresolverクロージャを生成する場合は、安定した値を
`MfmCustomEmoji.cacheScope` に渡してください。同じscopeを共有するWidgetは、
同じカタログ状態において同名絵文字を同じURLへ解決する必要があります。結果に
影響するホスト、アカウントなどをすべて含めてください。
例: `cacheScope: (resolverOwner, preferredHost, accountId)`。
scopeはレイアウトヒントのキャッシュだけを制御し、resolverが変わった場合は
再解決されます。省略時はresolver関数オブジェクト自体が使用されます。
独自リゾルバーのカタログを更新した場合は、`emojiRefreshListenable` または
`refreshListenable` に渡した `Listenable` を通知すると、表示中の絵文字を
再解決できます。`MfmEmojiConfig` は `autoSync` 完了後に自動で通知します。

手順は [高度なカスタム絵文字の設定](#高度なカスタム絵文字の設定)
を参照してください。

### 対応fn関数

| カテゴリ | fn名 | 構文例 | 対応状況 |
|---------|------|--------|:--------:|
| **サイズ** | x2 | `$[x2 text]` | ✅ |
| | x3 | `$[x3 text]` | ✅ |
| | x4 | `$[x4 text]` | ✅ |
| **変換** | flip | `$[flip text]` / `$[flip.h,v text]` | ✅ |
| | rotate | `$[rotate.deg=45 text]` | ✅ |
| | scale | `$[scale.x=2,y=2 text]` | ✅ |
| | position | `$[position.x=1,y=1 text]` | ✅ |
| **スタイル** | fg (前景色) | `$[fg.color=ff0000 text]` | ✅ |
| | bg (背景色) | `$[bg.color=00ff00 text]` | ✅ |
| | border | `$[border.color=0000ff text]` | ✅ |
| | font | `$[font.serif text]` | ✅ |
| **特殊** | blur | `$[blur text]` | ✅ |
| | ruby | `$[ruby 漢字 ふりがな]` | ✅ |
| | unixtime | `$[unixtime 1234567890]` | ✅ |
| **アニメーション** | tada | `$[tada text]` | ✅ |
|| | jelly | `$[jelly text]` | ✅ |
|| | twitch | `$[twitch text]` | ✅ |
|| | shake | `$[shake text]` | ✅ |
|| | spin | `$[spin text]` | ✅ |
|| | jump | `$[jump text]` | ✅ |
|| | bounce | `$[bounce text]` | ✅ |
|| | rainbow | `$[rainbow text]` | ✅ |
|| | sparkle | `$[sparkle text]` | ✅ |

`fg` / `bg` の `color` には、`#` なしの3・6桁のRGB、または4桁のRGBAの16進数を指定します。未指定・無効値は本家準拠で赤（`f00`）にフォールバックします。5桁は本家の正規表現には一致しますがCSSでは無効な色として宣言が破棄されるため、本実装でも色を付けません。

`tada` の150%は親に対する実フォントサイズとして適用され、アニメーション無効時も維持されます。
描画時の拡大だけでなく、テキストのレイアウトサイズも広がります。

`twitch` と `shake` は本家Misskeyと同じく、隣接する各キーフレーム区間に `ease` を適用します。

## インストール

Flutter 3.38.1 以上（Dart 3.10.0 以上）が必要です。`.fvmrc` の開発環境では
Flutter 3.38.7 を使用していますが、パッケージの対応下限は Flutter 3.38.1 です。

`pubspec.yaml` に依存関係を追加してください：

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.1
  misskey_client: ^1.0.0-beta.5
```

## クイックスタート

多くのケースでは、ヘルパー関数で簡単に絵文字対応を設定できます：

```dart
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

final serverUrl = Uri.parse('https://misskey.io');
final client = MisskeyClient(
  config: MisskeyClientConfig(baseUrl: serverUrl),
);

// 1回だけ初期化（例: main()）
final config = await MfmEmojiConfig.createDefault(client: client);

// アプリ内のどこでも利用可能
MfmText(
  text: ':custom_emoji: **こんにちは**',
  config: config,
)

// 後で、所有元の破棄時にリソースを解放
await config.dispose();
```

`createDefault` は、`MfmRenderConfig` としてそのまま使える
`MfmEmojiConfigHandle` を返します。このハンドルは永続ストアを所有するため、
不要になったら `dispose()` を呼んでください。ユニットテストでは
`emojiStoreFactory` にテストダブルを注入すると、Isarのネイティブライブラリを
ロードせずに構成処理を検証できます。`copyWith` で作成した設定は同じ
ライフサイクルを共有し、いずれかを破棄するとすべて破棄済みになります。
渡した `MisskeyClient` の所有権はアプリ側に残り、ハンドルと一緒には破棄されません。
永続絵文字ストアは `MisskeyClient.baseUrl` を用いてサーバーごとに分離されるため、
サーバーURLを別途指定する必要はありません。

より詳細な制御が必要な場合は、
[高度なカスタム絵文字の設定](#高度なカスタム絵文字の設定) を参照してください。

## 使い方

### 基本的な使い方

```dart
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// MFMテキストを直接レンダリング
MfmText(
  text: '**こんにちは** *世界* :emoji:',
)

// パース済みノードを渡す場合
MfmText(
  parsedNodes: parsedNodes,
)

// シンプルパーサーを使用（テキスト・絵文字のみ）
MfmText(
  text: 'こんにちは :wave:',
  simple: true,
)
```

`searchButtonLabel` はロケールから解決されたラベルと継承したラベルを上書きします。
設定済みまたは継承した上書きを解除し、現在のロケール（日本語は`検索`、
その他は`Search`）へ戻すには `useLocaleSearchButtonLabel` を指定します。
trueの場合は `searchButtonLabel` より優先され、ラベルはnullとして保持されます。

```dart
final localizedConfig = config.copyWith(
  useLocaleSearchButtonLabel: true,
);

MfmText(
  text: 'flutter Search',
  config: const MfmRenderConfig(
    useLocaleSearchButtonLabel: true,
  ),
)
```

### コールバックの設定

```dart
MfmText(
  text: '@user@example.com と #hashtag を https://example.com で確認',
  config: MfmRenderConfig(
    // リンクタップ時
    onLinkTap: (url) {
      launchUrl(Uri.parse(url));
    },
    // メンションタップ時
    onMentionTap: (acct) {
      navigateToUser(acct);
    },
    // ハッシュタグタップ時
    onHashtagTap: (tag) {
      navigateToHashtag(tag);
    },
    // 検索タップ時
    onSearchTap: (query) {
      performSearch(query);
    },
    // 任意: ローカライズされた検索ボタンラベルを上書き
    searchButtonLabel: '検索する',
    // コードブロックのコピー完了時（既定のSnackBarを置き換える）
    onCodeCopied: (code) {
      showCopyConfirmation(code);
    },
    // 任意: ローカライズされたコードコピー文言を上書き
    // （codeCopyTooltip はコピーボタンのアクセシビリティラベル）
    codeCopyTooltip: 'ソースをコピー',
    codeCopiedMessage: 'ソースをコピーしました',
  ),
)
```

`onCodeCopied` にはクリップボードへの書き込み完了後にコード全文が渡され、
既定の通知を置き換えます。省略時は `ScaffoldMessenger` の祖先がある場合だけ
SnackBarを表示し、ない場合は通知せずにコピーを完了します。
`codeCopiedMessage` はこの既定のSnackBarでのみ使用します。文言を上書きしない場合、
`codeCopyTooltip` / `codeCopiedMessage` は日本語ロケールで「コピー」/
「コードをコピーしました」、その他・ロケール未設定時は `Copy` /
`Copied to clipboard` になります。コピーボタンはMaterialウィジェットを使わずに
構成しているため `CupertinoApp` / `WidgetsApp` 配下でも動作します。
ツールチップは表示せず、`codeCopyTooltip` はコピーボタンの
アクセシビリティ（Semantics）ラベルとして機能します。

コードブロックは `baseTextStyle.fontSize`（ベーススタイル未設定時は周囲の
`DefaultTextStyle`）を継承し、フォントファミリーは `monospace` を維持します。
サイズ未指定時はシンタックスハイライターの既定値を使用します。

リモート投稿内のホスト省略メンションを解決するには、投稿者とローカル
インスタンスのホストを指定します。`onMentionTap`には解決後の完全なacctが
渡されます。どちらのホストも解決できない場合は、元のacctがそのまま渡されます。

```dart
MfmText(
  text: '@alice',
  config: MfmRenderConfig(
    author: const MfmAuthorContext(host: 'remote.example'),
    localHost: 'local.example',
    onMentionTap: navigateToUser,
  ),
)
```

### 高度なカスタム絵文字の設定

Misskeyサーバーのカスタム絵文字を表示するには、`misskey_emoji` ライブラリと連携します：

#### 1. （任意）依存関係の明示

import対象パッケージを直接依存に置きたい場合は追加してください：

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.1
  misskey_client: ^1.0.0-beta.5
  misskey_emoji: ^2.0.0-beta.1
  path_provider: ^2.1.5
```

#### 2. 絵文字リゾルバーの初期化

```dart
import 'package:flutter/foundation.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';

final baseUrl = Uri.parse('https://misskey.io');

// アプリのMisskeyクライアントを再利用
final client = MisskeyClient(
  config: MisskeyClientConfig(baseUrl: baseUrl),
);

// Misskeyクライアントを使用する絵文字ソースを作成
final emojiSource = MisskeyClientEmojiSource(client);

// 絵文字メタデータ保存用のIsarをオープン
final dir = await getApplicationDocumentsDirectory();
final isar = await openEmojiIsarForServer(baseUrl, directory: dir.path);

// 永続化カタログとリゾルバーを作成
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: IsarEmojiStore(isar, ownsIsar: true),
);
final resolver = MisskeyEmojiResolver(catalog);
final emojiRefreshNotifier = ValueNotifier(0);

// サーバーから絵文字メタデータを同期（起動時に1回実行）
await catalog.sync();
emojiRefreshNotifier.value++;
```

#### 3. MfmTextにemojiBuilderを設定

```dart
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

MfmText(
  text: ':custom_emoji: こんにちは！',
  config: MfmRenderConfig(
    // nameはコロン無しで渡される
    emojiBuilder: (name, context) => MfmCustomEmoji(
      name: name,
      resolver: resolver,
      cacheScope: resolver,
      size: context.fontSize * 2, // 表示上の高さ（2em）
      // vertical-align: middle相当（size / 2 - context.fontSize * 0.25）
      baselineOffset: context.fontSize * 0.75,
      maxWidth: 70.0, // 任意
      refreshListenable: emojiRefreshNotifier,
    ),
  ),
)
```

#### 4. リソースの解放

```dart
emojiRefreshNotifier.dispose();
await catalog.dispose();
```

#### 5. (任意) フォールバック表示のカスタマイズ

```dart
MfmCustomEmoji(
  name: 'emoji_name',
  resolver: resolver,
  cacheScope: resolver,
  fallbackBuilder: (context, name) => Text(
    '[$name]',
    style: const TextStyle(color: Colors.grey),
  ),
  loadingBuilder: (context) =>
      const Icon(Icons.hourglass_empty, size: 16),
)
```

### 絵文字ビルダーの描画文脈とUnicode画像

`emojiBuilder` / `unicodeEmojiBuilder` はともに引数が2つになりました。
`(name) => ...` を `(name, context) => ...`（固定Widgetなら `(name, _) => ...`）
へ移行してください。公開された不変の `MfmEmojiContext` は次の情報を持ちます。

- `fontSize`: サイズ関数・`tada`（150%）・`<small>`（80%）を反映した
  現在の実効フォントサイズ（論理px）。
- `scale`: x2/x3/x4/scale関数の累積倍率。`tada` と `<small>` では変わりません。
  advanced MFMが有効で基準14pxなら、x2は `(28, 2)`、x4は `(84, 4)`、
  `scale.x=3,y=3` は `(14, 3)`、`tada` は `(21, 1)` です。
  非等倍の `scale` は非負の値では本家と同じく `max(x, y)` を掛けるため、
  `scale.x=3,y=1` も `(14, 3)` になります。`enableAdvancedMfm: false` では、
  x2/x3/x4は `(14, 2)` / `(14, 3)` / `(14, 4)`、`scale.x=3,y=3` は
  `(14, 1)` になります。
- `useOriginalSize`: 本家と同じ `scale >= 2.5` による原寸画像利用のヒント。
  `misskey_emoji` 2.0.0-beta.1 は `EmojiImage.url` を1つだけ公開し、原寸／縮小版を
  区別しません。自動切替には依存パッケージ側の対応が必要なため、現時点では
  `MfmCustomEmoji.useOriginalSize` は追加していません。両URLを取得できる
  独自ビルダーでこのヒントを利用できます。advanced MFM無効時もx系の倍率は
  伝播するため、`$[x4 :emoji:]` はフォントを拡大しなくても
  `useOriginalSize: true` になり得ます。

両ビルダーの結果は `WidgetSpan` のalphabeticベースラインに揃えます。
任意のWidgetの画像高さ・下降量はレンダラーから判断できないため、ベースラインは
ビルダー側で指定してください。`MfmCustomEmoji.baselineOffset` は描画時の移動だけでなく、
ボックス下端より上にベースラインを設定し、行レイアウトにも下降量を反映します。

本家のカスタム絵文字は `vertical-align: middle`、つまりボックスの上下中心を
`baseline + x-height / 2` に合わせます。x-heightを0.5emと近似すると下降量は
`size / 2 - context.fontSize * 0.25` になり、`MfmEmojiConfig` は固定 `emojiSize`
指定時も含めてこの値を設定します。Flutterの `PlaceholderAlignment.middle` は
テキストのascent/descentの中点を基準にするためCSSの `middle` とは別物で、
レンダラーはbaseline揃えを維持し位置決めをビルダーに委ねています。
Unicode絵文字の画像は異なり、本家は高さ1.25emで `vertical-align: -0.25em`
なので、下降量は `context.fontSize * 0.25` です。

`unicodeEmojiBuilder` 未指定時はUnicode絵文字をネイティブの文字として描画します。
Twemoji等の画像を使う場合は `unicodeEmojiBuilder` を実装してください。
例えばUnicode文字列から画像URLを持つ `EmojiImage` を返す
`unicodeImageResolver` をアプリ側で用意すれば、次のように画像Widgetを再利用できます。

```dart
MfmRenderConfig(
  unicodeEmojiBuilder: (emoji, context) => MfmCustomEmoji(
    name: emoji,
    resolver: unicodeImageResolver, // アプリ側で用意したEmojiResolver
    size: context.fontSize * 1.25,
    baselineOffset: context.fontSize * 0.25,
  ),
)
```

本家のUnicode絵文字画像と同じ、高さ1.25em・`vertical-align: -0.25em` 相当に
なります。Twemojiアセットや
Unicode文字列から画像へのリゾルバーはパッケージに同梱していません。

### カスタムフォントの設定

`$[font.xxx]` 構文で使用されるフォントをカスタマイズ可能

```dart
import 'package:google_fonts/google_fonts.dart';

MfmText(
  text: r'$[font.monospace コンソール出力]',
  config: MfmRenderConfig(
    fontFamilyResolver: (fontType) {
      switch (fontType) {
        case 'monospace':
          return GoogleFonts.robotoMono().fontFamily;
        case 'serif':
          return GoogleFonts.notoSerif().fontFamily;
        case 'cursive':
          return GoogleFonts.dancingScript().fontFamily;
        default:
          return null; // デフォルトフォントを使用
      }
    },
  ),
)
```

### テキストスタイルのカスタマイズ

```dart
MfmText(
  text: 'スタイル付きテキスト',
  config: MfmRenderConfig(
    baseTextStyle: const TextStyle(
      fontSize: 16,
      color: Colors.black87,
      height: 1.5,
    ),
  ),
)
```

### 色のカスタマイズ

インラインコードの背景色をカスタマイズできます（数式には背景を付けません）：

```dart
MfmText(
  text: r'インライン`コード`と数式 \(x^2\)',
  config: MfmRenderConfig(
    // ライトモード用の背景色（デフォルト: #F5F5F5）
    inlineCodeBgColorLight: const Color(0xFFF0F0F0),
    // ダークモード用の背景色（デフォルト: #121212）
    inlineCodeBgColorDark: const Color(0xFF1A1A1A),
  ),
)
```

デフォルトの色はMisskey本家の実装に準拠しています：
- ライトモード: `Color(0xFFF5F5F5)` - 非常に薄いグレー
- ダークモード: `Color(0xFF121212)` - 非常に暗いグレー

### 高度なMFMの制御

`enableAdvancedMfm` はx2/x3/x4の視覚的拡大、`scale`、`position`、
および全9種類のMFMアニメーション関数を制御します。アニメーションは両フラグが
trueのときだけ有効です。読み取り専用の `config.useAnimation` ゲッターは
`enableAdvancedMfm && enableAnimation` を返します。既定値は両方trueです。

```dart
MfmText(
  text: r'$[x4 拡大] $[scale.x=3 変形] $[position.x=10 移動] $[spin 静止]',
  config: MfmRenderConfig(
    // サイズ・scale・positionの効果とMFMアニメーションを抑止
    enableAdvancedMfm: false,
    enableAnimation: true, // advanced MFMの設定が優先される
  ),
)
```

advanced MFM無効時、x2/x3/x4はフォントサイズを維持します（絵文字の描画文脈への
公称倍率伝播は継続）。`scale` は変形も倍率伝播も行わず、`position` は
`$[position 子要素]` としてリテラル表示されます。`flip`、`rotate`、その他の
スタイル関数は引き続き利用できます。

どちらかのフラグがfalseの場合、`spin`、`jump`、`bounce`、`shake`、`twitch`、
`jelly` はアニメーション用ラッパーなしで子要素を表示します。`tada` は150%の
フォントサイズを維持し、`rainbow` は静的グラデーション、`sparkle` はラッパーなしの
子要素になります。サイズ・scale・positionの効果を維持してMFMアニメーションだけを
止める場合は、`enableAnimation: false` のみを指定してください。
これらのフラグはMFMアニメーション関数を制御し、アニメーション絵文字画像の再生は
制御しません。OSの「視差効果を減らす」設定には自動連動しません。

### unixtime のローカライズ

`$[unixtime]` は [timeago](https://pub.dev/packages/timeago) パッケージを使用して相対時間を表示します。  
日本語表示にするには、アプリ起動時にロケールを設定してください。

```dart
import 'package:timeago/timeago.dart' as timeago;

void main() {
  // 日本語ロケールを設定
  timeago.setLocaleMessages('ja', timeago.JaMessages());
  timeago.setDefaultLocale('ja');
  
  runApp(MyApp());
}
```

## 設定

### MfmRenderConfig

| プロパティ | 型 | デフォルト | 説明 |
|-----------|------|---------|------|
| `baseTextStyle` | `TextStyle?` | null | ベースのテキストスタイル |
| `enableAdvancedMfm` | `bool` | true | x2/x3/x4の視覚的拡大、scale/positionの効果、MFMアニメーションを有効化 |
| `enableAnimation` | `bool` | true | advanced MFM有効時のMFMアニメーションを有効化 |
| `useAnimation` | `bool`（getter） | true（導出値） | 読み取り専用の実効判定: `enableAdvancedMfm && enableAnimation` |
| `enableNyaize` | `bool` | false | nyaize（猫語）変換をテキストノードに対して有効化 |
| `emojiBuilder` | `Widget Function(String, MfmEmojiContext)?` | null | カスタム絵文字ビルダー |
| `unicodeEmojiBuilder` | `Widget Function(String, MfmEmojiContext)?` | null | Unicode絵文字ビルダー |
| `onLinkTap` | `void Function(String)?` | null | リンクタップコールバック |
| `onMentionTap` | `void Function(String)?` | null | メンションタップコールバック |
| `onHashtagTap` | `void Function(String)?` | null | ハッシュタグタップコールバック |
| `onSearchTap` | `void Function(String)?` | null | 検索タップコールバック |
| `onCodeCopied` | `void Function(String)?` | null | コードコピー完了コールバック。指定時は既定のSnackBarを置換し、未指定時はScaffoldMessengerの祖先がある場合のみ通知 |
| `codeCopyTooltip` | `String?` | 現在のロケール | コードコピーボタンのアクセシビリティラベルの上書き（日本語は`コピー`、その他は`Copy`） |
| `codeCopiedMessage` | `String?` | 現在のロケール | コピー完了時の既定のSnackBar文言上書き（日本語は`コードをコピーしました`、その他は`Copied to clipboard`） |
| `author` | `MfmAuthorContext?` | null | ホスト依存の描画に使用する投稿者情報 |
| `localHost` | `String?` | null | ホスト解決のフォールバックに使用するローカルMisskeyホスト |
| `searchButtonLabel` | `String?` | 現在のロケール | 検索ボタンのラベル上書き（日本語は`検索`、その他は`Search`） |
| `useLocaleSearchButtonLabel` | `bool` | false | 設定済みまたは継承した検索ラベルを解除し、現在のロケールから解決 |
| `fontFamilyResolver` | `String? Function(String)?` | null | フォントファミリー解決関数 |

`copyWith`では、`author`と`localHost`の引数を省略または`null`にすると
現在値を維持します。値を削除するには`clearAuthor: true`または
`clearLocalHost: true`を指定します。置換値と対応するclearフラグを同時に
指定した場合は`ArgumentError`を投げます。

## 技術的な注意事項

### テキスト選択について

本ライブラリは視覚的な再現性を優先している為、レンダリング後のテキスト選択には非対応です。  
テキストのコピー機能が必要な場合は、アプリ側で元のMFMテキスト（生データ）をコピーする機能を別途実装する必要があります。

### スケールの制限

`scale` fn関数は最大5倍に制限されています。これはMisskey本家と同様の制限です。
`enableAdvancedMfm: false` の場合、描画時の変形も `MfmEmojiContext.scale` への
倍率伝播も行いません。外側のx系関数から継承した倍率はそのまま維持します。
静的な子要素には `TextSpan` を使い、本家の空の `inline-block` spanによる
行レイアウトの境界までは再現しません。

### サイズ関数の入れ子

`x2`、`x3`、`x4`は、異なる種類の組み合わせも含めて共通のネスト深さを使い、Misskey本家と同じ動作をします。advanced MFM有効時、以下の割合はいずれも親の実効フォントサイズに対する相対値です。

- 1階層目: `x2`は200%、`x3`は400%、`x4`は600%。
- 2階層目: 内側の関数自身のzoom値を使い、`zoom / 2 + 50%`（`x2`: 150%、`x3`: 250%、`x4`: 350%）。
- 3階層目以降: 100%（追加の拡大を無効化し、親のフォントサイズを継承）。

ベースフォントサイズが14pxの場合、`$[x2 $[x2 A]]`の外側は28px、内側は42pxになります。`$[x2 $[x3 A]]`の内側は70pxです。3階層目にサイズ関数を追加しても、それ以上は拡大しません。太字、アニメーション関数、`scale`など他のノードは、このネスト深さを増やさずに引き継ぎます。

`enableAdvancedMfm: false` の場合、x2/x3/x4はどの階層でもフォントサイズを
変更しません。ネスト深さと公称倍率（2/3/4）は、3階層目以降も伝播します。
この倍率はCSSのフォントサイズ割合とは別系統です。例えば `$[x2 $[x3 A]]` は
基準14pxのままですが、子要素へ渡すscaleは6です。`enableAnimation` だけを
無効化しても、サイズ関数の動作は変わりません。

## 追加情報

- [APIドキュメント](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM仕様](https://misskey-hub.net/ja/docs/for-users/features/mfm/)

## ライセンス

3-Clause BSD License - [LICENSE](LICENSE) を参照
