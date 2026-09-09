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
| | Small (0.8× inherited font size, 0.7× opacity) | `<small>small</small>` | ✅ |
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

*Both math syntaxes display formulas as unadorned monospace text, matching upstream Misskey's plain `<code>` output rather than rendering LaTeX. They inherit the surrounding text style without a background, padding, or forced block layout; line breaks in parsed text nodes are preserved. The current parser consumes the newline immediately after a math block, and the renderer does not insert a replacement.

### Additional Notes

**Inline code**: Inherits the surrounding text size, color, and weight, uses monospace fonts, uses the active `MfmColorScheme.bg`, and scales its padding (0.1em) and border radius (0.3em) with the inherited font size.

**Small text**: Nested `<small>` tags multiply the inherited font size by 0.8 and dim content by 0.7 per level.
Dimming applies to the inherited color's alpha as well as to fixed colors (`$[fg ...]`, link colors) and widgets such as emoji, so a child color override cannot cancel the dimming.

**Quote**: `> quote` occupies a full line with an 8px margin on all sides, padding of 6px top/bottom and 12px left (0px right), and a 3px left border, matching Misskey's `QUOTE_STYLE`. Text and border use the active `MfmColorScheme.fg` with cumulative opacity applied; each quote and `<small>` level multiplies the original alpha by 0.7. This quote color is independent of `baseTextStyle` and `DefaultTextStyle`.
Block display requires a parent with bounded width (for example, `SizedBox(width: 300)` or `Expanded` in a `Row`). With unbounded width, such as a non-`Expanded` child of a `Row`, quotes use their natural width and are not guaranteed to occupy a separate line. No extra boundary newlines are inserted. CSS margin collapsing between adjacent quotes and the handling of extra newlines around blocks are not fully reproduced.

**Literal fn fallback**: Unknown fn names, `font` without a valid family, and `position` with `enableAdvancedMfm: false` are displayed as `$[name content]` (arguments omitted), preserving child formatting, matching Misskey.

**Not Yet Implemented:**
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
- Aspect-ratio-preserving rendering with a context-relative display height (2em by default)
- Reuse of decoded aspect ratios to stabilize loading placeholders
- Fallback display for unavailable emojis
- Animated emoji support (GIF, APNG, WebP)

`MfmEmojiConfig.createDefault` and `fromResolver` use a height of **2em**
(`context.fontSize * 2`) by default: a 14px font produces a 28px emoji, and
`$[x4 :emoji:]` produces a 168px emoji. This replaces the previous 24px default.
The `emojiSize` parameter now defaults to `null`; pass `emojiSize: 24` to keep
an explicit fixed height. The low-level `MfmCustomEmoji.size` default remains
24px when constructed directly. Size functions, `tada`, and `<small>` adjust
the effective font size; `scale` applies its existing paint transform without
changing that font size (do not multiply the height by `context.scale` again).

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

For `fg` / `bg`, use 3- or 6-digit RGB or 4-digit RGBA hexadecimal `color` values without `#`. Missing or invalid values fall back to red (`f00`), matching Misskey. Five-digit values pass Misskey's regex but are invalid CSS colors that browsers drop, so no color is applied here either.

`tada` applies 150% of the parent's actual font size, including when animations
are disabled. This enlarges the text's layout size, not just its painted size.

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
    // After a code block is copied (replaces the default SnackBar)
    onCodeCopied: (code) {
      showCopyConfirmation(code);
    },
    // Optional: override the localized code copy labels
    // (codeCopyTooltip is the copy button's accessibility label)
    codeCopyTooltip: 'Copy source',
    codeCopiedMessage: 'Source copied',
  ),
)
```

`onCodeCopied` receives the full code after the clipboard write completes and
replaces the built-in notification. If omitted, a SnackBar is shown only when a
`ScaffoldMessenger` ancestor is available; otherwise copying completes silently.
`codeCopiedMessage` is used only by that built-in SnackBar. When no override is
provided, `codeCopyTooltip` / `codeCopiedMessage` use `コピー` /
`コードをコピーしました` for Japanese and `Copy` / `Copied to clipboard` for
other or unavailable locales. The copy button is built without Material
widgets so it also works under `CupertinoApp` / `WidgetsApp`; no tooltip is
shown and `codeCopyTooltip` serves as the button's accessibility (semantics)
label.

Code blocks inherit `baseTextStyle.fontSize` (or the surrounding
`DefaultTextStyle` when no base style is configured), use the Consolas / Monaco /
Andale Mono / Ubuntu Mono / monospace fallback list, and apply that size as 1em
padding. They use a 1px theme divider border and 8px radius. Blocks without a
language use the selected MFM scheme's `bg` / `fg`; highlighted blocks retain
the highlight theme root background, falling back to the scheme `bg` only when
the theme has no root background. If the size is unspecified, the highlighter's
default is used.

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
    emojiBuilder: (name, context) => MfmCustomEmoji(
      name: name,
      resolver: resolver,
      cacheScope: resolver,
      size: context.fontSize * 2, // 2em display height
      // vertical-align: middle, i.e. size / 2 - context.fontSize * 0.25
      baselineOffset: context.fontSize * 0.75,
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

### Emoji Builder Context and Unicode Images

Both `emojiBuilder` and `unicodeEmojiBuilder` now take two arguments. Migrate
`(name) => ...` to `(name, context) => ...` (or `(name, _) => ...` for a fixed
widget). The publicly exported immutable `MfmEmojiContext` contains:

- `fontSize`: the current effective font size in logical pixels, including
  size functions, `tada` (150%), and `<small>` (80%).
- `scale`: the cumulative x2/x3/x4/scale-function multiplier. `tada` and
  `<small>` do not change it. For a 14px base, x2 gives `(28, 2)`, x4 gives
  `(84, 6)`, `scale.x=3,y=3` gives `(14, 3)`, and `tada` gives `(21, 1)`.
  A non-uniform `scale` multiplies by `max(x, y)`, matching Misskey, so
  `scale.x=3,y=1` also gives `(14, 3)`.
- `useOriginalSize`: `scale >= 2.5`, matching Misskey's original-image hint.
  `misskey_emoji` 2.0.0-beta.1 exposes only one `EmojiImage.url`, with no
  original/thumbnail distinction. Automatic original-URL switching requires
  support in that dependency; no `MfmCustomEmoji.useOriginalSize` option is
  provided yet. A custom builder with access to both URLs can use the hint.

Both builder results use an alphabetic-baseline `WidgetSpan`. The renderer
cannot infer an arbitrary widget's image height or descent; the builder must
provide its baseline. `MfmCustomEmoji.baselineOffset` reports a baseline above
its box bottom without a paint-only translation, so line layout also accounts
for the descent.

Misskey aligns a custom emoji with `vertical-align: middle`, which centers the
box on `baseline + x-height / 2`. Approximating the x-height as 0.5em, the
matching descent is `size / 2 - context.fontSize * 0.25`, and `MfmEmojiConfig`
sets exactly that, including for a fixed `emojiSize`. Flutter's
`PlaceholderAlignment.middle` centers on the midpoint of the text ascent and
descent instead, so it is not equivalent; the renderer keeps baseline alignment
and lets the builder position the box. A Unicode emoji image is different:
Misskey renders it at a 1.25em height with `vertical-align: -0.25em`, so its
descent is `context.fontSize * 0.25`.

Without `unicodeEmojiBuilder`, Unicode emoji remain native text. To render
Twemoji or another image set, implement `unicodeEmojiBuilder` yourself. For
example, if your `unicodeImageResolver` maps a Unicode string to an
`EmojiImage` with the appropriate image URL, reuse the image widget as follows:

```dart
MfmRenderConfig(
  unicodeEmojiBuilder: (emoji, context) => MfmCustomEmoji(
    name: emoji,
    resolver: unicodeImageResolver, // App-provided EmojiResolver
    size: context.fontSize * 1.25,
    baselineOffset: context.fontSize * 0.25,
  ),
)
```

This matches Misskey's Unicode emoji image: a 1.25em height with
`vertical-align: -0.25em`. The package does not bundle Twemoji assets or a
Unicode-to-image resolver.

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

### MFM Color Schemes

`MfmColorScheme` controls the Misskey theme colors used by URL/link, mention,
hashtag, quote, search borders, the border fn default, unixtime borders, and
inline-code backgrounds. Ordinary body text continues to use `baseTextStyle`
or `DefaultTextStyle`.

The built-in presets contain resolved colors from Misskey's Mi Light and Mi
Dark themes:

| Role | Mi Light | Mi Dark |
|------|----------|---------|
| `accent` | `#86B300` | `#86B300` |
| `link` | `#44A4C1` | `#86B300` |
| `hashtag` | `#FF9156` | `#4CB8D4` |
| `mention` | `#86B300` | `#DA6D35` |
| `mentionMe` | `#00B346` | `#D44C4C` |
| `fg` | `#676767` | `#C7D1D8` |
| `bg` | `#F9F9F9` | `#232323` |
| `divider` | `#E8E8E8` | `rgba(255, 255, 255, 0.14)` |
| `panel` | `#FFFFFF` | `#2D2D2D` |

Set one or both schemes on `MfmRenderConfig`. An omitted mode keeps its
built-in preset:

```dart
MfmText(
  text: '@user #flutter https://example.com and `code`',
  config: const MfmRenderConfig(
    lightColorScheme: MfmColorScheme.light(
      link: Color(0xFF0066CC),
      bg: Color(0xFFF0F0F0),
    ),
    darkColorScheme: MfmColorScheme.dark(
      link: Color(0xFF80CBC4),
      bg: Color(0xFF1A1A1A),
    ),
  ),
)
```

Each field is a resolved, independent color. For example, overriding `accent`
does not automatically change `mention`, `link`, or any other field. Normal
mentions currently use `mention`; `mentionMe` is available in the scheme but
cannot be selected until the renderer has viewer identity information.

The mode is resolved in this order:

1. `MfmRenderConfig.brightness`
2. the nearest Material `Theme`
3. the nearest Cupertino theme
4. `MediaQuery` platform brightness
5. `Brightness.light`

Ambient themes select the mode only; their colors are not mapped automatically.
To opt into an application's Material colors, define that mapping explicitly:

```dart
MfmColorScheme mfmColorsFrom(ColorScheme material) => MfmColorScheme(
  accent: material.primary,
  link: material.primary,
  hashtag: material.tertiary,
  mention: material.secondary,
  mentionMe: material.error,
  fg: material.onSurface,
  bg: material.surface,
  divider: material.outlineVariant,
  panel: material.surfaceContainer,
);

final config = MfmRenderConfig(
  lightColorScheme: mfmColorsFrom(lightTheme.colorScheme),
  darkColorScheme: mfmColorsFrom(darkTheme.colorScheme),
);
```

The former `inlineCodeBgColorLight` / `inlineCodeBgColorDark` properties have
been removed. Migrate them to the corresponding preset's `bg` override:

```dart
const MfmRenderConfig(
  lightColorScheme: MfmColorScheme.light(bg: Color(0xFFF0F0F0)),
  darkColorScheme: MfmColorScheme.dark(bg: Color(0xFF1A1A1A)),
)
```

Math formulas remain unadorned and do not use `bg`.

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
| `lightColorScheme` | `MfmColorScheme?` | Mi Light preset | MFM colors used in light mode |
| `darkColorScheme` | `MfmColorScheme?` | Mi Dark preset | MFM colors used in dark mode |
| `brightness` | `Brightness?` | ambient theme/platform | Explicitly select the active MFM color mode |
| `enableAdvancedMfm` | `bool` | true | Enable advanced features like position |
| `enableAnimation` | `bool` | true | Enable animations (for future use) |
| `enableNyaize` | `bool` | false | Enable nyaize (cat-speak) transformation on text nodes |
| `emojiBuilder` | `Widget Function(String, MfmEmojiContext)?` | null | Custom emoji builder |
| `unicodeEmojiBuilder` | `Widget Function(String, MfmEmojiContext)?` | null | Unicode emoji builder |
| `onLinkTap` | `void Function(String)?` | null | Link tap callback |
| `onMentionTap` | `void Function(String)?` | null | Mention tap callback |
| `onHashtagTap` | `void Function(String)?` | null | Hashtag tap callback |
| `onSearchTap` | `void Function(String)?` | null | Search tap callback |
| `onCodeCopied` | `void Function(String)?` | null | Code copy completion callback; replaces the default SnackBar, which requires a ScaffoldMessenger ancestor |
| `codeCopyTooltip` | `String?` | current locale | Code copy button accessibility label override (`コピー` for Japanese, `Copy` otherwise) |
| `codeCopiedMessage` | `String?` | current locale | Default copy SnackBar message override (`コードをコピーしました` for Japanese, `Copied to clipboard` otherwise) |
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

The `x2`, `x3`, and `x4` functions share a nesting depth, including mixed combinations, matching Misskey's official behavior. All percentages are relative to the parent's effective font size:

- First level: `x2` is 200%, `x3` is 400%, and `x4` is 600%.
- Second level: `zoom / 2 + 50%`, using the inner function's zoom value (`x2`: 150%, `x3`: 250%, `x4`: 350%).
- Third level and deeper: 100% (no further enlargement; the parent's font size is inherited).

For a base font size of 14px, `$[x2 $[x2 A]]` renders the outer level at 28px and the inner level at 42px. `$[x2 $[x3 A]]` renders the inner level at 70px. Adding a third size function does not enlarge it further. Other nodes, such as bold, animation functions, and `scale`, preserve this nesting depth without increasing it.

## Additional information

- [API Documentation](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM Specification](https://misskey-hub.net/en/docs/for-users/features/mfm/)

## License

3-Clause BSD License - see [LICENSE](LICENSE)
