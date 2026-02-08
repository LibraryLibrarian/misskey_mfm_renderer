# misskey_mfm_renderer

[![pub package](https://img.shields.io/pub/v/misskey_mfm_renderer.svg)](https://pub.dev/packages/misskey_mfm_renderer)

A Flutter widget library for rendering Misskey MFM (Misskey Flavored Markdown) content.

## About MFM and Custom Emoji

MFM (Misskey Flavored Markdown) is Misskey's markup language. Custom emoji
syntax (`:emoji_name:`) is a standard part of the MFM specification, not an
optional feature. This package provides complete MFM rendering including
built-in custom emoji support through the `misskey_emoji` library.

### Why misskey_emoji is included

Custom emoji rendering is a core MFM feature. To provide a complete MFM
renderer out of the box, this package includes `misskey_emoji` as a dependency.
This allows you to render all MFM syntax without requiring additional
integration work.

[日本語](#日本語)

## Features

### Supported Node Types

| Category | Element | Syntax Example | Status |
|----------|---------|----------------|:------:|
| **Text Formatting** | Bold | `**bold**` | ✅ |
| | Italic | `*italic*` / `<i>italic</i>` | ✅ |
| | Strike | `~~strike~~` | ✅ |
| | Small | `<small>small</small>` | ✅ |
| | Plain | `<plain>text</plain>` | ✅ |
| **Block Elements** | Quote | `> quote` | ✅ |
| | Center | `<center>text</center>` | ✅ |
| | Code Block | ` ```code``` ` | ✅ |
| | Inline Code | `` `code` `` | ✅ |
| | Math Block | `\[ formula \]` | ✅* |
| | Math Inline | `\( formula \)` | ✅* |
| **Links & References** | URL | `https://example.com` | ✅ |
| | Link | `[label](url)` | ✅ |
| | Mention | `@user@host` | ✅ |
| | Hashtag | `#hashtag` | ✅ |
| | Search | `keyword Search` | ✅ |
| **Emoji** | Custom Emoji | `:emoji_name:` | ✅ |
| | Unicode Emoji | `😀` | ✅ |

*Math formulas are currently displayed as plain text. Math rendering support is planned for future releases.

### Custom Emoji Support

Custom emoji rendering is supported through integration with the `misskey_emoji` library.

**Status**: ✅ Fully supported with `misskey_emoji` integration

**Features**:
- Automatic emoji metadata resolution
- Image caching with `cached_network_image`
- Fallback display for unavailable emojis
- Animated emoji support (GIF, APNG, WebP)

See [Advanced Custom Emoji Configuration](#advanced-custom-emoji-configuration)
for setup instructions.

### Supported fn Functions

| Category | fn Name | Syntax Example | Status |
|----------|---------|----------------|:------:|
| **Size** | x2 | `$[x2 text]` | ✅ |
| | x3 | `$[x3 text]` | ✅ |
| | x4 | `$[x4 text]` | ✅ |
| **Transform** | flip | `$[flip text]` / `$[flip.h,v text]` | ✅ |
| | rotate | `$[rotate.deg=45 text]` | ✅ |
| | scale | `$[scale.x=2,y=2 text]` | ✅ |
| | position | `$[position.x=1,y=1 text]` | ✅ |
| **Style** | fg (foreground) | `$[fg.color=ff0000 text]` | ✅ |
| | bg (background) | `$[bg.color=00ff00 text]` | ✅ |
| | border | `$[border.color=0000ff text]` | ✅ |
| | font | `$[font.serif text]` | ✅ |
| **Special** | blur | `$[blur text]` | ✅ |
| | ruby | `$[ruby kanji furigana]` | ✅ |
| | unixtime | `$[unixtime 1234567890]` | ✅ |
| **Animation** | tada, jelly, twitch, shake, spin, jump, bounce, rainbow, sparkle | - | 🚧 |

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.0.1
```

## Quick Start

For most use cases, use the helper function to quickly set up emoji support:

```dart
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// One-time setup (e.g., in main())
final config = await MfmEmojiConfig.quickSetup(
  serverUrl: 'https://misskey.io',
);

// Use anywhere in your app
MfmText(
  text: ':custom_emoji: **Hello** World!',
  config: config,
)
```

For advanced customization, see
[Advanced Custom Emoji Configuration](#advanced-custom-emoji-configuration).

## Usage

### Basic Usage

```dart
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// Render MFM text directly
MfmText(
  text: '**Hello** *World* :emoji:',
)

// Pass pre-parsed nodes
MfmText(
  parsedNodes: parsedNodes,
)

// Use simple parser (text and emoji only)
MfmText(
  text: 'Hello :wave:',
  simple: true,
)
```

### Callbacks Configuration

```dart
MfmText(
  text: 'Check @user@example.com and #hashtag at https://example.com',
  config: MfmRenderConfig(
    // On link tap
    onLinkTap: (url) {
      launchUrl(Uri.parse(url));
    },
    // On mention tap
    onMentionTap: (acct) {
      navigateToUser(acct);
    },
    // On hashtag tap
    onHashtagTap: (tag) {
      navigateToHashtag(tag);
    },
    // On search tap
    onSearchTap: (query) {
      performSearch(query);
    },
  ),
)
```

### Advanced Custom Emoji Configuration

To display custom emojis from a Misskey server, integrate the `misskey_emoji` library:

#### 1. (Optional) Add Direct Dependencies

If your project enforces direct dependencies for imported packages, add:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.0.1
  misskey_api_core: ^1.0.0
  path_provider: ^2.1.5
```

#### 2. Initialize Emoji Resolver

```dart
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';

final baseUrl = Uri.parse('https://misskey.io');

// Create HTTP client for Misskey API
final httpClient = MisskeyHttpClient(
  config: MisskeyApiConfig(baseUrl: baseUrl),
);

// Create emoji API client
final emojiApi = MisskeyEmojiApi(httpClient);

// Open Isar for emoji metadata storage
final dir = await getApplicationDocumentsDirectory();
final isar = await openEmojiIsarForServer(baseUrl, directory: dir.path);

// Create persistent catalog and resolver
final catalog = PersistentEmojiCatalog(
  api: emojiApi,
  store: IsarEmojiStore(isar),
  meta: MetaClient(httpClient),
);
final resolver = MisskeyEmojiResolver(catalog);

// Sync emoji metadata from server (run once at app startup)
await catalog.sync();
```

#### 3. Configure MfmText with Emoji Builder

```dart
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

MfmText(
  text: ':custom_emoji: Hello, world!',
  config: MfmRenderConfig(
    // name is passed without colons
    emojiBuilder: (name) => MfmCustomEmoji(
      name: name,
      resolver: resolver,
      size: 24.0,
    ),
  ),
)
```

#### 4. (Optional) Customize Fallback Display

```dart
MfmCustomEmoji(
  name: 'emoji_name',
  resolver: resolver,
  fallbackBuilder: (context, name) => Text(
    '[$name]',
    style: const TextStyle(color: Colors.grey),
  ),
  loadingBuilder: (context) =>
      const Icon(Icons.hourglass_empty, size: 16),
)
```

### Custom Font Configuration

Customize fonts used in `$[font.xxx]` syntax:

```dart
import 'package:google_fonts/google_fonts.dart';

MfmText(
  text: r'$[font.monospace console output]',
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
          return null; // Use default font
      }
    },
  ),
)
```

### Text Style Customization

```dart
MfmText(
  text: 'Styled text',
  config: MfmRenderConfig(
    baseTextStyle: const TextStyle(
      fontSize: 16,
      color: Colors.black87,
      height: 1.5,
    ),
  ),
)
```

### Color Customization

Customize background colors for inline code and math formulas:

```dart
MfmText(
  text: 'Inline `code` and math $x^2$',
  config: MfmRenderConfig(
    // Custom background color for light mode (default: #F5F5F5)
    inlineCodeBgColorLight: const Color(0xFFF0F0F0),
    // Custom background color for dark mode (default: #121212)
    inlineCodeBgColorDark: const Color(0xFF1A1A1A),
  ),
)
```

The default colors are based on Misskey's official implementation:
- Light mode: `Color(0xFFF5F5F5)` - Very light gray
- Dark mode: `Color(0xFF121212)` - Very dark gray

### Advanced MFM Control

Control advanced fn functions like `position` for security reasons:

```dart
MfmText(
  text: r'$[position.x=10 moved]',
  config: MfmRenderConfig(
    // Disable advanced features like position
    enableAdvancedMfm: false,
  ),
)
```

### Localizing unixtime

`$[unixtime]` uses the [timeago](https://pub.dev/packages/timeago) package for relative time display. Set locale at app startup for localization:

```dart
import 'package:timeago/timeago.dart' as timeago;

void main() {
  // Set Japanese locale
  timeago.setLocaleMessages('ja', timeago.JaMessages());
  timeago.setDefaultLocale('ja');
  
  runApp(MyApp());
}
```

## Configuration

### MfmRenderConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `baseTextStyle` | `TextStyle?` | null | Base text style |
| `enableAdvancedMfm` | `bool` | true | Enable advanced features like position |
| `enableAnimation` | `bool` | true | Enable animations (for future use) |
| `enableNyaize` | `bool` | false | Enable nyaize transformation (for future use) |
| `emojiBuilder` | `Widget Function(String)?` | null | Custom emoji builder |
| `unicodeEmojiBuilder` | `Widget Function(String)?` | null | Unicode emoji builder |
| `onLinkTap` | `void Function(String)?` | null | Link tap callback |
| `onMentionTap` | `void Function(String)?` | null | Mention tap callback |
| `onHashtagTap` | `void Function(String)?` | null | Hashtag tap callback |
| `onSearchTap` | `void Function(String)?` | null | Search tap callback |
| `fontFamilyResolver` | `String? Function(String)?` | null | Font family resolver function |

## Technical Notes

### Text Selection

This library prioritizes visual fidelity and does not support text selection after rendering. If you need copy functionality, implement it separately using the original MFM text (raw data) at the app level.

### Scale Limits

The `scale` fn function is limited to a maximum of 5x. This is the same security limitation as Misskey's official implementation.

### Nested Size Functions

When `x2`, `x3`, `x4` are nested, the effect is halved, matching Misskey's official behavior.

## Additional information

- [API Documentation](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM Specification](https://misskey-hub.net/en/docs/for-users/features/mfm/)

## License

3-Clause BSD License - see [LICENSE](LICENSE)

---

# 日本語

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

### カスタム絵文字対応

`misskey_emoji` ライブラリとの連携により、カスタム絵文字表示に対応しています。

**対応状況**: ✅ `misskey_emoji` 連携で完全対応

**特徴**:
- 絵文字メタデータの自動解決
- `cached_network_image` による画像キャッシュ
- 未取得時のフォールバック表示
- アニメーション絵文字（GIF/APNG/WebP）に対応

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
| **アニメーション** | tada, jelly, twitch, shake, spin, jump, bounce, rainbow, sparkle | - | 🚧 |

## インストール

`pubspec.yaml` に依存関係を追加してください：

```yaml
dependencies:
  misskey_mfm_renderer: ^0.0.1
```

## クイックスタート

多くのケースでは、ヘルパー関数で簡単に絵文字対応を設定できます：

```dart
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// 1回だけ初期化（例: main()）
final config = await MfmEmojiConfig.quickSetup(
  serverUrl: 'https://misskey.io',
);

// アプリ内のどこでも利用可能
MfmText(
  text: ':custom_emoji: **こんにちは**',
  config: config,
)
```

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
  ),
)
```

### 高度なカスタム絵文字の設定

Misskeyサーバーのカスタム絵文字を表示するには、`misskey_emoji` ライブラリと連携します：

#### 1. （任意）依存関係の明示

import対象パッケージを直接依存に置きたい場合は追加してください：

```yaml
dependencies:
  misskey_mfm_renderer: ^0.0.1
  misskey_api_core: ^1.0.0
  path_provider: ^2.1.5
```

#### 2. 絵文字リゾルバーの初期化

```dart
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';

final baseUrl = Uri.parse('https://misskey.io');

// Misskey API用のHTTPクライアントを作成
final httpClient = MisskeyHttpClient(
  config: MisskeyApiConfig(baseUrl: baseUrl),
);

// 絵文字APIクライアントを作成
final emojiApi = MisskeyEmojiApi(httpClient);

// 絵文字メタデータ保存用のIsarをオープン
final dir = await getApplicationDocumentsDirectory();
final isar = await openEmojiIsarForServer(baseUrl, directory: dir.path);

// 永続化カタログとリゾルバーを作成
final catalog = PersistentEmojiCatalog(
  api: emojiApi,
  store: IsarEmojiStore(isar),
  meta: MetaClient(httpClient),
);
final resolver = MisskeyEmojiResolver(catalog);

// サーバーから絵文字メタデータを同期（起動時に1回実行）
await catalog.sync();
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
      size: 24.0,
    ),
  ),
)
```

#### 4. (任意) フォールバック表示のカスタマイズ

```dart
MfmCustomEmoji(
  name: 'emoji_name',
  resolver: resolver,
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
| `enableNyaize` | `bool` | false | nyaize変換を有効化（今後実装） |
| `emojiBuilder` | `Widget Function(String)?` | null | カスタム絵文字ビルダー |
| `unicodeEmojiBuilder` | `Widget Function(String)?` | null | Unicode絵文字ビルダー |
| `onLinkTap` | `void Function(String)?` | null | リンクタップコールバック |
| `onMentionTap` | `void Function(String)?` | null | メンションタップコールバック |
| `onHashtagTap` | `void Function(String)?` | null | ハッシュタグタップコールバック |
| `onSearchTap` | `void Function(String)?` | null | 検索タップコールバック |
| `fontFamilyResolver` | `String? Function(String)?` | null | フォントファミリー解決関数 |

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