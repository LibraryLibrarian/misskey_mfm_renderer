---
id: rendering
slug: /rendering
title: Rendering MFM
sidebar_label: Rendering MFM
---

`MfmText` renders Misskey Flavored Markdown in a native Flutter widget. Install the published package using [Getting started](getting-started.md); the copyable examples in these guides target that published API, not the development example.

## A bounded rendering area

Place this widget in the body of the Material app from Getting started. Use a Dart **raw string** for `$[...]` so Dart does not interpret `$` as interpolation.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class RenderExample extends StatelessWidget {
  const RenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      child: MfmText(
        text: r'**Hello** $[fg.color=336699 blue] $[x2 large]',
        config: MfmRenderConfig(enableAnimation: false),
      ),
    );
  }
}
```

## Inputs and display modes

| Input | Behavior |
| --- | --- |
| `text` | MFM source; an empty string renders nothing. |
| `parsedNodes` | Previously parsed `List<MfmNode>` from `misskey_mfm_parser`. Reuse it when rendering the same parsed content; it takes precedence over `text`. Declare a direct parser dependency if importing the parser in your app. |
| `simple: true` | Uses the simple parser: ordinary text, mentions, hashtags, URLs and most formatting are not processed as full MFM. Unicode/custom emoji remain supported. |
| `plain: true` | Also uses simple parsing; emoji use the normal-size rendering context. This is not a generic HTML/Markdown sanitizer. |
| `nowrap: true` | A single line with ellipsis. Give the widget a finite available width. |
| `rootScale` | Positive, finite root scale (default `1.0`); it affects MFM rendering, not the app's accessibility preference. |
| `isNote` | Defaults to `true`; changes hashtag navigation details, not the parser. See [Interactions](interactions.md). |

Supply `text` or `parsedNodes`; the constructor asserts that one exists. A parser `FormatException` falls back to the whole source as plain text. This is not a guarantee that every malformed input throws or is sanitized. For per-post host/emoji context, see [Custom emoji](custom-emoji.md).

## Supported syntax

| Category | Examples / behavior |
| --- | --- |
| Text | Bold `**text**`, italic `*text*`, strike `~~text~~`, small `<small>text</small>`, center `<center>text</center>`. |
| Navigation | URLs, `[label](https://example.com)`, `@name`, `#tag`, and search blocks. Navigation is callback-driven. |
| Code and quote | Inline backticks, fenced code blocks with highlighting/copy, and `> quote`. Quotes need bounded layout width. |
| Emoji | Unicode emoji and `:shortcode:`. Server emoji need an emoji builder/resolver. |
| Math | Inline/block math is shown as **monospace text**, not rendered LaTeX. |
| Plain region | `<plain>...</plain>` keeps its contents literal. |

### Function blocks

| Function family | Published behavior |
| --- | --- |
| `x2`, `x3`, `x4`, `scale`, `position` | Size and positioning effects; advanced-MFM settings affect their application. |
| `fg`, `bg`, `font`, `border` | Text/background color, font selection and borders. Do not assume the development example's expanded border options exist in the published package. |
| `flip`, `rotate` | Static transforms. |
| `blur` | Visual blur that can be revealed; not a security or redaction boundary. |
| `ruby`, `unixtime` | Ruby text and timestamp display; see the development differences on the [example page](example.md). |
| `clickable` | Dispatches an event ID through a callback. |
| `jelly`, `tada`, `jump`, `bounce`, `shake`, `twitch`, `spin`, `rainbow`, `sparkle` | Animated/effect functions. See [Animation and accessibility](animation-accessibility.md) for disabling movement. |

Unknown functions retain a literal `$[name ...]` wrapper while rendering their children; no unknown effect is applied. Function support is not a promise of pixel-identical output to Misskey's browser renderer.

## Limitations and troubleshooting

- **No Web support** and **no text selection**. The output uses RichText with embedded widgets, not SelectableText.
- Use a bounded parent, such as `Expanded` inside a Row, if quotes or long content overflow.
- Missing fonts and glyphs are platform-dependent. Set [text/font configuration](configuration.md) rather than assuming identical fonts on every OS.
- `toPlainText()` on a rendered span is not a reliable semantic-text export: embedded widgets and visual transformations can differ from the source. Keep the original source or define an app-specific text conversion.
- A failed/absent custom-emoji resolver leaves a shortcode. It does not mean the MFM parser failed.

Next: [Configuration](configuration.md) · [Custom emoji](custom-emoji.md) · [API reference](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
