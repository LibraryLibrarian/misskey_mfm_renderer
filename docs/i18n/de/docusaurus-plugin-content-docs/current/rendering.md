---
id: rendering
slug: /rendering
title: MFM darstellen
sidebar_label: MFM darstellen
---

`MfmText` stellt Misskey Flavored Markdown in einem nativen Flutter-Widget dar. Installiere das veröffentlichte Paket wie unter [Erste Schritte](getting-started.md) beschrieben. Die kopierbaren Beispiele beziehen sich auf diese veröffentlichte API, nicht auf das Entwicklungsbeispiel.

## Ein begrenzter Darstellungsbereich

Setze dieses Widget in den Body der Material-App aus „Erste Schritte“. Verwende für `$[...]` einen Dart-**Raw-String**, damit Dart `$` nicht als Interpolation interpretiert.

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

## Eingaben und Anzeigemodi

| Eingabe | Verhalten |
| --- | --- |
| `text` | MFM-Quelltext; eine leere Zeichenfolge zeigt nichts an. |
| `parsedNodes` | Bereits geparste `List<MfmNode>` aus `misskey_mfm_parser`. Bei unverändertem Inhalt wiederverwendbar; hat Vorrang vor `text`. Bei direktem Parser-Import muss die App eine direkte Parser-Abhängigkeit deklarieren. |
| `simple: true` | Verwendet den einfachen Parser: gewöhnlicher Text, Erwähnungen, Hashtags, URLs und die meisten Formatierungen werden nicht als vollständiges MFM verarbeitet. Unicode- und benutzerdefinierte Emojis bleiben unterstützt. |
| `plain: true` | Verwendet ebenfalls den einfachen Parser; Emojis nutzen den Kontext für normale Größe. Kein allgemeiner HTML-/Markdown-Sicherheitsfilter. |
| `nowrap: true` | Eine einzelne Zeile mit Auslassungszeichen. Stelle eine endliche verfügbare Breite bereit. |
| `rootScale` | Positiver, endlicher Skalierungsfaktor an der Wurzel (Standard `1.0`); beeinflusst MFM, nicht die Barrierefreiheitseinstellung der App. |
| `isNote` | Standard `true`; verändert Hashtag-Navigationsdetails, nicht den Parser. Siehe [Interaktionen](interactions.md). |

Gib `text` oder `parsedNodes` an; der Konstruktor prüft dies mit einer Assertion. Bei einer `FormatException` des Parsers wird der gesamte Quelltext als Klartext angezeigt. Das garantiert weder, dass jede fehlerhafte Eingabe eine Ausnahme auslöst, noch eine Sicherheitsbereinigung. Host-/Emoji-Kontext pro Beitrag: [Benutzerdefinierte Emojis](custom-emoji.md).

## Unterstützte Syntax

| Kategorie | Beispiele / Verhalten |
| --- | --- |
| Text | Fett `**text**`, kursiv `*text*`, durchgestrichen `~~text~~`, klein `<small>text</small>`, zentriert `<center>text</center>`. |
| Navigation | URLs, `[label](https://example.com)`, `@name`, `#tag` und Suchblöcke. Navigation erfolgt über Callbacks. |
| Code und Zitat | Inline-Backticks, Codeblöcke mit Hervorhebung/Kopieren und `> quote`. Zitate benötigen eine begrenzte Layoutbreite. |
| Emojis | Unicode-Emojis und `:shortcode:`. Server-Emojis benötigen einen Emoji-Builder/Resolver. |
| Mathematik | Inline- und Blockformeln erscheinen als **Text mit fester Zeichenbreite**, nicht als gerendertes LaTeX. |
| Klartextbereich | `<plain>...</plain>` erhält den Inhalt wörtlich. |

### Funktionsblöcke

| Funktionsgruppe | Verhalten der veröffentlichten Version |
| --- | --- |
| `x2`, `x3`, `x4`, `scale`, `position` | Größen- und Positionseffekte; ihre Anwendung hängt von den erweiterten MFM-Einstellungen ab. |
| `fg`, `bg`, `font`, `border` | Text-/Hintergrundfarbe, Schriftwahl und Rahmen. Die erweiterten Rahmenoptionen des Entwicklungsbeispiels sind nicht automatisch im veröffentlichten Paket verfügbar. |
| `flip`, `rotate` | Statische Transformationen. |
| `blur` | Aufdeckbare visuelle Unschärfe; keine Sicherheits- oder Schwärzungsgrenze. |
| `ruby`, `unixtime` | Ruby-Anmerkungen und Zeitstempel; Entwicklungsunterschiede stehen auf der [Beispielseite](example.md). |
| `clickable` | Übergibt eine Ereignis-ID über einen Callback. |
| `jelly`, `tada`, `jump`, `bounce`, `shake`, `twitch`, `spin`, `rainbow`, `sparkle` | Animations-/Effektfunktionen. Zum Abschalten von Bewegung siehe [Animation und Barrierefreiheit](animation-accessibility.md). |

Unbekannte Funktionen behalten die wörtliche Hülle `$[name ...]` und rendern ihre Kindinhalte; unbekannte Effekte werden nicht angewendet. Funktionsunterstützung bedeutet keine pixelidentische Ausgabe zum Browser-Renderer von Misskey.

## Einschränkungen und Fehlersuche

- **Keine Web-Unterstützung** und **keine Textauswahl**. Die Ausgabe verwendet RichText mit eingebetteten Widgets, nicht SelectableText.
- Bei überlaufenden Zitaten oder langen Inhalten hilft ein begrenzter Elternbereich, etwa `Expanded` in einer Row.
- Fehlende Schriftarten und Glyphen sind plattformabhängig. Verwende die [Text-/Schriftkonfiguration](configuration.md), statt identische OS-Schriften vorauszusetzen.
- `toPlainText()` auf einem gerenderten Span ist kein verlässlicher Export semantischen Textes: eingebettete Widgets und visuelle Transformationen können vom Quelltext abweichen. Bewahre den Originaltext auf oder definiere eine app-spezifische Konvertierung.
- Ein fehlender oder fehlerhafter Emoji-Resolver lässt einen Shortcode stehen. Das bedeutet keinen MFM-Parserfehler.

Weiter: [Konfiguration](configuration.md) · [Benutzerdefinierte Emojis](custom-emoji.md) · [API-Referenz](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
