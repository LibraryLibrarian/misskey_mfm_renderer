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

## Mentions and display names

Mentions default to a capsule, even when `mentionOptions` is null: a circular
1.5em avatar/placeholder, 0.2em gap, and a single-line account label. No avatar
request is made by default. The full displayed account remains available once
to assistive technology even when the visible label is ellipsized. The whole
capsule is tappable when `onMentionTap` is supplied.

```dart
const config = MfmRenderConfig(
  localHost: 'local.example',
  mentionOptions: MfmMentionOptions(
    viewerAcct: '@alice', // Viewer, not the post author.
    // Opt in only if this local server should receive avatar requests:
    localOrigin: 'https://local.example',
  ),
);

// Migration: retain inline text layout instead of capsule WidgetSpans.
const textConfig = MfmRenderConfig(
  mentionOptions: MfmMentionOptions(
    presentation: MfmMentionPresentation.text,
  ),
);
```

- `viewerAcct` accepts `@username` or `@username@authority`; username is
  `[A-Za-z0-9_]+`. A hostless viewer requires `localHost` or `localOrigin`, never
  the author's host. Only a matching viewer uses the `mentionMe` role color.
- Display hosts resolve from the mention, then `author.host`, then `localHost`.
  An explicit origin authority is a final fallback for display, self comparison,
  and built-in avatars only. Local hosts are hidden; remote IDNs display in
  Unicode. Comparison is case-insensitive, removes one terminal DNS dot, and
  compares IPv6 address values. An absent mention port differs from an explicit
  port. Unlike upstream's raw local-host display comparison, local hiding here
  intentionally uses normalized authorities. Malformed content stays raw and
  cannot produce a guessed local/self match.
- `localOrigin` is a **string** to preserve spelling that `Uri` normalization
  would discard. At build time, after config inheritance, it must be an absolute
  HTTP(S) origin with a valid DNS/IDN, IPv4 or bracketed IPv6 host and optional
  numeric port 1–65535. Credentials, whitespace, queries/fragments (even empty),
  and paths other than empty or `/` are rejected with `ArgumentError`. Its
  authority must agree with merged `localHost`; scheme default ports are supplied
  only for this origin consistency check. Invalid viewers also throw, even in
  text mode or when the document has no mentions. Old malformed `localHost`
  values alone are not newly rejected.
- `avatarProvider: (String acct) => ImageProvider<Object>?` may return an asset,
  memory or explicitly network-backed image. It has priority; returning null
  means placeholder, **not** origin fallback. Only an absent provider permits
  the explicit origin's `/avatar/@username@host` path, safely assembled with
  `Uri.pathSegments`. Remote mention hosts are never contacted automatically.
  Loading and errors keep the same avatar geometry. Text mode never calls the
  provider or constructs an image.
- `onMentionTap` and the provider receive the same legacy raw resolved account,
  without Unicode/case conversion or origin-only fallback. Options inherit as a
  whole; `const MfmMentionOptions()` replaces inherited options. `copyWith` keeps
  options on null; `clearMentionOptions: true` removes only the current config's
  value, allowing inheritance again. Passing both a value and clear throws.

**Layout migration:** Capsules are `WidgetSpan`s, changing line breaks, line
height, and `InlineSpan.toPlainText()` (an object replacement character rather
than the account). Use source/AST data for text extraction or choose `text`
presentation. Text presentation retains normalized host display and applies the
same callback to both name and host. Capsules inherit typography and apply
small/quote opacity once; mention role colors override fg/static rainbow.
Animated rainbow still filters the whole subtree. Capsule text and avatar use
the ambient text scaler once (20px gives 30px avatar + 4px gap; scale 2 gives
60px + 8px). This does not change the existing root RichText scaling limitation;
it is not a text-scaling redesign for all MFM content.

For display names, use the existing plain parser rather than a new widget:

```dart
MfmText(
  text: 'Alice :wave: @alice',
  plain: true,
  nowrap: true,
  config: emojiConfig.copyWith(
    author: const MfmAuthorContext(host: 'remote.example'),
    emojiUrls: remoteUserEmojiUrls,
  ),
)
```

Here `@alice` remains literal text. Supply the target user's author context and
emoji dictionary, not the viewer's. The example catalog includes an offline,
deterministic display-name fixture and capsule/text comparisons.

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

**URL display**: Auto-linked HTTP(S) URLs are split into scheme, host, port, path, query, and fragment with the same emphasis as Misskey's `MkUrl`. Punycode hosts and percent-encoded hosts, paths, queries, and fragments are decoded for display only; `onLinkTap` always receives the original URL. External URLs end with an external-link icon, which requires the application to bundle the `MaterialIcons` font.
Set `MfmRenderConfig.localHost` to shorten URLs to the local instance: non-root URLs omit the scheme and host, while a root URL displays the bold host. The current API provides a host rather than a complete origin, so this is a host-based approximation: comparison is case-insensitive, ignores trailing dots, and checks the effective port only when `localHost` includes one. It cannot distinguish HTTP from HTTPS, and when no port is supplied it compares only the host.

**Quote**: `> quote` occupies a full line with an 8px margin on all sides, padding of 6px top/bottom and 12px left (0px right), and a 3px left border, matching Misskey's `QUOTE_STYLE`. Text and border use the active `MfmColorScheme.fg` with cumulative opacity applied; each quote and `<small>` level multiplies the original alpha by 0.7. This quote color is independent of `baseTextStyle` and `DefaultTextStyle`.
Block display requires a parent with bounded width (for example, `SizedBox(width: 300)` or `Expanded` in a `Row`). With unbounded width, such as a non-`Expanded` child of a `Row`, quotes use their natural width and are not guaranteed to occupy a separate line. No extra boundary newlines are inserted. CSS margin collapsing between adjacent quotes and the handling of extra newlines around blocks are not fully reproduced.

**Literal fn fallback**: Unknown fn names, `font` without a valid family, and `position` with `enableAdvancedMfm: false` are displayed as `$[name content]` (arguments omitted), preserving child formatting, matching Misskey.

**Not Yet Implemented:**
- **Font Limitations**: Some font types in `$[font.xxx]` syntax (specifically `emoji` and `math`) fall back to default fonts due to platform limitations.

**Nyaize (Cat-speak transformation)**: Text transformation is supported via the legacy
`enableNyaize` boolean or `nyaizeMode`. `MfmNyaizeMode.respectAuthor` converts only
when `author?.isCat == true`; an explicitly supplied `nyaizeMode` takes precedence
over `enableNyaize`. Subtrees of `link` / `quote` / `plain` are excluded from
transformation (matching Misskey's upstream behavior).
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
Visual x2/x3/x4 enlargement and `scale` effects require `enableAdvancedMfm: true`.
When it is false, x2/x3/x4 keep the font size unchanged but still propagate
nominal `context.scale` multipliers of 2/3/4; `scale` applies neither a transform
nor a context multiplier. For example, `$[x4 :emoji:]` stays 28px high at a 14px
base font, while its context is `(fontSize: 14, scale: 4)`.

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

Like Misskey, `twitch` and `shake` apply `ease` to each adjacent keyframe
interval. During a positive `delay`, they remain untransformed until playback starts.

## Getting started

This package requires Flutter 3.38.1 or later (Dart 3.10.0 or later). The
`.fvmrc` development environment uses Flutter 3.38.7, while the package
support floor remains Flutter 3.38.1.

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
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
test double without opening a SQLite database. Configurations created with
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

### MkMfm-compatible document props

`plain`, `nowrap`, `rootScale`, and `isNote` belong to each rendered document, so they
are arguments of `MfmText`, rather than `MfmRenderConfig`:

```dart
MfmText(
  text: 'one\ntwo :wave:',
  plain: true, // Uses the simple parser and renders line breaks as spaces.
  nowrap: true, // Single-line ellipsis, for example in timeline previews.
  rootScale: 3, // Initial cumulative scale for descendant MFM functions.
  isNote: false, // Makes hashtag details use /user-tags/... instead of /tags/....
)
```

`plain` is distinct from `simple: true`: both use the simple parser, but `simple`
preserves line breaks and the normal custom-emoji size. `plain` normalizes CRLF/CR/LF,
then replaces LF with spaces, including when `parsedNodes` is supplied. It also passes
`MfmEmojiContext.normal: true` to custom emoji builders. `MfmEmojiConfig` renders this
at 1.25em and uses a 0.25em descent, matching Misskey's `.normal` CSS class.

`nowrap` sets the outer `RichText` to one line with `TextOverflow.ellipsis` and
`softWrap: false`, making it suitable for timeline previews. Quotes retain their margin,
left border, and opacity, but use their natural inline width instead of expanding to the
full line so they can fit in the preview.

`rootScale` must be finite and greater than zero. It only initializes traversal scale;
it does not modify the root font size or add a transform.

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
    // Backward-compatible hashtag tap callback
    onHashtagTap: (tag) {
      navigateToHashtag(tag);
    },
    // Preferred detailed callback. When supplied, onHashtagTap is not called.
    onHashtagTapDetails: (details) {
      navigateToPath(details.path); // /tags/<encoded> or /user-tags/<encoded>
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
    author: const MfmAuthorContext(
      host: 'remote.example',
      isCat: true, // Used by MfmNyaizeMode.respectAuthor.
    ),
    localHost: 'local.example',
    onMentionTap: navigateToUser,
  ),
)
```

### Custom Emoji in Remote Posts

Pass each remote note's emoji URL map together with its author host. Start from your
shared local-server configuration and create a per-note copy:

```dart
MfmText(
  text: note.text,
  config: config.copyWith(
    author: const MfmAuthorContext(host: 'remote.example'),
    emojiUrls: note.emojis,
  ),
)
```

For a local post, custom emoji use the configured local resolver. For a remote post,
the renderer first uses the exact shortcode key in `emojiUrls`; a mapped non-empty URL
is used directly. If `emojiUrls` is present but has no key for the shortcode, the
renderer shows literal `:name:` text and does not use a fallback. When `emojiUrls` is
absent (or its matched URL is empty), `MfmEmojiConfig` falls back to the local Misskey
server's `/emoji/name@host.webp` endpoint. `MfmEmojiConfig.createDefault` obtains that
server URL from its client. For `MfmEmojiConfig.fromResolver`, provide
`serverBaseUrl` to enable this remote endpoint fallback; without it, a remote emoji
without a direct URL remains literal text and never uses the local resolver.

Treat `emojiUrls` as immutable. Mutating a map after passing it to `MfmRenderConfig`
does not notify inherited configuration listeners; replace it with a new map when the
note data changes.

### Advanced Custom Emoji Configuration

To display custom emojis from a Misskey server, integrate the `misskey_emoji` library:

#### 1. (Optional) Add Direct Dependencies

If your project enforces direct dependencies for imported packages, add:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
  misskey_client: ^1.0.0-beta.5
  misskey_emoji: ^2.0.0-beta.2
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

// Open the per-server SQLite store for emoji metadata
final dir = await getApplicationDocumentsDirectory();
final store = await openEmojiStoreForServer(baseUrl, directory: dir.path);

// Create persistent catalog and resolver (the catalog owns the store)
final catalog = PersistentEmojiCatalog(
  source: emojiSource,
  store: store,
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

The standard `:name:` fallback uses the surrounding text's **1em size and natural
alphabetic baseline**, including in plain mode, when resolution fails, or when an
image cannot be decoded. `emojiSize` and `emojiMaxWidth` affect images, not this
text. `MfmEmojiConfig` supplies the inherited font, weight, decoration and colors.
Standalone `MfmCustomEmoji` uses `fallbackTextStyle` when provided, otherwise
`DefaultTextStyle`. Custom fallback/error/loading builders keep the image baseline
policy; their signatures and the successful image sizing defaults are unchanged.

**Migration for the previous standalone appearance:** explicitly request the old
`size * 0.6` text size in `fallbackBuilder`. The existing `baselineOffset` still
applies to this custom builder; do not add another baseline wrapper.

```dart
const size = 24.0;
MfmCustomEmoji(
  name: 'emoji_name',
  resolver: resolver,
  size: size,
  baselineOffset: 8.5, // Keep your existing image baseline offset.
  fallbackBuilder: (context, name) => Text(
    ':$name:',
    style: DefaultTextStyle.of(context).style.copyWith(fontSize: size * 0.6),
  ),
)
```

### Emoji Builder Context and Unicode Images

Both `emojiBuilder` and `unicodeEmojiBuilder` now take two arguments. Migrate
`(name) => ...` to `(name, context) => ...` (or `(name, _) => ...` for a fixed
widget). The publicly exported immutable `MfmEmojiContext` contains:

- `fontSize`: the current effective font size in logical pixels, including
  size functions, `tada` (150%), and `<small>` (80%).
- `textStyle`: optional inherited text style before cumulative `small`/quote
  opacity, including the current size/font/decoration/colors. Original root alpha,
  foreground/background paints and shadows are preserved. The renderer applies
  cumulative opacity outside the returned widget, so do not attenuate it again.
  Renderer-created contexts always supply it; manually constructed contexts may
  omit it. For a text widget, use
  `context.textStyle ?? TextStyle(fontSize: context.fontSize)`.
- `scale`: the cumulative x2/x3/x4/scale-function multiplier. `tada` and
  `<small>` do not change it. `MfmText.rootScale` supplies the initial value.
  For a 14px base, x2 gives `(28, 2)`, x4 gives `(84, 4)`, `scale.x=3,y=3`
  gives `(14, 3)`, and `tada` gives `(21, 1)` with advanced MFM enabled.
  A non-uniform `scale` multiplies by `max(x, y)` for non-negative values,
  matching Misskey, so `scale.x=3,y=1` also gives `(14, 3)`. With
  `enableAdvancedMfm: false`, x2/x3/x4 instead give `(14, 2)` / `(14, 3)` /
  `(14, 4)`, while `scale.x=3,y=3` gives `(14, 1)`.
- `normal`: true only for custom emoji in `MfmText(plain: true)`. Builders can use
  it to select Misskey's 1.25em `.normal` appearance.
- `useOriginalSize`: `scale >= 2.5`, matching Misskey's original-image hint.
  `misskey_emoji` 2.0.0-beta.2 exposes only one `EmojiImage.url`, with no
  original/thumbnail distinction. Automatic original-URL switching requires
  support in that dependency; no `MfmCustomEmoji.useOriginalSize` option is
  provided yet. A custom builder with access to both URLs can use the hint.
  Because x multipliers still propagate with advanced MFM disabled,
  `$[x4 :emoji:]` can have `useOriginalSize: true` without enlarging the font.

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
    fallbackTextStyle: context.textStyle,
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

`ruby` and `unixtime` inherit surrounding MFM font sizes, colors, fonts, and
text decorations. Ruby annotations use half of the current font size, and
unixtime uses 90%. `position` offsets are measured in the current font's em,
so `$[x2 $[position.x=1 text]]` moves by twice the root font size. Nested
`small` opacity is applied once, including across these widget boundaries.

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

`enableAdvancedMfm` controls the visual enlargement of x2/x3/x4, `scale`,
`position`, and all nine MFM animation functions. Animations run only when
both flags are true: the read-only `config.useAnimation` getter is
`enableAdvancedMfm && enableAnimation`. Both flags default to true.

```dart
MfmText(
  text: r'$[x4 large] $[scale.x=3 scaled] $[position.x=10 moved] $[spin still]',
  config: MfmRenderConfig(
    // Suppress size/scale/position effects and MFM animations
    enableAdvancedMfm: false,
    enableAnimation: true, // Advanced MFM takes precedence
  ),
)
```

With advanced MFM disabled, x2/x3/x4 preserve font size (but still propagate
nominal emoji-context scale), `scale` applies neither a transform nor scale
propagation, and `position` is rendered literally as `$[position children]`.
`flip`, `rotate`, and other styling functions remain available.

When either flag is false, `spin`, `jump`, `bounce`, `shake`, `twitch`, and
`jelly` render their children without animation wrappers. `tada` retains its
150% font size, `rainbow` uses a static gradient, and `sparkle` renders its
children without a wrapper. Set only `enableAnimation: false` to stop MFM
animations while keeping size, scale, and position effects.
These flags control MFM animation functions, not playback of animated emoji
images. They do not automatically follow the OS reduced-motion preference.

### Rainbow animation and source colors

Like Misskey, `rainbow` applies `hue-rotate` → `contrast(150%)` →
`saturate(150%)`, rotating the hue **from the original text colors** rather
than sweeping a gradient across the text. **Gray or black body text shows no
hue change**: dark gray only becomes slightly darker, and black stays black.
Colored `fg` text, links, and color emoji visibly cycle through rainbow hues:

```dart
MfmText(text: r'$[rainbow $[fg.color=ff0000 colorful]]')
```

The default cycle is 1 second with linear, infinite repetition. `speed` changes
the cycle duration; a positive `delay` leaves the original child unfiltered
until the animation starts. When `config.useAnimation` is false, the static
fallback remains the familiar rainbow gradient (seven colors and seven stops).
It applies only to text using the inherited foreground color; explicit colors
inside the rainbow (such as `fg` and links), emoji images, backgrounds, and
borders retain their original colors.

### Unixtime display and localization

`$[unixtime 1700000000]` defaults to **local absolute date + relative time**
(`11/14/2023, 10:13:20 PM (3y ago)` in UTC, for example). The synchronous built-in
formatter needs no initialization or extra dependency. Locale priority is
`options.locale` → Flutter `Localizations` → English. Japanese uses
`2026/10/2 0:04:05`; all other languages/regions (including en-GB) fall back to
English/US order. Custom formatters receive the original resolved locale.

```dart
MfmText(
  text: r'$[unixtime 1700000000]',
  config: const MfmRenderConfig(
    unixtimeOptions: MfmUnixtimeOptions(
      locale: Locale('ja'),
      mode: MfmUnixtimeMode.detail, // relative / absolute also available
    ),
  ),
)
```

Options inherit **as one object**: null inherits, `const MfmUnixtimeOptions()`
resets to defaults, and `copyWith(clearUnixtimeOptions: true)` removes only the
local value, allowing inheritance again. Setting and clearing together throws
`ArgumentError`.

Only the first child is parsed, and only if it is text. Integer prefixes follow
ECMAScript whitespace/sign/hex rules: `1700000000foo` is accepted, `1e3` and `1.5`
mean 1, `0x10` means 16, and `0b11` means 0. Dates beyond ±8640000000000 seconds,
empty/non-text first children and invalid input retain the pill with “None”
(Japanese: “日時の解析に失敗”); later children are not a fallback. Years ≤ 0 display
as `1 - year` without an era label. This is not full Intl/CLDR or historical
timezone equivalence, nor arbitrary IANA timezone conversion.

Relative labels distinguish past and future using fixed-length years/months.
The intentionally asymmetric boundaries include exactly 60 seconds ahead →
“In 0s”, exactly 3600 seconds ahead → “In 60m”, and up to 3 seconds ahead →
“Just now”. Fractional milliseconds are considered before choosing the unit.

Valid detail/relative labels share one 10-second timer while mounted. It stops
when the app is hidden/paused/detached, refreshes immediately on resume, and is
released with its final subscriber. Inactive/unknown lifecycle states remain
active. `enableAnimation` and `TickerMode` do not disable date updates; individual
node visibility is not tracked. `now: () => appClock.now` can supply an
application-managed clock, read once per format. `autoUpdate: false` disables
periodic updates, not ordinary rebuild/config/locale refreshes. Absolute and
invalid labels never subscribe, **even when a custom formatter reads `now`**.
Local timezone is re-evaluated on formatting; absolute/disabled-update labels
need an ordinary rebuild rather than just resume to reflect timezone changes.
No MaterialApp, Localizations or MediaQuery ancestor is required.

Labels wrap within finite available width. With `MfmText(nowrap: true)` they use
one-line ellipsis while semantics retain the full current label. The clock is
decorative. Allow at least enough width for the pill padding, icon and gap;
arbitrarily tiny constraints cannot display it without overflow.

#### Migrating the previous relative labels

For the previous **valid-input** timeago labels (global/default locale and
legacy future wording) without automatic updates:

```dart
const MfmRenderConfig(
  unixtimeOptions: MfmUnixtimeOptions(
    mode: MfmUnixtimeMode.relative,
    formatter: mfmLegacyUnixtimeFormatter,
    autoUpdate: false,
  ),
)
```

Configure timeago's global locale in your app if needed. The built-in formatter
does not read or modify it. This migration does **not** restore old parsing or
invalid fallback behavior; relative mode alone uses the new short labels.

#### Custom formatting with intl

A formatter replaces the **whole label** and receives nullable local `dateTime`,
`now`, resolved `locale`, and `mode`. Add `intl` as a **direct dependency of your
app**, not this library. Complete its asynchronous date-symbol initialization
before using the formatter (and initialize every locale your app supplies):

```dart
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  runApp(Directionality(
    textDirection: TextDirection.ltr,
    child: MfmText(
      text: r'$[unixtime 1700000000]',
      config: MfmRenderConfig(
        unixtimeOptions: MfmUnixtimeOptions(
          locale: const Locale('ja', 'JP'),
          mode: MfmUnixtimeMode.absolute,
          formatter: (context) => context.dateTime == null
              ? '—'
              : DateFormat.yMMMMd(context.locale.toString())
                  .add_Hms()
                  .format(context.dateTime!),
        ),
      ),
    ),
  ));
}
```

## Configuration

### MfmRenderConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `unixtimeOptions` | `MfmUnixtimeOptions?` | null | Whole-object date display/locale/formatter/clock inheritance |
| `baseTextStyle` | `TextStyle?` | null | Base text style |
| `lightColorScheme` | `MfmColorScheme?` | Mi Light preset | MFM colors used in light mode |
| `darkColorScheme` | `MfmColorScheme?` | Mi Dark preset | MFM colors used in dark mode |
| `brightness` | `Brightness?` | ambient theme/platform | Explicitly select the active MFM color mode |
| `enableAdvancedMfm` | `bool` | true | Enable visual x2/x3/x4 enlargement, scale/position effects, and MFM animations |
| `enableAnimation` | `bool` | true | Enable MFM animations when advanced MFM is enabled |
| `useAnimation` | `bool` (getter) | true (derived) | Read-only effective animation gate: `enableAdvancedMfm && enableAnimation` |
| `enableNyaize` | `bool` | false | Legacy forced nyaize switch when `nyaizeMode` is null |
| `nyaizeMode` | `MfmNyaizeMode?` | null | `disabled`, `enabled`, or `respectAuthor`; explicit value takes precedence |
| `onHashtagTapDetails` | `void Function(MfmHashtagTapDetails)?` | null | Preferred hashtag callback with `tag`, `isNote`, and encoded route `path` |
| `emojiBuilder` | `Widget Function(String, MfmEmojiContext)?` | null | Custom emoji builder |
| `unicodeEmojiBuilder` | `Widget Function(String, MfmEmojiContext)?` | null | Unicode emoji builder |
| `emojiUrls` | `Map<String, String>?` | null | Direct image URLs keyed by custom emoji name, used for remote posts only. Treat the map as immutable and pass a new one to update |
| `onLinkTap` | `void Function(String)?` | null | Link tap callback |
| `onMentionTap` | `void Function(String)?` | null | Mention tap callback |
| `onHashtagTap` | `void Function(String)?` | null | Hashtag tap callback |
| `onSearchTap` | `void Function(String)?` | null | Search tap callback |
| `onClickableEvent` | `void Function(String)?` | null | `clickable` fn callback; receives the value of the `clickable.ev` argument |
| `showCodeBlockCopyButton` | `bool?` | true | Show the copy button on code blocks |
| `onCodeCopied` | `void Function(String)?` | null | Code copy completion callback; replaces the default SnackBar, which requires a ScaffoldMessenger ancestor |
| `codeCopyTooltip` | `String?` | current locale | Code copy button accessibility label override (`コピー` for Japanese, `Copy` otherwise) |
| `codeCopiedMessage` | `String?` | current locale | Default copy SnackBar message override (`コードをコピーしました` for Japanese, `Copied to clipboard` otherwise) |
| `codeTheme` | `Map<String, TextStyle>?` | github theme | Syntax highlight theme for code blocks in light mode |
| `codeDarkTheme` | `Map<String, TextStyle>?` | `codeTheme`, then github-dark | Syntax highlight theme for code blocks in dark mode |
| `author` | `MfmAuthorContext?` | null | Author context (`host`, `isCat`) used for host-dependent rendering and `respectAuthor` nyaize |
| `localHost` | `String?` | null | Local Misskey host used as a host-resolution fallback and for self-URL shortening |
| `searchButtonLabel` | `String?` | current locale | Search button label override (`検索` for Japanese, `Search` otherwise) |
| `useLocaleSearchButtonLabel` | `bool` | false | Clear a configured or inherited search label and resolve it from the current locale |
| `fontFamilyResolver` | `String? Function(String)?` | null | Font family resolver function |

`copyWith` preserves the current `author` and `localHost` when their nullable
arguments are omitted or `null`. Set `clearAuthor: true` or
`clearLocalHost: true` to remove a value. Providing a replacement value and its
corresponding clear flag in the same call throws `ArgumentError`.

## Technical Notes

### Platform notes

The package works on Android, iOS, macOS, Linux, and Windows. Web is not
supported. Web builds compile, but `misskey_emoji` does not provide a Web store
yet, so `MfmEmojiConfig.createDefault` cannot be used there. Rendering on Web
has not been tested.

Custom emoji metadata is stored in SQLite through Drift. The native SQLite
library is supplied by the build hooks of `sqlite3` 3.x, which download
prebuilt binaries from GitHub Releases on a clean build. For offline builds or
an internal mirror, configure `hooks.user_defines` in the application's
`pubspec.yaml` (in the workspace root's `pubspec.yaml` when using a pub
workspace). See the `misskey_emoji` README for the available settings.

Apps using the macOS App Sandbox need the
`com.apple.security.network.client` entitlement for `MfmEmojiConfig` and image
loading. Windows apps require the Microsoft Visual C++ Runtime
(`VCRUNTIME140.dll`).

### Migrating from Isar cache files

Versions depending on `misskey_emoji` 2.0.0-beta.1 or earlier stored emoji
metadata in Isar. The current version uses a differently named
`misskey_emoji_<serverKey>_<hash8>.sqlite` file for each server and does not
read the old files, so emoji metadata is fetched again on the first sync. The old files only consume disk space. To remove them, delete
the following files from the `storagePath` passed to
`MfmEmojiConfig.createDefault` (the application documents directory when
omitted), after every old handle has been disposed:

```
<directory>/misskey_emoji_*.isar
<directory>/misskey_emoji_*.isar-lck
```

Filter by the `misskey_emoji_` prefix, because the application may keep its own
unrelated Isar databases in the same directory.

### Text Selection

This library prioritizes visual fidelity and does not support text selection after rendering. If you need copy functionality, implement it separately using the original MFM text (raw data) at the app level.

### Scale Limits

The `scale` fn function is limited to a maximum of 5x. This is the same security limitation as Misskey's official implementation.
With `enableAdvancedMfm: false`, it applies neither a paint transform nor a
multiplier to `MfmEmojiContext.scale`; any scale inherited from an outer x
function is preserved. Its static children use `TextSpan`, without reproducing
the upstream empty `inline-block` span's line-layout boundary.

### Nested Size Functions

The `x2`, `x3`, and `x4` functions share a nesting depth, including mixed combinations, matching Misskey's official behavior. With advanced MFM enabled, all percentages are relative to the parent's effective font size:

- First level: `x2` is 200%, `x3` is 400%, and `x4` is 600%.
- Second level: `zoom / 2 + 50%`, using the inner function's zoom value (`x2`: 150%, `x3`: 250%, `x4`: 350%).
- Third level and deeper: 100% (no further enlargement; the parent's font size is inherited).

For a base font size of 14px, `$[x2 $[x2 A]]` renders the outer level at 28px and the inner level at 42px. `$[x2 $[x3 A]]` renders the inner level at 70px. Adding a third size function does not enlarge it further. Other nodes, such as bold, animation functions, and `scale`, preserve this nesting depth without increasing it.

With `enableAdvancedMfm: false`, x2/x3/x4 do not change font size at any depth.
Nesting depth and nominal scale multipliers (2/3/4) still propagate, even at the
third level and deeper. These multipliers are separate from the CSS font-size
percentages: `$[x2 $[x3 A]]` keeps a 14px base font but passes scale 6 to its
children. Disabling only `enableAnimation` does not change size-function behavior.

## Additional information

- [API Documentation](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM Specification](https://misskey-hub.net/en/docs/for-users/features/mfm/)

## License

3-Clause BSD License - see [LICENSE](LICENSE)
