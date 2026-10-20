---
id: interactions
slug: /interactions
title: Interaktionen
sidebar_label: Interaktionen
---

Der Renderer meldet Interaktionen; deine Anwendung bestimmt ihre Bedeutung. URLs werden **nicht** automatisch geöffnet, Profile nicht automatisch aufgerufen und Suchanfragen nicht automatisch gesendet.

## Beispiel für lokale Rückmeldung

Platziere dieses Widget in einem `Scaffold` unter einer `MaterialApp`, wie unter [Erste Schritte](getting-started.md). Alle Aktionen zeigen eine lokale SnackBar; eine Launcher-Abhängigkeit oder ein echtes Konto ist nicht erforderlich.

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

## Callback-Verträge

| Callback | Wert und Verhalten |
| --- | --- |
| `onLinkTap` | Original-URL aus dem Quelltext, kein vertrauenswürdiges/bereinigtes Ziel. Ohne Callback kein automatisches Öffnen. |
| `onMentionTap` | Normalisierter Account. Host-Auflösung: expliziter Host der Erwähnung, dann `author.host`, dann `localHost`; ohne Host bleibt der ursprüngliche Account erhalten. |
| `onHashtagTapDetails` | Tag, `isNote` und kodierter Navigationspfad. Hat Vorrang vor `onHashtagTap`. |
| `onHashtagTap` | Fallback nur mit Tag, wenn der Details-Callback fehlt. |
| `onSearchTap` | Suchanfrage; die veröffentlichte Suchdarstellung ist nicht das bearbeitbare Feld des Entwicklungsbeispiels. |
| `onClickableEvent` | `ev`-Wert aus `$[clickable.ev=demo ...]`; fehlendes `ev` ergibt einen leeren String. Ohne Callback ist der Inhalt gewöhnlicher Text. |
| `onCodeCopied` | Vollständiger Code nach dem Kopieren in die Zwischenablage. Ersetzt die Standard-Erfolgs-SnackBar, nicht den Schreibvorgang in die Zwischenablage. |

Bei Hashtags ergibt `isNote: true` den Pfad `/tags/<encoded-tag>`, `false` hingegen `/user-tags/<encoded-tag>`. Dies sind relative Pfade; Server oder Navigator werden nicht automatisch gewählt.

## URL- und Ereignisrichtlinien gehören in die App

Behandle Callback-Werte als nicht vertrauenswürdigen Beitragsinhalt. Prüfe vor dem Öffnen URI-Schema und Ziel gemäß den App-Richtlinien; übergib beliebige Schemas nicht blind an einen Launcher. Auch Profil-/Serverwahl, Authentifizierung, Bestätigung externer Navigation und erlaubte clickable-Ereignis-IDs liegen bei der App. Eine Ereignis-ID darf nicht als ausführbarer Code interpretiert werden.

## Kopierrückmeldung und Barrierefreiheit

Der Kopierbutton ist standardmäßig sichtbar; `showCodeBlockCopyButton: false` blendet ihn aus. `codeCopyTooltip` ist seine **Semantics-Beschriftung**, kein sichtbarer Hover-Tooltip. Ohne `onCodeCopied` erscheint die Standard-Erfolgs-SnackBar nur bei vorhandenem `ScaffoldMessenger`; `codeCopiedMessage` ändert den Text. Die Vorgaben sind für Japanisch/andere Spracheinstellungen lokalisiert.

Für integrierte Material-Icons muss `uses-material-design: true` in der Flutter-Konfiguration der App bleiben. Stelle gleichwertige Beschriftungen und Fokusverhalten bereit, wenn du Interaktionswidgets ersetzt.

## Fehlersuche

Prüfe bei wirkungslosem Tippen den zugehörigen Callback und die vollständige Parser-Einstellung (nicht `simple`/`plain`). Sind beide Hashtag-Callbacks vorhanden, wird nur der Details-Callback genutzt. Bei falschem Erwähnungs-Host prüfe `author` des Beitrags und das gemeinsame `localHost`, statt aus dem angezeigten Text zu raten.

Weiter: [Konfiguration](configuration.md) · [Benutzerdefinierte Emojis](custom-emoji.md) · [Animation und Barrierefreiheit](animation-accessibility.md)
