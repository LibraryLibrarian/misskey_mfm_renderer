# misskey_mfm_renderer

[![pub package](https://img.shields.io/pub/v/misskey_mfm_renderer.svg)](https://pub.dev/packages/misskey_mfm_renderer)

A Flutter widget library for rendering Misskey MFM (Misskey Flavored Markdown) content.

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

### Custom Emoji Configuration

```dart
MfmText(
  text: 'Hello :custom_emoji:',
  config: MfmRenderConfig(
    // Custom emoji builder (for :name: format)
    emojiBuilder: (name) {
      final url = emojiResolver.resolve(name);
      return CachedNetworkImage(
        imageUrl: url,
        height: 24,
        width: 24,
      );
    },
    // Unicode emoji builder (for custom rendering)
    unicodeEmojiBuilder: (emoji) {
      return Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      );
    },
  ),
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

### カスタム絵文字の設定

```dart
MfmText(
  text: 'こんにちは :custom_emoji:',
  config: MfmRenderConfig(
    // カスタム絵文字（:name: 形式）のビルダー
    emojiBuilder: (name) {
      final url = emojiResolver.resolve(name);
      return CachedNetworkImage(
        imageUrl: url,
        height: 24,
        width: 24,
      );
    },
    // Unicode絵文字のビルダー（カスタム表示が必要な場合）
    unicodeEmojiBuilder: (emoji) {
      return Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      );
    },
  ),
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