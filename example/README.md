# example

Example app for `misskey_mfm_renderer` that demonstrates:

- MFM rendering with custom emoji support
- Quick setup using `MfmEmojiConfig`
- Catalog and playground screens for MFM syntax

## Quick Start

Run the app on a supported device:

```bash
flutter run -d android
flutter run -d ios
flutter run -d macos
flutter run -d linux
flutter run -d windows
```

The app initializes emoji support once at startup and shares the configuration
through `MfmConfig`, so any `MfmText` widget renders custom emojis out of the box.

## Offline Twemoji samples

The emoji catalog retains the native `Unicode Emoji` sample and adds two
explicitly configured `MfmTwemojiBuilder` samples. Those two samples use only the
eight bundled PNGs in [`assets/twemoji`](assets/twemoji/); they never select a CDN.
Their filename allowlist returns null for an unavailable image (for example 🚀),
so the original Unicode remains visible. The helper is configured per example,
not as a global setting. This does not remove the app's separate custom-emoji
initialization at startup.

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
