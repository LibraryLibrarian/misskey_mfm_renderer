# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0 - 2026-02-09

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
