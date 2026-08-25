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
| | 小文字 | `<small>small</small>` | ✅ |
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

*数式は現在プレーンテキストとして表示されます。将来的に数式レンダリング対応予定。

### 追加の注意事項

**未実装の機能:**
- **数式レンダリング**: LaTeX数式はプレーンテキストで表示されます。KaTeXなどのライブラリを使った完全な数式レンダリングは将来のリリースで対応予定です。
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
- 高さを固定し、元画像のアスペクト比を維持した表示
- 読み込み済みアスペクト比の再利用によるプレースホルダのレイアウト安定化
- 未取得時のフォールバック表示
- アニメーション絵文字（GIF/APNG/WebP）に対応

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

## インストール

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
  ),
)
```

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
    emojiBuilder: (name) => MfmCustomEmoji(
      name: name,
      resolver: resolver,
      cacheScope: resolver,
      size: 24.0, // 表示上の高さ
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

インラインコードや数式の背景色をカスタマイズできます：

```dart
MfmText(
  text: 'インライン`コード`と数式 $x^2$',
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

`position` などの高度なfn関数はセキュリティ上の理由から制御できます。  

```dart
MfmText(
  text: r'$[position.x=10 移動]',
  config: MfmRenderConfig(
    // positionなどの高度な機能を無効化
    enableAdvancedMfm: false,
  ),
)
```

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
| `enableAdvancedMfm` | `bool` | true | position等の高度な機能を有効化 |
| `enableAnimation` | `bool` | true | アニメーションを有効化（今後実装） |
| `enableNyaize` | `bool` | false | nyaize（猫語）変換をテキストノードに対して有効化 |
| `emojiBuilder` | `Widget Function(String)?` | null | カスタム絵文字ビルダー |
| `unicodeEmojiBuilder` | `Widget Function(String)?` | null | Unicode絵文字ビルダー |
| `onLinkTap` | `void Function(String)?` | null | リンクタップコールバック |
| `onMentionTap` | `void Function(String)?` | null | メンションタップコールバック |
| `onHashtagTap` | `void Function(String)?` | null | ハッシュタグタップコールバック |
| `onSearchTap` | `void Function(String)?` | null | 検索タップコールバック |
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

## 追加情報

- [APIドキュメント](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM仕様](https://misskey-hub.net/ja/docs/for-users/features/mfm/)

## ライセンス

3-Clause BSD License - [LICENSE](LICENSE) を参照
