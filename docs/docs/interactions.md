---
id: interactions
slug: /interactions
title: Interactions
sidebar_label: Interactions
---

The renderer reports interactions; your application decides what they mean. It does **not** automatically launch URLs, navigate to profiles, or send search requests.

## Local feedback example

Place this widget inside a `Scaffold` below a `MaterialApp` (as in [Getting started](getting-started.md)). All actions show a local SnackBar; no launcher dependency or real account is needed.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class InteractionExample extends StatelessWidget {
  const InteractionExample({super.key});

  @override
  Widget build(BuildContext context) {
    void show(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return MfmText(
      text: '[Example](https://example.com) @alice #flutter\n'
          'Flutter Search\n'
          r'$[clickable.ev=demo Tap me]',
      config: MfmRenderConfig(
        localHost: 'example.com',
        onLinkTap: (url) => show('Link: $url'),
        onMentionTap: (acct) => show('Mention: $acct'),
        onHashtagTapDetails: (details) => show('Tag path: ${details.path}'),
        onSearchTap: (query) => show('Search: $query'),
        onClickableEvent: (eventId) => show('Event: $eventId'),
        onCodeCopied: (code) => show('Copied ${code.length} characters'),
        codeCopyTooltip: 'Copy code',
      ),
    );
  }
}
```

## Callback contracts

| Callback | Value and behavior |
| --- | --- |
| `onLinkTap` | Original source URL, not a trusted/sanitized destination. With no callback, there is no automatic launch. |
| `onMentionTap` | Normalized account. Host resolution uses an explicit mention host, then `author.host`, then `localHost`; without a host it retains the raw account. |
| `onHashtagTapDetails` | Tag, `isNote` and encoded navigation path. Takes precedence over `onHashtagTap`. |
| `onHashtagTap` | Tag-only fallback when the details callback is absent. |
| `onSearchTap` | The search query; the published search display is not the development example's editable field. |
| `onClickableEvent` | The `ev` value in `$[clickable.ev=demo ...]`; missing `ev` yields an empty string. Without this callback, the contents are ordinary text. |
| `onCodeCopied` | Full code after clipboard copying. Replaces the default success SnackBar, not the clipboard write itself. |

For hashtags, `isNote: true` produces `/tags/<encoded-tag>`; `false` produces `/user-tags/<encoded-tag>`. These are relative paths, not an automatic choice of server or navigator.

## URL and event policy belongs to the app

Treat callback values as untrusted post content. Before launching, validate the URI scheme and destination according to your app's policy; do not blindly pass arbitrary schemes to a launcher. Profile/server selection, authentication, external-navigation confirmation and allowed clickable event IDs are also application responsibilities. Do not interpret a clickable event ID as executable code.

## Copy feedback and accessibility

The copy button is shown by default. `showCodeBlockCopyButton: false` hides it. `codeCopyTooltip` is the button's **Semantics label**, not a visible hover tooltip. Without `onCodeCopied`, the default success SnackBar is shown only when a `ScaffoldMessenger` exists; `codeCopiedMessage` changes that message. Defaults are localized for Japanese/other locales.

Keep `uses-material-design: true` in the application's Flutter configuration when using the built-in Material icon glyphs. Provide equivalent labels and focus behavior if replacing interaction widgets yourself.

## Troubleshooting

If tapping does nothing, confirm that the corresponding callback exists and that full parsing is enabled (not `simple`/`plain`). If both hashtag callbacks are supplied, only the details callback is used. If a mention goes to the wrong host, check the per-post `author` and shared `localHost` rather than guessing from the displayed text.

Next: [Configuration](configuration.md) · [Custom emoji](custom-emoji.md) · [Animation and accessibility](animation-accessibility.md)
