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

[日本語](README.ja.md)

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

### Additional Notes

**Not Yet Implemented:**
- **Math Rendering**: LaTeX formulas are displayed as plain text. Full math rendering with KaTeX or similar library is planned for future releases.
- **Font Limitations**: Some font types in `$[font.xxx]` syntax (specifically `emoji` and `math`) fall back to default fonts due to platform limitations.

**Nyaize (Cat-speak transformation)**: Text transformation feature is supported via `enableNyaize`.
Equivalent to Misskey's cat mode, it converts text in text nodes to cat-speak (ja-JP / en-US / ko-KR).
Subtrees of `link` / `quote` / `plain` are excluded from transformation (matching Misskey's upstream behavior).
The `nyaize(String)` pure function is also exposed publicly.

### Custom Emoji Support

Custom emoji rendering is supported through integration with the `misskey_emoji` library.

**Status**: ✅ Fully supported with `misskey_emoji` integration

**Features**:
- Automatic emoji metadata resolution
- Image caching with `cached_network_image`
- Aspect-ratio-preserving rendering with a fixed display height
- Reuse of decoded aspect ratios to stabilize loading placeholders
- Fallback display for unavailable emojis
- Animated emoji support (GIF, APNG, WebP)

Custom emojis use their natural width by default. To cap very wide emojis,
pass `emojiMaxWidth` to `MfmEmojiConfig` or `maxWidth` to `MfmCustomEmoji`.
If an image ratio is already available in application metadata, pass it to
`MfmCustomEmoji.aspectRatio` to stabilize the very first loading layout too.
When the ratio is unknown, the first load intentionally starts at zero width
and can still reflow; an exact initial width requires `aspectRatio`.
If a resolver closure is recreated during builds, pass a stable value to
`MfmCustomEmoji.cacheScope`. Widgets sharing a scope must resolve the same name
to the same URL for a given catalog state, so include every captured host,
account, or other input that affects the result, for example
`cacheScope: (resolverOwner, preferredHost, accountId)`.
The scope only controls cached layout hints; a changed resolver is still run
again. When omitted, the resolver function object itself is used.
When a custom resolver's catalog changes, pass a `Listenable` through
`emojiRefreshListenable` or `refreshListenable` and notify it to re-resolve
visible emojis. `MfmEmojiConfig` does this automatically after `autoSync`.

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
| **Animation** | tada | `$[tada text]` | ✅ |
|| | jelly | `$[jelly text]` | ✅ |
|| | twitch | `$[twitch text]` | ✅ |
|| | shake | `$[shake text]` | ✅ |
|| | spin | `$[spin text]` | ✅ |
|| | jump | `$[jump text]` | ✅ |
|| | bounce | `$[bounce text]` | ✅ |
|| | rainbow | `$[rainbow text]` | ✅ |
|| | sparkle | `$[sparkle text]` | ✅ |

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.1
  misskey_client: ^1.0.0-beta.5
```

## Quick Start

For most use cases, use the helper function to quickly set up emoji support:

```dart
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

final serverUrl = Uri.parse('https://misskey.io');
final client = MisskeyClient(
  config: MisskeyClientConfig(baseUrl: serverUrl),
);

// One-time setup (e.g., in main())
final config = await MfmEmojiConfig.createDefault(client: client);

// Use anywhere in your app
MfmText(
  text: ':custom_emoji: **Hello** World!',
  config: config,
)

// Later, release resources when the owner is disposed.
await config.dispose();
```

`createDefault` returns an `MfmEmojiConfigHandle`, which can be
used anywhere an `MfmRenderConfig` is accepted. The handle owns its persistent
store and must be disposed. Unit tests can pass `emojiStoreFactory` to inject a
test double without loading Isar's native library. Configurations created with
`copyWith` share the same lifecycle; disposing any copy disposes them all.
The provided `MisskeyClient` remains owned by the application and is not
disposed with the handle. The persistent emoji store is partitioned per server
using `MisskeyClient.baseUrl`, so no separate server URL argument is needed.

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

`searchButtonLabel` overrides both the locale-derived label and an inherited
label. To remove an existing or inherited override and return to the current
locale (`検索` for Japanese, `Search` otherwise), set
`useLocaleSearchButtonLabel`. When true, it takes precedence over
`searchButtonLabel` and stores the label as `null`:

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
    // Optional: override the localized search button label
    searchButtonLabel: 'Find',
  ),
)
```

For hostless mentions in remote posts, provide the author and local instance
hosts. `onMentionTap` then receives the resolved full acct. When neither host
can be resolved, the original acct is passed through unchanged.

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

### Advanced Custom Emoji Configuration

To display custom emojis from a Misskey server, integrate the `misskey_emoji` library:

#### 1. (Optional) Add Direct Dependencies

If your project enforces direct dependencies for imported packages, add:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.1
  misskey_client: ^1.0.0-beta.5
  misskey_emoji: ^2.0.0-beta.1
  path_provider: ^2.1.5
```

#### 2. Initialize Emoji Resolver

```dart
import 'package:flutter/foundation.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';

final baseUrl = Uri.parse('https://misskey.io');

// Reuse the application's Misskey client
final client = MisskeyClient(
  config: MisskeyClientConfig(baseUrl: baseUrl),
);

// Create an emoji source backed by the Misskey client
final emojiSource = MisskeyClientEmojiSource(client);

// Open Isar for emoji metadata storage
final dir = await getApplicationDocumentsDirectory();
final isar = await openEmojiIsarForServer(baseUrl, directory: dir.path);

// Create persistent catalog and resolver
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: IsarEmojiStore(isar, ownsIsar: true),
);
final resolver = MisskeyEmojiResolver(catalog);
final emojiRefreshNotifier = ValueNotifier(0);

// Sync emoji metadata from server (run once at app startup)
await catalog.sync();
emojiRefreshNotifier.value++;
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
      cacheScope: resolver,
      size: 24.0, // Display height
      maxWidth: 70.0, // Optional
      refreshListenable: emojiRefreshNotifier,
    ),
  ),
)
```

#### 4. Release Resources

```dart
emojiRefreshNotifier.dispose();
await catalog.dispose();
```

#### 5. (Optional) Customize Fallback Display

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
| `enableNyaize` | `bool` | false | Enable nyaize (cat-speak) transformation on text nodes |
| `emojiBuilder` | `Widget Function(String)?` | null | Custom emoji builder |
| `unicodeEmojiBuilder` | `Widget Function(String)?` | null | Unicode emoji builder |
| `onLinkTap` | `void Function(String)?` | null | Link tap callback |
| `onMentionTap` | `void Function(String)?` | null | Mention tap callback |
| `onHashtagTap` | `void Function(String)?` | null | Hashtag tap callback |
| `onSearchTap` | `void Function(String)?` | null | Search tap callback |
| `author` | `MfmAuthorContext?` | null | Author context used for host-dependent rendering |
| `localHost` | `String?` | null | Local Misskey host used as a host-resolution fallback |
| `searchButtonLabel` | `String?` | current locale | Search button label override (`検索` for Japanese, `Search` otherwise) |
| `useLocaleSearchButtonLabel` | `bool` | false | Clear a configured or inherited search label and resolve it from the current locale |
| `fontFamilyResolver` | `String? Function(String)?` | null | Font family resolver function |

`copyWith` preserves the current `author` and `localHost` when their nullable
arguments are omitted or `null`. Set `clearAuthor: true` or
`clearLocalHost: true` to remove a value. Providing a replacement value and its
corresponding clear flag in the same call throws `ArgumentError`.

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
