---
id: configuration
slug: /configuration
title: Configuration
sidebar_label: Configuration
---

Use `MfmRenderConfig` for rendering preferences and callbacks. `MfmConfig` shares a config with descendant `MfmText` widgets. There is no `MfmRenderOptions` type.

## Share a configuration

Place this widget in the app from [Getting started](getting-started.md). For a single widget, pass the same config through `MfmText(config: ...)` instead.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class ConfigExample extends StatelessWidget {
  const ConfigExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MfmConfig(
      config: MfmRenderConfig(
        baseTextStyle: TextStyle(fontSize: 18, height: 1.5),
        enableAnimation: false,
        nyaizeMode: MfmNyaizeMode.disabled,
        codeCopyTooltip: 'Copy code',
        codeCopiedMessage: 'Code copied',
      ),
      child: MfmText(text: '**Shared style** and `inline code`'),
    );
  }
}
```

## Defaults and inheritance

| Setting | Default / resolution |
| --- | --- |
| `enableAdvancedMfm`, `enableAnimation` | Both `true`; `useAnimation` is their logical AND. |
| `enableNyaize` | `false`; prefer an explicit `nyaizeMode` for new code. |
| `baseTextStyle` | Configured style, otherwise `DefaultTextStyle`; a missing font size falls back to 14. |
| `brightness` | Explicit value, then Material theme, Cupertino theme, platform brightness, with a light fallback. |
| `lightColorScheme`, `darkColorScheme` | Inherited values or `MfmColorScheme.light()` / `.dark()` presets. Ambient **brightness**, not all ambient theme colors, is adopted automatically. |
| `codeTheme`, `codeDarkTheme` | Light: github. Dark: explicit dark theme, then `codeTheme`, then atom-one-dark (`atomOneDarkTheme`). |
| `showCodeBlockCopyButton` | `null` means shown. Set `false` to hide it. |
| `useLocaleSearchButtonLabel` | `false`. Labels are locale-derived when `searchButtonLabel` is absent. Set `true` to clear an explicit/inherited label and use the current locale; it takes precedence over `searchButtonLabel`. |

Nullable fields generally fall back to inherited settings. **Default-valued booleans are not unconditional overrides**: a child's `enableAnimation: true` does not re-enable animation disabled by the parent. Put the effective choice at the shared configuration boundary instead of trying to undo it per note. `MfmConfig` notifies dependents when the config instance changes; reuse stable instances where practical, but rebuild when theme or accessibility inputs change.

## Colors, fonts and code

Provide `lightColorScheme` / `darkColorScheme` to customize MFM links, mentions, quotes, code and other colors. Their `copyWith` methods are useful for changing only selected roles. Verify contrast in both themes.

`fontFamilyResolver` maps MFM font types (such as `serif` or `monospace`) to font-family names. Return `null` to use defaults. A resolver does not load fonts: bundle and declare any custom fonts in the application. No Google Fonts dependency is required by this library.

`codeTheme` and `codeDarkTheme` accept maps of highlight styles. A custom light `codeTheme` is also the dark fallback unless you supply `codeDarkTheme`; avoid accidentally using low-contrast light styling in dark mode. Code-copy callbacks and labels are covered in [Interactions](interactions.md).

## Cat-language conversion

- `MfmNyaizeMode.disabled`: no conversion.
- `MfmNyaizeMode.enabled`: convert eligible text regardless of author.
- `MfmNyaizeMode.respectAuthor`: convert when `author.isCat` is true.

An explicit mode takes precedence over the legacy `enableNyaize` flag. This is a rendering choice; it does not update an account or rewrite stored MFM.

## Copying and clearing context

`copyWith(field: null)` keeps the existing field; it does **not** clear it. The published context reset flags are `clearAuthor`, `clearEmojiUrls`, and `clearLocalHost`. For example, `config.copyWith(clearAuthor: true, clearEmojiUrls: true)` removes post-specific context before reuse. Do not pass both a value and its matching clear flag: this throws. Clearing a local config does not remove values inherited from an enclosing `MfmConfig`.

An emoji handle's `copyWith` shares lifecycle ownership; it is not a new independently disposable resource. See [Custom emoji](custom-emoji.md).

## Troubleshooting

If a setting seems ignored, check the nearest `MfmConfig`, default-valued booleans, and `enableAdvancedMfm`. If colors differ from the app theme, explicitly supply MFM color schemes rather than expecting automatic color mapping.

Next: [Custom emoji](custom-emoji.md) · [Animation and accessibility](animation-accessibility.md) · [MfmRenderConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmRenderConfig-class.html)
