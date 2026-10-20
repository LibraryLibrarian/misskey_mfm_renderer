---
id: animation-accessibility
slug: /animation-accessibility
title: Animation und Barrierefreiheit
sidebar_label: Animation und Barrierefreiheit
---

Animationen sind standardmäßig aktiviert. Der Renderer verknüpft seine Flags **nicht** automatisch mit der Betriebssystemeinstellung für reduzierte Bewegung. Diese Verbindung muss die Anwendung herstellen.

## Reduzierte Bewegung berücksichtigen

Verwende dieses Widget unter der `MaterialApp` aus [Erste Schritte](getting-started.md). Es beobachtet Änderungen an `MediaQuery.disableAnimations`. Eine App-Einstellung zum Abschalten von Effekten kann mit demselben booleschen Wert kombiniert werden.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MotionExample extends StatelessWidget {
  const MotionExample({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MfmText(
      text: r'$[tada Hello] $[rainbow Color]',
      config: MfmRenderConfig(enableAnimation: !reduceMotion),
    );
  }
}
```

## Zwei Schalter mit unterschiedlichen Aufgaben

| Einstellung | Ergebnis |
| --- | --- |
| `enableAnimation: false` | Deaktiviert MFM-Animationen und erhält statische Formatierung/Effekte, soweit implementiert. `tada` bleibt vergrößert, `rainbow` wird ein statischer Verlauf, `sparkle` behält seinen Inhalt ohne Effekt. |
| `enableAdvancedMfm: false` | Deaktiviert zusätzlich erweiterte Größen-/Positionseffekte; nicht bloß ein Schalter für reduzierte Bewegung. |
| Beide aktiviert | MFM-Animationen sind erlaubt (`useAnimation == true`). |

Keines der Flags stoppt animierte **GIF-/APNG-/WebP-Emoji-Bilder**. Steuere diese über Bild-/Emoji-Builder und App-Richtlinien, etwa mit Standbildern. Eine übergeordnete Konfiguration mit deaktivierten Animationen lässt sich nicht einfach mit dem Standardwert `true` beim Kind aufheben; siehe [Konfiguration](configuration.md).

MFM-Animationsargumente `speed`/`delay` verwenden Sekunden, etwa `$[spin.speed=2s text]`, nicht `2000ms`. Verwende für `$[...]` Dart-Raw-Strings.

## Vorlesen, Fokus und verborgene Inhalte

- `blur` ist nur ein visueller Effekt. Sein Inhalt bleibt in der Semantik enthalten und kann von assistiven Technologien vorgelesen werden. **Niemals zum Verbergen vertraulicher Daten verwenden.**
- Ruby-Anmerkungen und eingebettete WidgetSpans können Lesereihenfolge oder Aussprache gegenüber der visuellen Darstellung verändern. Prüfe TalkBack/VoiceOver auf dem tatsächlichen Zielgerät, statt vollständige Barrierefreiheit vorauszusetzen.
- Textauswahl ist nicht implementiert. Biete erforderliches Kopieren oder eine alternative Leseansicht auf Anwendungsebene mit dem Originalinhalt und expliziten Konvertierungsregeln an.
- Verwende aussagekräftige Labels für eigene Emoji-/Interaktionswidgets und ausreichenden Kontrast in beiden MFM-Farbschemata. Kopierlabels sind unter [Interaktionen](interactions.md) beschrieben.
- Teste größere Systemschrift, lange Links, Zitate sowie Tastatur-/Fokusnavigation im umgebenden Bildschirm. Ein Screenshot belegt keine Screenreader-Unterstützung.

## Leistung und Fehlersuche

Vermeide in dichten Timelines unnötiges Neuerzeugen von Resolver-/Konfigurationsinstanzen, verwende geparste Knoten unveränderter Inhalte wieder und begrenze die Zahl sichtbarer animierter Widgets. Messe auf der Zielhardware, bevor du eine Richtlinie festlegst. Die Bibliothek garantiert keine bestimmte Bildrate und pausiert nicht automatisch jeden Effekt außerhalb des Sichtbereichs.

Unterscheide bei verbleibender Bewegung zuerst Bildanimationen von MFM-Effekten. Sollen auch große/statische Effekte entfallen, erwäge `enableAdvancedMfm: false` und prüfe das Ergebnis. Wird reduzierte Bewegung scheinbar ignoriert, prüfe die `MediaQuery`-Anbindung und geerbte Konfiguration.

Weiter: [Darstellung](rendering.md) · [Benutzerdefinierte Emojis](custom-emoji.md) · [Beispiel-App](example.md)
