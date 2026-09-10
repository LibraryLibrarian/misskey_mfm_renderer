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

## Platform Notes

Web is not supported. The package re-exports `misskey_emoji`, whose Isar
generated code cannot be compiled by dart2js or dart2wasm, so the example does
not build for Web.

On macOS, the App Sandbox requires the
`com.apple.security.network.client` entitlement for `MfmEmojiConfig` and image
loading.

Linux is supported only on x86-64 with glibc 2.38 or later (Ubuntu 24.04 or
later), which is required by the bundled `libisar.so` from
`isar_community_flutter_libs`. Before building, install:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

Install CJK fonts such as Noto Sans CJK JP to render Japanese glyphs; otherwise
they are shown as missing-glyph boxes.

Windows is supported only on x64 because the bundled DLL is x64. Running the app
requires the Microsoft Visual C++ Runtime (`VCRUNTIME140.dll`), and building it
requires Visual Studio with the "Desktop development with C++" workload.
