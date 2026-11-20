---
id: custom-emoji
slug: /custom-emoji
title: Custom emoji
sidebar_label: Custom emoji
---

Server-specific `:shortcodes:` need an emoji configuration. Without a builder, they remain literal text. Install the renderer as described in [Getting started](getting-started.md).

## Default catalog and storage

`MfmEmojiConfig.createDefault` connects a caller-owned `MisskeyClient` to a persistent catalog, resolver and image builder. It returns a **handle**, not just a config. The default storage directory is the app's documents directory; `storagePath` overrides it. The default store uses SQLite/Drift. Keep the handle alive at a screen/application scope, not separately for every timeline note.

The example below accepts an already-created client. Because it directly imports `misskey_client`, declare that as a direct application dependency (compatible with `^1.0.0-beta.6`, not the older beta.5). It uses online background synchronization by default. Supply a real, intentionally selected server client only when you want that network access.

Mount this widget under the app from Getting started. Treat its client as fixed for the widget's lifetime; replace the widget with a new key when changing servers. The client must remain valid until asynchronous handle cleanup finishes. For application-wide shutdown where that ordering must be awaited, own the handle outside `State` and await its disposal before closing the client.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class EmojiExample extends StatefulWidget {
  const EmojiExample({super.key, required this.client});

  final MisskeyClient client;

  @override
  State<EmojiExample> createState() => _EmojiExampleState();
}

class _EmojiExampleState extends State<EmojiExample> {
  late final Future<MfmEmojiConfigHandle> _pending;
  MfmEmojiConfigHandle? _handle;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _pending = MfmEmojiConfig.createDefault(client: widget.client);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final handle = await _pending;
      if (mounted) setState(() => _handle = handle);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _close() async {
    MfmEmojiConfigHandle handle;
    try {
      handle = await _pending;
    } catch (_) {
      return; // Initialization failed; no handle was returned.
    }
    try {
      await handle.dispose();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('while disposing the emoji handle'),
      ));
    }
  }

  @override
  void dispose() {
    unawaited(_close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return const Text('Emoji initialization failed');
    final handle = _handle;
    if (handle == null) return const CircularProgressIndicator();
    return MfmText(text: ':smile:', config: handle);
  }
}
```

## Ownership and asynchronous cleanup

The example waits for initialization even if the widget is removed before it finishes, then disposes the returned handle. Flutter's `State.dispose` cannot be asynchronous; cleanup runs separately and reports disposal errors. Do not drop the initialization Future and lose a late-created handle.

- `await handle.dispose()` is idempotent and waits for background synchronization before closing its catalog/store.
- It **does not dispose the caller's client**.
- Copies made with `handle.copyWith(...)` share lifecycle state. Disposing any copy disposes the shared resources; do not dispose one per note.
- `autoSync: false` disables initial background sync. `onSyncError` lets the app observe synchronization failures; successful handle creation alone does not prove that a server sync succeeded.
- `emojiRefreshListenable` can notify rendered emoji when catalog data changes. Default auto-sync also supplies refresh notifications.

## Remote-post context

Derive a per-post config from `handle` and supply `author: MfmAuthorContext(host: 'remote.example')` together with `emojiUrls`, a name-to-image-URL map from the post. Local authors have a null host. The helper's `localHost` comes from the client's origin.

Treat the map as immutable and replace it when data changes. **A present map that lacks the requested shortcode means literal fallback**; it is not equivalent to an absent map. Clear stale post context with the [published clear flags](configuration.md) when reusing configurations.

## Existing resolver or custom builder

If your application already owns a catalog/resolver, use `MfmEmojiConfig.fromResolver(resolver: ..., serverBaseUrl: ...)`. It returns a config, not an owning handle: the caller must dispose its own catalog/store. `serverBaseUrl` enables remote fallback URLs when no direct URL is available; without it, unresolved remote emoji stay shortcodes.

For complete control, `emojiBuilder` receives `(String name, MfmEmojiContext context)`. `unicodeEmojiBuilder` receives the Unicode string and the same context. Return a Widget and supply your own loading/error/semantics behavior. This published context exposes `fontSize`, `scale`, `normal`, `host`, `url` and `useOriginalSize`; it does **not** have the development-only `textStyle` field. A custom resolver or direct URL controls network access, so apply the application's media/host policy there.

## Size, baseline and cache

- Helper defaults: height **2em**, or **1.25em** for the normal/plain context. `emojiSize` specifies a fixed height, not a minimum. Standalone `MfmCustomEmoji.size` defaults to 24.
- For a builder matching the helper, the baseline offset is `size / 2 - context.fontSize * 0.25`; in the normal/plain context it is `context.fontSize * 0.25` instead. Do not multiply the image by `context.scale` again: the enclosing paint transform already applies scale.
- `emojiMaxWidth` caps width. `useOriginalSize` is a hint for custom builders; the helper cannot automatically choose original versus thumbnail URLs when the resolver does not distinguish them.
- URL and aspect-ratio caches are process-wide LRUs with 256 entries each. `cacheScope` isolates identities. The default uses the resolver identity or direct URL; recreating resolver closures on every build can defeat reuse.

## Platforms and troubleshooting

Native Android/iOS/macOS/Linux/Windows are supported; Web is not. Follow native storage/network setup in the [example README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md). Build-time SQLite/dependency downloads are distinct from runtime sync.

If shortcodes remain, check the resolver, server origin, per-post host/map, synchronization errors, image availability and native network permissions. Do not log tokens or assume a shortcode fallback proves an authentication error. For deterministic local tests, disable auto-sync and inject fake storage/resolvers; those tests do not validate real-server synchronization.

Next: [Configuration](configuration.md) · [Interactions](interactions.md) · [MfmEmojiConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmEmojiConfig-class.html)
