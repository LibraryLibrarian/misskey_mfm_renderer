# Example screenshot provenance

These two images illustrate the **development example**, not the published package's visual contract. Both are original full-screen Android PNG captures, without cropping, resizing, retouching or generated content. They contain synthetic sample text and no account data. No iOS capture or iOS visual-verification claim is included.

## Source and build

- Source commit: `3ecc3b20bf9085c6c0e049fd89f6c47dbb488167` (merged PR1 on develop).
- Fresh isolated source snapshot, with only the Android `applicationId` changed to `dev.librarylibrarian.mfmdocs.capture` for capture. Namespace and launcher activity remained unchanged. The repository's example was not modified.
- Flutter 3.38.7 / Dart 3.10.7; Android arm64 debug APK with `--dart-define=MFM_EXAMPLE_OFFLINE=true`.
- Example uses the parent renderer through `path: ../`. The capture source predates these documentation changes.
- `example/pubspec.lock` SHA-256: `91b6500a79a4013920084663d1310fb681ab80531b38da8c16ab6b4d876be2d9`. This is the lock used by the example build; no root lockfile was present in the archived library source.
- APK package/launcher and signature were checked before installation on the fresh, session-owned emulator. No physical device or pre-existing application was used.

## Environment and shared settings

- Android 13 / API 33, `google_apis` arm64 system image; Android Emulator 37.2.12.0.
- Pixel 4 AVD profile with initial display configuration **720 × 1280 px**, **320 dpi / DPR 2.0** (360 × 640 logical pixels); full status/navigation bars retained.
- Text scale **1.0**, app locale **Japanese (`ja`)**, emulator timezone **Asia/Tokyo**. The example's supported locale list selects Japanese; the emulator's `persist.sys.locale` property was unset.
- App theme setting: system; system night mode explicitly off, yielding the **light** theme. Default app/MFM palette, no custom color scheme.
- Fresh app defaults: advanced MFM on, animation on, nyaize disabled, simulated author-is-cat off, remote author off, emoji URL map off, emoji context display off, plain off, nowrap off, rootScale 1, isNote true, code-copy button on.
- Offline startup skips the online custom-emoji service. The selected samples have no network images, Twemoji artwork, animation or clock-dependent MFM; no server synchronization is represented by the captures.
- `使用設定` was not expanded. No settings were changed between the catalog and Playground captures. A settings-screen capture was retained locally as evidence but is not a site asset.

## Images

| File (under `static/img/`) | Capture time (host clock, JST / UTC+09:00) | Content |
| --- | --- | --- |
| `example-text-format-android-develop.png` | 2026-10-20 00:52:37.200935 | Catalog → テキスト整形, at the top, showing Bold and Italic. The lower card continues below the scroll viewport. |
| `example-playground-android-develop.png` | 2026-10-20 00:53:14.385486 | Bold sample loaded through この設定で試す, including its settings. Source `**太字テキスト**`, no edits, keyboard closed. |

The emulator status bar displayed a 12-hour clock; precise provenance timestamps above come from the host capture process, not the visible status-bar label.

SHA-256:

```text
d5a778208b942c7b360dac7eb1c7176e92153d42e3becda87bf1abc14654ed51  example-text-format-android-develop.png
fb8c6c974f39d185bf04a577abddaf99331dd7c131ba050aa071e837e411aef6  example-playground-android-develop.png
```

Repository copies were checked byte-for-byte against the retained original PNGs. Each was visually inspected before inclusion. Both are below 1 MB (50,193 and 41,290 bytes respectively).

## Reproduction and scope

1. Use the recorded source revision and Flutter SDK in a separate checkout; choose a dedicated capture app ID and a fresh emulator rather than overwriting an existing app.
2. Build with the offline flag, then launch on the verified owned target. Keep default shared settings, light system mode and text scale 1.0.
3. Open テキスト整形 and capture the top of the catalog. Select この設定で試す on Bold and capture Playground without editing or opening the keyboard.
4. Retain original full PNGs, record environment/source/lock hashes and capture timestamps, inspect for personal data, and update both locale captions together.

Captures do not establish pixel identity across OSes, font versions or future revisions, nor do they validate screen readers or real-server emoji synchronization. The capture script's immediate shutdown check returned nonzero because ADB still listed the exiting emulator; a later read-only check confirmed the owned process and device were absent. The original failure record and later confirmation were kept separately.
