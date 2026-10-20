---
id: configuration
slug: /configuration
title: Konfiguration
sidebar_label: Konfiguration
---

`MfmRenderConfig` enthält Darstellungsoptionen und Callbacks. `MfmConfig` teilt eine Konfiguration mit untergeordneten `MfmText`-Widgets. Einen Typ `MfmRenderOptions` gibt es nicht.

## Konfiguration gemeinsam nutzen

Setze dieses Widget in die App aus [Erste Schritte](getting-started.md). Für ein einzelnes Widget kannst du dieselbe Konfiguration direkt über `MfmText(config: ...)` übergeben.

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

## Standardwerte und Vererbung

| Einstellung | Standard / Auflösung |
| --- | --- |
| `enableAdvancedMfm`, `enableAnimation` | Beide `true`; `useAnimation` ist ihre logische UND-Verknüpfung. |
| `enableNyaize` | `false`; für neuen Code ist ein expliziter `nyaizeMode` vorzuziehen. |
| `baseTextStyle` | Konfigurierter Stil, sonst `DefaultTextStyle`; fehlt die Schriftgröße, gilt 14. |
| `brightness` | Expliziter Wert, dann Material-Theme, Cupertino-Theme, Plattformhelligkeit, schließlich hell. |
| `lightColorScheme`, `darkColorScheme` | Geerbte Werte oder Vorgaben `MfmColorScheme.light()` / `.dark()`. Automatisch übernommen wird die **Helligkeit**, nicht jede Farbe des umgebenden Themes. |
| `codeTheme`, `codeDarkTheme` | Hell: github. Dunkel: explizites dunkles Theme, dann `codeTheme`, dann atom-one-dark (`atomOneDarkTheme`). |
| `showCodeBlockCopyButton` | `null` bedeutet sichtbar. `false` blendet den Button aus. |
| `useLocaleSearchButtonLabel` | `false`. Ohne `searchButtonLabel` stammt die Beschriftung aus der Spracheinstellung. `true` entfernt eine explizite/geerbte Beschriftung zugunsten der aktuellen Sprache und hat Vorrang vor `searchButtonLabel`. |

Nullable-Felder greifen gewöhnlich auf geerbte Werte zurück. **Boolesche Standardwerte überschreiben nicht bedingungslos**: `enableAnimation: true` beim Kind aktiviert keine Animation, die beim Elternteil deaktiviert ist. Setze die wirksame Wahl an der gemeinsamen Konfigurationsgrenze, statt sie pro Beitrag rückgängig zu machen. `MfmConfig` benachrichtigt abhängige Widgets bei einem Wechsel der Konfigurationsinstanz. Verwende nach Möglichkeit stabile Instanzen, baue sie aber bei geänderten Theme- oder Barrierefreiheitseingaben neu auf.

## Farben, Schriften und Code

Mit `lightColorScheme` / `darkColorScheme` passt du Farben für MFM-Links, Erwähnungen, Zitate, Code und weitere Elemente an. Deren `copyWith`-Methoden eignen sich für einzelne Farbrollen. Prüfe den Kontrast in beiden Themes.

`fontFamilyResolver` ordnet MFM-Schrifttypen wie `serif` oder `monospace` Schriftfamiliennamen zu. `null` verwendet die Vorgaben. Ein Resolver lädt keine Schriften: eigene Schriften müssen mit der App ausgeliefert und deklariert werden. Diese Bibliothek benötigt keine Google-Fonts-Abhängigkeit.

`codeTheme` und `codeDarkTheme` nehmen Maps mit Hervorhebungsstilen entgegen. Ein eigenes helles `codeTheme` dient ohne `codeDarkTheme` auch als dunkler Fallback; vermeide versehentlich kontrastarme helle Stile im Dunkelmodus. Kopier-Callbacks und Beschriftungen stehen unter [Interaktionen](interactions.md).

## Katzensprache

- `MfmNyaizeMode.disabled`: keine Konvertierung.
- `MfmNyaizeMode.enabled`: geeigneten Text unabhängig vom Autor konvertieren.
- `MfmNyaizeMode.respectAuthor`: konvertieren, wenn `author.isCat` true ist.

Ein expliziter Modus hat Vorrang vor dem älteren Flag `enableNyaize`. Dies betrifft nur die Darstellung; weder Kontodaten noch gespeichertes MFM werden geändert.

## Kontext kopieren und zurücksetzen

`copyWith(field: null)` behält den vorhandenen Wert und löscht ihn **nicht**. Die veröffentlichten Rücksetzflags heißen `clearAuthor`, `clearEmojiUrls` und `clearLocalHost`. Beispielsweise entfernt `config.copyWith(clearAuthor: true, clearEmojiUrls: true)` den beitragsspezifischen Kontext vor einer Wiederverwendung. Ein Wert zusammen mit seinem zugehörigen Rücksetzflag löst eine Ausnahme aus. Das Leeren einer lokalen Konfiguration entfernt keine aus einem umgebenden `MfmConfig` geerbten Werte.

`copyWith` eines Emoji-Handles teilt die Lebenszyklusverantwortung; es erzeugt keine unabhängig freizugebende Ressource. Siehe [Benutzerdefinierte Emojis](custom-emoji.md).

## Fehlersuche

Prüfe bei scheinbar ignorierten Einstellungen das nächste `MfmConfig`, boolesche Standardwerte und `enableAdvancedMfm`. Gib bei abweichenden Farben MFM-Farbschemata explizit an, statt automatische Farbzuordnung zu erwarten.

Weiter: [Benutzerdefinierte Emojis](custom-emoji.md) · [Animation und Barrierefreiheit](animation-accessibility.md) · [MfmRenderConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmRenderConfig-class.html)
