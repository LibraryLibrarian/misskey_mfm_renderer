# misskey_mfm_renderer

[![pub package](https://img.shields.io/pub/v/misskey_mfm_renderer.svg)](https://pub.dev/packages/misskey_mfm_renderer)

English | [日本語](README.ja.md)

A Flutter widget library for rendering Misskey MFM (Misskey Flavored Markdown),
with custom emoji integration through `misskey_emoji`.

**Documentation:** [English](https://librarylibrarian.github.io/misskey_mfm_renderer/) ·
[日本語](https://librarylibrarian.github.io/misskey_mfm_renderer/ja/) ·
[简体中文](https://librarylibrarian.github.io/misskey_mfm_renderer/zh-Hans/) ·
[Deutsch](https://librarylibrarian.github.io/misskey_mfm_renderer/de/) ·
[Français](https://librarylibrarian.github.io/misskey_mfm_renderer/fr/) ·
[한국어](https://librarylibrarian.github.io/misskey_mfm_renderer/ko/)

These are the publication URLs. If the site is not available yet, read the
[guide sources](https://github.com/LibraryLibrarian/misskey_mfm_renderer/tree/develop/docs/docs)
or the [published API reference](https://pub.dev/documentation/misskey_mfm_renderer/latest/).

## Features

- MFM text formatting, quotes, code highlighting, links, mentions and hashtags.
- Custom emoji resolution, remote-note emoji URLs and cached images.
- MFM functions and animation controls, light/dark color schemes and inherited configuration.
- Application-owned link, mention, hashtag, search and copy callbacks.

Custom emoji syntax is part of MFM. The package includes `misskey_emoji`, but
server-backed rendering still requires resolver configuration and lifecycle
management; see [Advanced Custom Emoji Configuration](#advanced-custom-emoji-configuration).
Math is displayed as monospace text, not rendered LaTeX. Web and selection of
rendered text are not supported. See the [rendering guide](https://librarylibrarian.github.io/misskey_mfm_renderer/rendering/)
for supported syntax and limitations.

## Getting started

Requires **Flutter 3.38.1 or later** and **Dart 3.10.0 or later**. The repository's
development SDK is Flutter 3.38.7. Use Android, iOS, macOS, Linux or Windows, not a
Web target.

Add the published package to your application's `pubspec.yaml`:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

```bash
flutter pub get
```

## Quick Start

In a new or disposable Flutter application, use this as `lib/main.dart`. For an
existing application, add `MfmText` to your screen rather than replacing its entry point.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  runApp(const MfmDemoApp());
}

class MfmDemoApp extends StatelessWidget {
  const MfmDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: MfmText(text: '**Hello** from *MFM*!'),
          ),
        ),
      ),
    );
  }
}
```

This example uses the published dependency, not a local path to `develop`.
The [getting started guide](https://librarylibrarian.github.io/misskey_mfm_renderer/getting-started/)
includes native-device run instructions.

## Documentation

| Guide | Contents |
| --- | --- |
| [Overview](https://librarylibrarian.github.io/misskey_mfm_renderer/) | Scope, dependencies and limitations |
| [Getting started](https://librarylibrarian.github.io/misskey_mfm_renderer/getting-started/) | Installation and first render |
| [Rendering](https://librarylibrarian.github.io/misskey_mfm_renderer/rendering/) | Syntax, parsing and layout |
| [Configuration](https://librarylibrarian.github.io/misskey_mfm_renderer/configuration/) | Inheritance, themes and clear flags |
| [Custom emoji](https://librarylibrarian.github.io/misskey_mfm_renderer/custom-emoji/) | Setup, ownership, remote posts and sizing |
| [Interactions](https://librarylibrarian.github.io/misskey_mfm_renderer/interactions/) | Callbacks, search and copying |
| [Animation and accessibility](https://librarylibrarian.github.io/misskey_mfm_renderer/animation-accessibility/) | Motion settings and accessibility limits |
| [Example](https://librarylibrarian.github.io/misskey_mfm_renderer/example/) | Development app, screenshots and their scope |

### Advanced Custom Emoji Configuration

Follow the [custom emoji guide](https://librarylibrarian.github.io/misskey_mfm_renderer/custom-emoji/)
for `MfmEmojiConfig.createDefault`, `fromResolver`, remote emoji and custom builders.
If you import `misskey_client` directly, declare its dependency as shown there.

`createDefault` returns an `MfmEmojiConfigHandle` usable directly as an
`MfmRenderConfig`. It owns its persistent store: await `dispose()` when its owner
is finished. Copies made with `copyWith` share that lifecycle; disposing any copy
disposes them all. The application retains ownership of the supplied
`MisskeyClient`. `fromResolver` does not take ownership of the resolver.

Tests can inject `emojiStoreFactory` to avoid opening SQLite. Custom `EmojiStore`
implementations must implement `load`, `save`, `clear`, `count` and `sizeInBytes`.
The default store is partitioned by `MisskeyClient.baseUrl`. Opening the same
server and directory while an existing handle still holds it throws `StateError`;
different `storagePath` directories can be used concurrently.

### MkMfm-compatible document props

These belong to `MfmText`, not `MfmRenderConfig`:

- `plain`: uses the simple parser, normalizes CRLF/CR/LF to spaces (including
  supplied `parsedNodes`) and sets `MfmEmojiContext.normal`. The built-in emoji
  config then uses 1.25em height and 0.25em descent. By contrast, `simple: true`
  alone preserves line breaks and the ordinary emoji size.
- `nowrap`: one line, no soft wrapping, with an ellipsis. Quotes keep their margin,
  left border and opacity at their natural inline width.
- `rootScale`: a finite positive initial traversal scale; it does not change the
  root font size or apply a transform.
- `isNote`: selects `/tags/...` versus `/user-tags/...` in the detailed hashtag
  callback. The application performs navigation; supplying `onHashtagTapDetails`
  takes precedence over `onHashtagTap`.

## Technical Notes

### Platform notes

Web is not supported: `misskey_emoji` does not provide a Web store for
`MfmEmojiConfig.createDefault`, and Web rendering has not been tested.

Emoji metadata uses SQLite through Drift. The `sqlite3` 3.x build hooks download
native binaries from GitHub Releases on a clean build. For offline builds or an
internal mirror, configure `hooks.user_defines` in the application's `pubspec.yaml`
(the workspace root's pubspec when using a pub workspace). See the
[`misskey_emoji` documentation](https://pub.dev/packages/misskey_emoji) for settings.

macOS apps using App Sandbox need the `com.apple.security.network.client`
entitlement for `MfmEmojiConfig` and image loading. Windows apps require the
Microsoft Visual C++ Runtime (`VCRUNTIME140.dll`).

### Migrating from Isar cache files

Versions depending on `misskey_emoji` 2.0.0-beta.1 or earlier used Isar. The current
store uses `misskey_emoji_<serverKey>_<hash8>.sqlite` per server and does not read
those old files; the first sync fetches metadata again. Old files only consume
disk space.

To remove them, first dispose **every old handle**, then remove only these files
from the `storagePath` supplied to `MfmEmojiConfig.createDefault` (the application
documents directory when omitted):

```text
<directory>/misskey_emoji_*.isar
<directory>/misskey_emoji_*.isar-lck
```

**Filter by the `misskey_emoji_` prefix.** Unrelated application Isar databases
may exist in the same directory and must not be removed.

### Text Selection

Rendered text is not selectable. Implement copying from the original MFM source
at the application level; `InlineSpan.toPlainText()` is not a guaranteed semantic
export. See [interactions](https://librarylibrarian.github.io/misskey_mfm_renderer/interactions/)
and [accessibility limits](https://librarylibrarian.github.io/misskey_mfm_renderer/animation-accessibility/).

### Scale Limits

The `scale` function is capped at 5x. With `enableAdvancedMfm: false`, it applies
neither a paint transform nor a multiplier to `MfmEmojiContext.scale`; inherited
outer x-function scale is preserved. Its static `TextSpan` children do not
reproduce the upstream empty inline-block line-layout boundary.

### Nested Size Functions

`x2`, `x3` and `x4` share a nesting depth, including mixed combinations. With
advanced MFM enabled, sizes are relative to the parent's effective font size:

- First level: 200%, 400%, 600% respectively.
- Second level: the inner function's `zoom / 2 + 50%` (150%, 250%, 350%).
- Third level and deeper: 100%, with no additional enlargement.

At a 14px base, `$[x2 $[x2 A]]` gives 28px outside and 42px inside;
`$[x2 $[x3 A]]` gives 70px inside. Other node types preserve, but do not increase,
this depth. With `enableAdvancedMfm: false`, font size stays unchanged at every
depth, while nominal context multipliers 2/3/4 still propagate: the latter example
keeps a 14px font but passes scale 6. Disabling only `enableAnimation` does not
change size functions.

### Border clipping

The `border` function's `noclip` argument disables its child paint clipping; it
does not expand ancestor hit regions. Border styles, numeric/color parsing and
clipping behavior have further **unreleased** changes; consult the migration
notes below rather than assuming the development behavior is in the published version.

## Development and unreleased changes

The guides and installation example target the published package. The `develop`
source and example app can contain newer behavior. See
[CHANGELOG — Unreleased](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md#unreleased)
for migration notes on editable search, labelled links, borders, unixtime,
mention capsules and emoji fallbacks, and for opt-in Twemoji support.

The [development example](https://github.com/LibraryLibrarian/misskey_mfm_renderer/tree/develop/example)
is not a guarantee of published-package behavior. The
[pre-site development reference](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/8e530138d977a67bd3b91e69ecd7fbbd9751bd7a/README.md)
preserves the former detailed examples as a historical snapshot, including
unreleased APIs; it is not the current published API reference.

## Additional information

- [API Documentation](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
- [MFM Specification](https://misskey-hub.net/en/docs/for-users/features/mfm/)
- [Issues](https://github.com/LibraryLibrarian/misskey_mfm_renderer/issues)

## License

3-Clause BSD License - see [LICENSE](LICENSE)
