---
id: animation-accessibility
slug: /animation-accessibility
title: Animation and accessibility
sidebar_label: Animation and accessibility
---

Animation is enabled by default. By default, `MfmText` also follows the operating system's reduced-motion preference (`MediaQuery.disableAnimations`): while it is on, MFM is rendered exactly as with `enableAnimation: false`, and the output follows changes to the setting.

## Reduced motion

`followPlatformReducedMotion` controls this behavior.

| Value | Result |
| --- | --- |
| `null` (default) or `true` | Follow the OS setting. When it is on, MFM animation stops and the static rendering described below is used. |
| `false` | Ignore the OS setting. Only `enableAnimation` / `enableAdvancedMfm` decide whether MFM animates. |

The OS setting can only stop animation; it never re-enables animation disabled through `enableAnimation: false`. A child configuration's explicit `true` / `false` overrides its parent, and `null` inherits the parent's value. `MfmRenderConfig.useAnimation` is computed from the configuration only and does not include the OS setting.

If your application has its own “disable effects” preference, combine it with `enableAnimation`. To let users play MFM animation even when the OS setting is on, also set `followPlatformReducedMotion: false`. Use this widget below the `MaterialApp` in [Getting started](getting-started.md).

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MotionExample extends StatelessWidget {
  const MotionExample({super.key, required this.userPrefersAnimation});

  /// Application preference, for example initialized from the OS setting.
  final bool userPrefersAnimation;

  @override
  Widget build(BuildContext context) {
    return MfmText(
      text: r'$[tada Hello] $[rainbow Color]',
      config: MfmRenderConfig(
        enableAnimation: userPrefersAnimation,
        // The application preference already reflects the OS setting.
        followPlatformReducedMotion: false,
      ),
    );
  }
}
```

## Two switches, different purposes

| Setting | Result |
| --- | --- |
| `enableAnimation: false` | Disables MFM animation while retaining static formatting/effects where implemented. `tada` remains enlarged, `rainbow` becomes a static gradient, and `sparkle` retains its contents without the effect. |
| `enableAdvancedMfm: false` | Also disables advanced size/position behavior; this is not merely a reduced-motion switch. |
| OS reduced motion with `followPlatformReducedMotion` `null`/`true` | Same rendering as `enableAnimation: false`. |
| Both enabled | MFM animations are allowed (`useAnimation == true`). |

Neither flag stops animated **GIF/APNG/WebP emoji images**. Control those through your image/emoji builder and application policy, for example by supplying still images. A parent configuration with animations disabled cannot be undone simply by passing the default `true` to a child; see [Configuration](configuration.md).

MFM animation `speed`/`delay` arguments use seconds, for example `$[spin.speed=2s text]`, not `2000ms`. Keep `$[...]` in Dart raw strings.

## Reading, focus and hidden content

- `blur` is only a visual effect. Its contents are not excluded from semantics and may be read by assistive technology. **Never use it to hide confidential data.**
- Ruby and embedded WidgetSpans can produce reading order or pronunciation that differs from the visual text. Check with TalkBack/VoiceOver on your actual target rather than assuming full accessibility compliance.
- Text selection is not implemented. If copying or an alternative reading view is required, provide it at the application level using the original content and explicit text-conversion rules.
- Provide meaningful labels for your custom emoji/interaction widgets and adequate contrast in both MFM color schemes. Code-copy labels are described in [Interactions](interactions.md).
- Test larger system text sizes, long links, quotes, and keyboard/focus navigation in the enclosing screen. A screenshot does not establish screen-reader support.

## Performance and troubleshooting

For dense timelines, avoid unnecessarily rebuilding resolver/config instances, reuse parsed nodes for unchanged content, and bound the number of visible animated widgets. Profile on target hardware before choosing a policy. The library does not guarantee a particular frame rate or automatically pause every offscreen effect.

If movement persists with MFM animation disabled, first distinguish image animation from MFM effects. If large/static effects also need disabling, consider `enableAdvancedMfm: false` and check the visual result. If reduced motion seems ignored, confirm that `followPlatformReducedMotion` is not `false` in the explicit or inherited configuration and that the `MediaQuery` above `MfmText` reports `disableAnimations`.

Next: [Rendering](rendering.md) · [Custom emoji](custom-emoji.md) · [Example app](example.md)
