---
id: custom-emoji
slug: /custom-emoji
title: Benutzerdefinierte Emojis
sidebar_label: Benutzerdefinierte Emojis
---

Serverspezifische `:shortcodes:` benötigen eine Emoji-Konfiguration. Ohne Builder bleiben sie wörtlicher Text. Installiere den Renderer wie unter [Erste Schritte](getting-started.md) beschrieben.

## Standardkatalog und Speicher

`MfmEmojiConfig.createDefault` verbindet einen vom Aufrufer verwalteten `MisskeyClient` mit einem persistenten Katalog, Resolver und Bild-Builder. Es liefert ein **Handle**, nicht nur eine Konfiguration. Standardmäßig wird das Dokumentenverzeichnis der App verwendet; `storagePath` überschreibt es. Der Standardspeicher verwendet SQLite/Drift. Halte das Handle auf Bildschirm- oder Anwendungsebene vor, nicht separat für jeden Timeline-Beitrag.

Das folgende Beispiel erhält einen bereits erzeugten Client. Wegen des direkten Imports muss die App `misskey_client` als direkte Abhängigkeit deklarieren (kompatibel mit `^1.0.0-beta.6`, nicht mit der älteren beta.5). Standardmäßig findet Online-Hintergrundsynchronisierung statt. Übergib nur dann einen echten Client für einen bewusst gewählten Server, wenn dieser Netzwerkzugriff gewünscht ist.

Platziere das Widget unter der App aus „Erste Schritte“. Der Client bleibt während der Widget-Lebensdauer unverändert; ersetze das Widget beim Serverwechsel mit einem neuen Key. Der Client muss bis zum Ende der asynchronen Handle-Freigabe gültig bleiben. Muss diese Reihenfolge beim Beenden der Anwendung abgewartet werden, verwalte das Handle außerhalb von `State` und warte vor dem Schließen des Clients auf seine Freigabe.

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

## Ressourcenverantwortung und asynchrone Freigabe

Das Beispiel wartet auch dann auf die Initialisierung, wenn das Widget vorher entfernt wird, und gibt anschließend das zurückgelieferte Handle frei. Flutter erlaubt kein asynchrones `State.dispose`; die Bereinigung läuft separat und meldet Freigabefehler. Verwirf das Initialisierungs-Future nicht, sonst geht ein später erzeugtes Handle verloren.

- `await handle.dispose()` ist idempotent und wartet vor dem Schließen von Katalog/Speicher auf die Hintergrundsynchronisierung.
- Der **Client des Aufrufers wird nicht freigegeben**.
- Kopien aus `handle.copyWith(...)` teilen den Lebenszyklus. Die Freigabe einer Kopie gibt die gemeinsamen Ressourcen frei; nicht pro Beitrag freigeben.
- `autoSync: false` deaktiviert die anfängliche Hintergrundsynchronisierung. `onSyncError` macht Synchronisierungsfehler beobachtbar; ein erfolgreich erzeugtes Handle beweist keine erfolgreiche Serversynchronisierung.
- `emojiRefreshListenable` kann gerenderte Emojis bei Katalogänderungen benachrichtigen. Die standardmäßige automatische Synchronisierung stellt ebenfalls Aktualisierungsbenachrichtigungen bereit.

## Kontext entfernter Beiträge

Leite aus `handle` eine Konfiguration pro Beitrag ab und übergib `author: MfmAuthorContext(host: 'remote.example')` zusammen mit `emojiUrls`, der Zuordnung von Emoji-Namen zu Bild-URLs aus dem Beitrag. Lokale Autoren haben einen null-Host. `localHost` des Helpers stammt vom Origin des Clients.

Behandle die Map als unveränderlich und ersetze sie bei Datenänderungen. **Eine vorhandene Map ohne den angefragten Shortcode bedeutet wörtlichen Fallback**; sie ist nicht gleichbedeutend mit einer fehlenden Map. Entferne veralteten Beitragskontext bei Wiederverwendung mit den [veröffentlichten Rücksetzflags](configuration.md).

## Vorhandener Resolver oder eigener Builder

Wenn deine App bereits einen Katalog/Resolver verwaltet, verwende `MfmEmojiConfig.fromResolver(resolver: ..., serverBaseUrl: ...)`. Das Ergebnis ist eine Konfiguration, kein ressourcenbesitzendes Handle: Katalog/Speicher bleiben vom Aufrufer freizugeben. `serverBaseUrl` ermöglicht entfernte Fallback-URLs, falls eine direkte URL fehlt; ohne diese Angabe bleiben nicht aufgelöste entfernte Emojis Shortcodes.

Für vollständige Kontrolle erhält `emojiBuilder` `(String name, MfmEmojiContext context)`. `unicodeEmojiBuilder` erhält den Unicode-String und denselben Kontext. Gib ein Widget zurück und implementiere Laden, Fehlerbehandlung und Semantik selbst. Der veröffentlichte Kontext bietet `fontSize`, `scale`, `normal`, `host`, `url` und `useOriginalSize`, **nicht** das nur in der Entwicklungsversion vorhandene `textStyle`. Eigene Resolver oder direkte URLs steuern den Netzwerkzugriff; wende dort die Medien-/Host-Richtlinien der App an.

## Größe, Grundlinie und Cache

- Helper-Standardhöhe: **2em**, im normalen/plain-Kontext **1.25em**. `emojiSize` gibt eine feste Höhe an, keine Mindesthöhe. Ein eigenständiges `MfmCustomEmoji.size` hat den Standardwert 24.
- Ein zum Helper passender Builder verwendet den Grundlinienversatz `size / 2 - context.fontSize * 0.25`, im normalen/plain-Kontext hingegen `context.fontSize * 0.25`. Multipliziere das Bild nicht erneut mit `context.scale`: die umgebende Zeichentransformation skaliert bereits.
- `emojiMaxWidth` begrenzt die Breite. `useOriginalSize` ist ein Hinweis für eigene Builder; ohne Unterscheidung im Resolver kann der Helper nicht automatisch zwischen Original- und Vorschaubild-URLs wählen.
- URL- und Seitenverhältnis-Caches sind prozessweite LRUs mit jeweils 256 Einträgen. `cacheScope` trennt Identitäten. Standardmäßig gilt die Resolver-Identität oder direkte URL; neu erzeugte Resolver-Closures bei jedem Build können die Wiederverwendung verhindern.

## Plattformen und Fehlersuche

Unterstützt werden native Android-/iOS-/macOS-/Linux-/Windows-Ziele, nicht Web. Hinweise zu nativem Speicher und Netzwerk stehen in der [Beispiel-README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md). SQLite-/Abhängigkeitsdownloads beim Build sind von der Synchronisierung zur Laufzeit zu unterscheiden.

Prüfe bei stehenbleibenden Shortcodes Resolver, Server-Origin, beitragsspezifischen Host/Map, Synchronisierungsfehler, Bildverfügbarkeit und native Netzwerkberechtigungen. Protokolliere keine Tokens und werte einen Shortcode-Fallback nicht als Beweis eines Authentifizierungsfehlers. Für deterministische lokale Tests automatische Synchronisierung ausschalten und Fake-Speicher/Resolver injizieren; solche Tests prüfen keine echte Serversynchronisierung.

Weiter: [Konfiguration](configuration.md) · [Interaktionen](interactions.md) · [MfmEmojiConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmEmojiConfig-class.html)
