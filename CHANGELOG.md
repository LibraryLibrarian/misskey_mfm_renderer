# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fixed `rainbow` recoloring custom emoji, explicitly set text colors, backgrounds, and borders while animation is disabled. The static gradient now applies only to text that inherits its color, preserving `fg` and link colors as well as the original colors of images

## [0.6.0-beta.2] - 2026-09-12

### Added
- Added `MfmColorScheme` and `MfmRenderConfig.lightColorScheme` / `darkColorScheme`, following Mi Light / Mi Dark. The colors of links, mentions, hashtags, quotes, search, the `border` fn, unixtime, and inline code can now be configured separately for light and dark (#50)
- Added `MfmAuthorContext.isCat` and `MfmNyaizeMode` (`disabled` / `enabled` / `respectAuthor`). When `nyaizeMode` is unset, the existing `enableNyaize` is interpreted for backward compatibility; `respectAuthor` follows the author's `isCat` (#39)
- Added `MfmText.plain`, `rootScale`, and `isNote`. As in upstream MkMfm, `plain` uses the simple parser, turns newlines in text nodes into single spaces, and renders custom emoji at normal size; `rootScale` resets the accumulated scale for descendants (#39)
- Added `MfmText.nowrap`, which renders on a single line, disables wrapping, and enables an ellipsis on overflow. Quotes keep their margins, left border, and opacity at their natural inline width (#39)
- Added `MfmHashtagTapDetails` and `onHashtagTapDetails`. The detailed callback receives the tag, `isNote`, and an encoded `/tags/...` or `/user-tags/...` path, and takes precedence over the existing `onHashtagTap` when supplied (#39)
- Added `MfmRenderConfig.emojiUrls`, `MfmCustomEmoji.url`, `MfmEmojiContext.host` / `url`, and `MfmEmojiConfig.fromResolver(serverBaseUrl:)`, supporting direct custom emoji URLs from remote posts with a fallback through the local server (#56)
- Added macOS, Linux, and Windows support to the example app, along with per-platform notes in the README covering the lack of web support, the macOS entitlement, and the Linux/Windows requirements

### Fixed
- Changed the `rainbow` animation from a gradient sweep to the same three-stage filter used by upstream Misskey: `hue-rotate`, then `contrast(150%)`, then `saturate(150%)` (#40, visual change). Because the hue rotates from the original text color, gray or black body text shows no visible hue change; dark gray only becomes slightly deeper, and black is unchanged. Colored `fg`, links, and color emoji do show the hue change. No filter is applied while a positive `delay` is pending, and the rainbow gradient used when the animation is disabled is preserved, reorganized to the same seven colors and seven stops as upstream
- Changed the `ease` of `twitch` and `shake` to apply to each adjacent keyframe interval, as upstream Misskey does, rather than to the animation as a whole (#42)
- Quotes now render as a full-width block inside a bounded parent, separated from the surrounding text. When the width is unconstrained, they fall back to their natural width (#32)
- Aligned quote spacing with the upstream `QUOTE_STYLE` (8px margin on all sides; 6px top and bottom, 12px left, and 0px right padding), and used `MfmColorScheme.fg` with the accumulated opacity for both the 3px left border and the text (#52)
- Joined the search field and its button with a `MfmColorScheme.divider` border and no gap, and removed the fixed blue background and white text to match the upstream appearance (#53)

### Changed
- Extended the scope of `enableAdvancedMfm` to the visual enlargement of x2/x3/x4, `scale` / `position`, and all nine MFM animations. Added `MfmRenderConfig.useAnimation` (`enableAdvancedMfm && enableAnimation`), so animations also stop when advanced MFM is disabled. Both flags still default to true (#37)
- With advanced MFM disabled, the nominal x2/x3/x4 multipliers of 2/3/4 still propagate to the emoji rendering context, but the `scale` fn transform and its multiplier propagation stop. With animation disabled, no dedicated animation widget is created, while tada's 150% font size, rainbow's static gradient, and sparkle's bare child are preserved (#37)
- Added `normal` to `MfmEmojiContext` and included it in value equality, `hashCode`, and `toString`. For `normal`, `MfmEmojiConfig` uses a default of 1.25em and a 0.25em descent equivalent to `vertical-align: -0.25em`. An explicit `emojiSize` takes precedence for the height, while the baseline policy for `normal` is retained (#39)
- Made `MfmCustomEmoji.resolver` optional and gave precedence to a directly specified `url`. The `==` and `toString` of `MfmEmojiContext` now include the host and URL (#56)
- **Breaking:** Changed `emojiBuilder` / `unicodeEmojiBuilder` to `Widget Function(String, MfmEmojiContext)` so that the effective font size and accumulated scale are passed (#47, #57)
- **Breaking:** Changed the default `emojiSize` of `MfmEmojiConfig.createDefault` / `fromResolver` from a fixed 24px to twice the effective font size (2em, with a null argument). Pass `emojiSize: 24` explicitly to keep the fixed size (#47)
- Changed emoji `WidgetSpan`s to alphabetic baseline alignment. `MfmEmojiConfig` sets `MfmCustomEmoji.baselineOffset` to the same descent as upstream custom emoji, equivalent to `vertical-align: middle` (`size / 2 - font size * 0.25`), and reflects it in the line's descent as well. When drawing Unicode emoji as images, specify a height of 1.25em and a descent of `font size * 0.25`, equivalent to `vertical-align: -0.25em` (#57)
- Changed the accumulated multiplier of the `scale` fn from `(|x| + |y|) / 2` to `max(|x|, |y|)`, matching upstream. `MfmEmojiContext.scale` for `$[scale.x=3,y=1]` is now 3.0 instead of 2.0, and the `useOriginalSize` decision matches upstream as well (#47)
- Added an original-size image decision (scale >= 2.5) to `MfmEmojiContext.useOriginalSize`. Because `misskey_emoji` does not distinguish original and scaled-down URLs, no automatic switching is performed; it is exposed as a hint for custom builders (#47)
- Inline code now inherits font size, color, and weight from its parent, and its padding and corner radius are em-relative (#54)
- **Breaking:** Removed the default underline on URLs and links to match upstream Misskey's underline-free rendering, and changed the link color from a fixed `#0066CC` to the selected `MfmColorScheme.link` (#50)
- **Breaking:** Removed `inlineCodeBgColorLight` / `inlineCodeBgColorDark` and consolidated the inline code background into `MfmColorScheme.bg`. The defaults become Mi Light `#f9f9f9` / Mi Dark `#232323`. Migrate the old settings to `lightColorScheme: MfmColorScheme.light(bg: color)` / `darkColorScheme: MfmColorScheme.dark(bg: color)` (#50)
- Removed the card presentation, padding, centering, and full-width layout of math, rendering it as the same undecorated monospace text as upstream Misskey (#51, visual change)
- URLs are now decomposed into scheme, Unicode host, port, and decoded path, query, and fragment, with an external-link icon and self-URL shortening based on `localHost` (#48, visual change)
- Added `punycoder ^0.3.0` as a dependency for Punycode decoding of URL hosts
- Aligned code blocks with upstream MkCode, applying a 1px theme divider border, an 8px corner radius, 1em padding, and a monospace font fallback list. Blocks without a language use the MFM scheme's `bg` / `fg`, while highlighted blocks use the highlight theme background (#55, visual change)

## [0.6.0-beta.1] - 2026-08-15

### Changed
- **Breaking:** `MfmEmojiConfig.createDefault()` now requires a caller-owned `MisskeyClient`
  - Stopped creating a dedicated HTTP client for fetching emoji, reusing the app's connection settings and credentials instead
  - `MfmEmojiConfigHandle.dispose()` disposes only the catalog and the store, not the supplied `MisskeyClient`
- Dropped the dependency on `misskey_api_core` and migrated to the `EmojiSource` API of `misskey_client` and `misskey_emoji` 2.0

### Removed
- **Breaking:** Removed the `serverUrl` argument from `MfmEmojiConfig.quickSetup()` / `createDefault()`
  - It is now derived from `MisskeyClient.baseUrl`, added in `misskey_client` 1.0.0-beta.6
  - Previously both `client` and `serverUrl` were required, which allowed inconsistent values to be passed

- **Breaking:** Removed `MfmEmojiConfig.quickSetup()`. Dropping `serverUrl` made its signature identical to `createDefault()`; use `createDefault()` instead

## [0.5.0] - 2026-08-10
### Added
- Added `cacheScope` for separating the custom emoji URL and aspect ratio caches by a stable identifier

### Fixed
- Fixed a known aspect ratio not being reused when the resolver closure is recreated
- Fixed the reverse reflow that occurred after the real image appeared, caused by using `maxWidth` as the estimated placeholder width when the aspect ratio was unknown
- Fixed generating a loading indicator that could not be drawn inside a zero-width placeholder

## [0.4.0] - 2026-08-10
### Added
- Added `dispose()`, which releases the persistent store, to the configuration returned by `MfmEmojiConfig.quickSetup()` / `createDefault()`
- Added support for injecting an emoji store through `emojiStoreFactory`
- Added `aspectRatio` for specifying a known custom emoji aspect ratio

### Changed
- Changed the return value of `MfmEmojiConfig.quickSetup()` / `createDefault()` to `MfmEmojiConfigHandle`, a subclass of `MfmRenderConfig`
  - Existing code that treats it as a `MfmRenderConfig` needs no change
  - Configurations created with `copyWith()` share a lifecycle; disposing any one of them marks all of them disposed

### Fixed
- Fixed `emoji_config_test` opening a real Isar instance inside a unit test, which failed when the native library was missing or the instance name collided
- Fixed body text reflowing because a square width was reserved while a custom emoji was loading
- Known custom emoji aspect ratios are now reused, suppressing reflow when they are recreated

## [0.3.0] - 2026-08-08
### Added
- Added `maxWidth` / `emojiMaxWidth` for setting an optional maximum width on custom emoji
- Added `refreshListenable` / `emojiRefreshListenable` for re-resolving custom emoji after a catalog update

### Fixed
- Fixed wide custom emoji being rendered extremely small inside a square area
- Fixed a possible aspect ratio distortion when creating the custom emoji memory cache
- Fixed already-resolved custom emoji being resolved again when the parent widget rebuilds
- Fixed unresolved custom emoji and updated metadata not being reflected after a catalog sync
- Fixed rendering failing when an animation function's `speed` was zero or negative, or shorter than 1ms
- A negative `delay` is now treated as already-elapsed time, as upstream Misskey does

## [0.2.0] - 2026-05-16
### Added
- Added Nyaize support, the text transformation used by cat mode
  - The pure function `nyaize(String)` is part of the public API and can be imported directly from `misskey_mfm_renderer`
  - Transformation rules equivalent to upstream Misskey for Japanese, English, and Korean
  - Setting `MfmRenderConfig.enableNyaize` to `true` applies it automatically to the text nodes of `MfmText`
  - Subtrees under `link` / `quote` / `plain` are excluded, following upstream behavior
  - URL, mention, hashtag, code, math, emoji, and search nodes are excluded naturally because they structurally do not go through text nodes

## [0.1.0] - 2026-02-09
Initial release of misskey_mfm_renderer - A Flutter widget library for rendering Misskey MFM (Misskey Flavored Markdown) content.

### Added

#### Text Formatting
- Bold (`**text**`)
- Italic (`*text*` / `<i>text</i>`)
- Strike (`~~text~~`)
- Small (`<small>text</small>`)
- Plain (`<plain>text</plain>`)

#### Block Elements
- Quote (`> text`)
- Center (`<center>text</center>`)
- Code Block (` ```code``` `)
- Inline Code (`` `code` ``)
- Math Block (`\[ formula \]`) - Displayed as plain text
- Math Inline (`\( formula \)`) - Displayed as plain text

#### Links & References
- URL (auto-detection)
- Link (`[label](url)`)
- Mention (`@user@host`)
- Hashtag (`#hashtag`)
- Search (`keyword Search`)

#### Emoji Support
- Unicode Emoji
- Custom Emoji with `misskey_emoji` integration
  - Automatic emoji metadata resolution
  - Image caching with `cached_network_image`
  - Fallback display for unavailable emojis
  - Animated emoji support (GIF, APNG, WebP)

#### fn Functions - Size
- x2 (`$[x2 text]`)
- x3 (`$[x3 text]`)
- x4 (`$[x4 text]`)

#### fn Functions - Transform
- Flip (`$[flip text]` / `$[flip.h,v text]`)
  - Horizontal flip
  - Vertical flip
  - Combined flip
- Rotate (`$[rotate.deg=45 text]`)
- Scale (`$[scale.x=2,y=2 text]`)
- Position (`$[position.x=1,y=1 text]`)

#### fn Functions - Style
- Foreground color (`$[fg.color=ff0000 text]`)
- Background color (`$[bg.color=00ff00 text]`)
- Border (`$[border.color=0000ff text]`)
- Font (`$[font.serif text]` / `$[font.monospace text]` / `$[font.cursive text]`)

#### fn Functions - Special
- Blur (`$[blur text]`)
- Ruby (furigana) (`$[ruby kanji furigana]`)
- Unixtime (`$[unixtime 1234567890]`)

#### fn Functions - Animation
- Spin (`$[spin text]` / `$[spin.x text]` / `$[spin.y text]`)
- Jump (`$[jump text]`)
- Bounce (`$[bounce text]`)
- Shake (`$[shake text]`)
- Twitch (`$[twitch text]`)
- Jelly (`$[jelly text]`)
- Tada (`$[tada text]`)
- Rainbow (`$[rainbow text]`)
- Sparkle (`$[sparkle text]`)

#### Configuration Options
- `MfmRenderConfig` for customizing rendering behavior
- Custom emoji builder support
- Unicode emoji builder support
- Callback support for links, mentions, hashtags, and search
- Custom font family resolver
- Text style customization
- Advanced MFM control (enable/disable position, etc.)
- Inline code/math background color customization

#### Helpers
- `MfmEmojiConfig.quickSetup()` for easy emoji configuration

#### Known Limitations
- **Math Rendering**: LaTeX formulas (`\(formula\)` and `\[formula\]`) are displayed as plain text. Math rendering support is planned for future releases.
- **Nyaize**: Text transformation feature is not yet implemented.
- **Font Types**: Some font types (emoji, math) fall back to default fonts due to platform limitations.
- **Text Selection**: Not supported by design for visual fidelity. If copy functionality is needed, implement it at the app level using the original MFM text.
- **Scale Limits**: Scale function is limited to 5x maximum (same as Misskey's official implementation for security reasons).
