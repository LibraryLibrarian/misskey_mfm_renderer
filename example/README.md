# example

Example app for `misskey_mfm_renderer` that demonstrates:

- MFM rendering with custom emoji support
- Quick setup using `MfmEmojiConfig`
- Catalog and playground screens for MFM syntax

## Quick Start

Run from this `example/` directory with the repository's pinned Flutter SDK
(`fvm flutter` may be used instead of `flutter`):

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

The default startup initializes misskey.io custom emoji support once and shares
it through `MfmConfig`. The settings drawer distinguishes successful online sync,
intentional offline startup, and initialization failure. Link, mention, hashtag,
clickable, and search actions only show a SnackBar; they do not open a browser or
perform a search request.

This app uses `misskey_mfm_renderer` through `path: ../`. It demonstrates the
checked-out source, including `[Unreleased]` features, not necessarily the latest
version published on pub.dev. No new runtime dependencies are needed for the
showcase controls.

### Offline startup

```bash
flutter run -d <device-id> --dart-define=MFM_EXAMPLE_OFFLINE=true
```

This skips `EmojiService.initialize()` entirely: no custom-emoji client, store, or
sync is initialized. Online-only remote-author and emojiUrls controls remain
disabled. Ordinary misskey.io emoji samples show shortcodes; the explicitly
configured fallback, avatar, and Twemoji samples work without network access.
The shared base configuration stays empty—fixtures are local to their samples.

This is a runtime startup option, not a fully offline build guarantee. Dependency
resolution and the SQLite build hook may still require network access. It does
not add Web store support or prevent networking in an arbitrary configuration
injected by an embedding app.

## Catalog → Playground

Each sample may include a visible setup summary and an expandable **使用設定**
(used settings) section. Code is a short Dart excerpt, not a standalone program;
helper functions and bundled assets are identified where needed.

- **MFMをコピー** copies only the MFM text, never Dart settings.
- **この設定で試す** opens that same sample in Playground with its `config`,
  `plain`, and `nowrap` overrides. This is the route to reproduce the card's
  rendering while editing.
- Editing text retains the sample's settings. Loading another sample replaces
  all previous overrides; reloading the same sample also resets preview-local
  state such as search drafts.
- **本文をクリア** empties the text while retaining the sample settings.
- Replacing or clearing edited, non-empty text asks for confirmation. Canceling
  keeps the text, selected example, and current tab unchanged.
- Reset in the settings drawer affects only shared settings. Tab changes and
  switching between narrow/wide layouts retain editor state.

The renderer's normal `MfmConfig` inheritance rules still apply; this app does
not implement a separate merge algorithm. Explicit per-sample `plain`/`nowrap`
override the shared switches. `mentionOptions`, `unixtimeOptions`, and author
context are whole objects, not field-by-field merges. Unspecified settings,
callbacks, and themes continue to inherit. The emoji-context tooltip switch
wraps only the shared emoji builder; samples with their own builders bypass it.

## What to inspect

| Samples | Settings / behavior |
| --- | --- |
| Mention Capsule / Mention Text | `viewerAcct`, `localHost`, capsule/text presentation, self-mention colors |
| Mention Avatar (offline) | Bundled demo avatar for Alice, null-provider placeholder for Bob, 1.5em slots; no `localOrigin` network endpoint |
| Custom Emoji (存在しない / フォールバックの継承) | Stable null resolver via `MfmEmojiConfig.fromResolver`, actual `MfmCustomEmoji` fallback, natural 1em baseline, bold/small inheritance |
| Display Name | `plain=true`, `nowrap=true`, remote author and emojiUrls with a non-network builder |
| Unixtime | Japanese/English, detail/absolute/relative, legacy formatter and `autoUpdate=false` |
| URL (自ホスト) / labelled links | Explicit local host, external icon; label and icon notify the same callback |
| Search | Editable query, button/keyboard submission, including empty text |
| Twemoji | Eight local images, native Unicode fallback, inherited sizes |
| Style / border / delayed animation | Existing inheritance, border styles/clipping, and positive-delay examples |

The avatar and missing-emoji fixtures are in
[`offline_example_fixtures.dart`](lib/core/emoji/offline_example_fixtures.dart).
They fix the author to local context so the shared remote-author setting does
not change the demonstrated code path. The avatar is a Twemoji illustration,
not a real user's photo. Its attribution requirements are the same as below.

## Reproducible screenshots

Use offline startup and reset shared settings before selecting a named sample.
Record the checkout revision (and any uncommitted diff), lockfiles, Flutter/OS
versions, device size and DPR, text scale, theme, locale, capture date/time and
timezone, sample name, shared settings, and whether **使用設定** is expanded.
For Playground, also record whether the sample was loaded with its settings or
only its MFM was pasted, plus any edits. Wait for bundled images to decode.

Unixtime uses the real clock and local timezone; relative labels change over
time. Animations are not frozen by a screenshot mode. Use matching conditions
for before/after images, and retain original PNGs for later multilingual
Docusaurus documentation. This change does not create or publish that site.

## Offline Twemoji samples

The emoji catalog retains the native `Unicode Emoji` sample and adds two
explicitly configured `MfmTwemojiBuilder` samples. Those two samples use only the
eight bundled PNGs in [`assets/twemoji`](assets/twemoji/); they never select a CDN.
Their filename allowlist returns null for an unavailable image (for example 🚀),
so the original Unicode remains visible. The helper is configured per example,
not as a global setting. The separate custom-emoji initialization is skipped
only when the offline startup flag is enabled.

Twemoji graphics by Twitter and contributors are licensed under
[CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/). This unmodified subset
comes from [Twemoji v17.0.3](https://github.com/jdecked/twemoji/tree/b6b55fef1e8636b540a6d016a4729ca8cdf2e60b).
The asset directory includes the full graphics license, upstream MIT license,
and a manifest of source URLs and SHA-256 hashes. No upstream code is copied
into the builder. Apps reusing the images must provide their own appropriate
attribution and license links; the helper does not add attribution UI.

## Platform Notes

Web is not supported. The example compiles for Web, but `misskey_emoji` does
not provide a Web store yet, so emoji initialization cannot run there.

On macOS, the App Sandbox requires the
`com.apple.security.network.client` entitlement for `MfmEmojiConfig` and image
loading.

The native SQLite library is downloaded from GitHub Releases by the `sqlite3`
build hooks on a clean build, so the first build needs network access.

On Linux, install the following before building:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

Install CJK fonts such as Noto Sans CJK JP to render Japanese glyphs; otherwise
they are shown as missing-glyph boxes.

On Windows, running the app requires the Microsoft Visual C++ Runtime (`VCRUNTIME140.dll`), and building it
requires Visual Studio with the "Desktop development with C++" workload.
