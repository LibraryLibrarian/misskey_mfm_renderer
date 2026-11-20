---
id: example
slug: /example
title: Beispiel-App
sidebar_label: Beispiel-App
---

Das Repository enthält eine native Flutter-Anwendung zum Durchsuchen von MFM-Beispielen und Experimentieren mit eigenem Text. Die Oberfläche ist derzeit **japanisch**.

## App starten

Klone den Entwicklungsbranch in ein neues Verzeichnis oder nutze einen vorhandenen Checkout:

```bash
git clone --branch develop https://github.com/LibraryLibrarian/misskey_mfm_renderer.git
cd misskey_mfm_renderer/example
```

Verwende das festgelegte Flutter SDK des Repositorys (`fvm flutter` kann `flutter` ersetzen). Liste Geräte auf und wähle ein natives Ziel. Dieser Startmodus eignet sich zum Erkunden des Katalogs ohne Initialisierung des Online-Emoji-Dienstes:

```bash
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=MFM_EXAMPLE_OFFLINE=true
```

Ersetze `<device-id>` durch die ID des gewählten Geräts. Dies ist keine Web-Demo.

:::note Entwicklungsquellcode

Das Beispiel verwendet das übergeordnete Paket über `path: ../`. Es zeigt den ausgecheckten Quellcode einschließlich unveröffentlichter Funktionen und entspricht nicht unbedingt dem neuesten Paket auf pub.dev. Siehe dazu das [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md).

:::

## Durchsuchen und ausprobieren

1. **Katalog (Catalog)**: Wähle etwa Textformatierung oder `fn`-Funktionen. Verwandte Beispiele sind auf einer Seite gruppiert.
2. **Mit diesen Einstellungen ausprobieren (この設定で試す)**: Übertrage Text und Einstellungen des Beispiels in den Playground. Die Aktion ist ein Icon mit Barrierefreiheitslabel und Tooltip.
3. **Playground**: Bearbeite MFM-Text und betrachte das Ergebnis. Die Löschaktion leert den Text.
4. **Anzeigeeinstellungen (表示設定)**: Öffne den Einstellungsbildschirm für gemeinsame Optionen. Katzensprache hat eine eigene Detailseite zu Modi und zur simulierten Katzeneinstellung des Autors.

Die App ändert keine Katzeneinstellung eines echten Kontos. Links, Erwähnungen, Hashtags, clickable- und Suchaktionen zeigen eine SnackBar, statt Browser zu öffnen oder Suchanfragen zu senden.

## Offline- und Onlineverhalten

Ohne `MFM_EXAMPLE_OFFLINE=true` initialisiert der Start die Emoji-Unterstützung für misskey.io. Die Einstellungen unterscheiden erfolgreiche Online-Initialisierung, bewussten Offline-Start und Initialisierungsfehler.

Mit dem Offline-Flag wird die Emoji-Initialisierung übersprungen. Die nur online verfügbaren Bedienelemente für entfernte Autoren und `emojiUrls` sind deaktiviert. Gewöhnliche Server-Emojis bleiben Shortcodes; explizit konfigurierte lokale Fallback-, Avatar- und Twemoji-Beispiele sind weiterhin sichtbar.

Das Flag steuert den Laufzeitstart, nicht die Build-Umgebung. Abhängigkeitsauflösung und SQLite-Build-Hook können weiterhin Netzwerkzugriff benötigen. Web-Unterstützung wird dadurch nicht hinzugefügt.

## Unterschiede nur in der Entwicklungsversion

Die Leitfäden beziehen sich auf die veröffentlichte Abhängigkeit aus „Erste Schritte“. Der fotografierte Entwicklungs-Checkout enthält zusätzlich folgende Änderungen. Diese Tabelle ist **keine** kopierbare API-Anleitung für das veröffentlichte Paket.

| Bereich | Entwicklungs-Checkout (nicht die veröffentlichte API der Leitfäden) |
| --- | --- |
| Erwähnungen | Kapselförmige Darstellung, `MfmMentionOptions`, Darstellungs-/Avatar-Provider-Optionen. |
| Zeitstempel | `MfmUnixtimeOptions`, absolute/relative Formatierung und regelmäßige Aktualisierung relativer Beschriftungen. |
| Emojis | `MfmTwemojiBuilder`, `textStyle` im Emoji-Kontext und `fallbackTextStyle` für benutzerdefinierte Emojis. |
| Suche und Links | Bearbeitbare Suche und externe Icons bei beschrifteten Links (Icons für reine URLs existieren bereits im veröffentlichten Paket). |
| Rahmen | Neun erweiterte Rahmenstile, RGBA und Clipping-Verhalten. |

## Tatsächliche Beispielansichten

Dies sind unveränderte Android-Emulatoraufnahmen des **Entwicklungs-Checkouts** mit synthetischen Offline-Daten und japanischer Oberfläche. Sie illustrieren die App, versprechen keine identische Pixelausgabe des veröffentlichten Pakets und belegen keine visuelle iOS-Prüfung.

<figure className="example-capture">

![Android-Entwicklungsbeispiel: Textformatierungskatalog, synthetische Offline-Daten, japanische Oberfläche.](/img/example-text-format-android-develop.png)

<figcaption>Android-Entwicklungsbeispiel — Textformatierungskatalog, synthetische Offline-Daten, japanische Oberfläche. Helles Theme und gemeinsame Standardeinstellungen.</figcaption>
</figure>

<figure className="example-capture">

![Android-Entwicklungsbeispiel: Playground, synthetische Offline-Daten, japanische Oberfläche.](/img/example-playground-android-develop.png)

<figcaption>Android-Entwicklungsbeispiel — Playground, synthetische Offline-Daten, japanische Oberfläche. Das ausgewählte Katalogbeispiel ist mit seinen Einstellungen unverändert geladen.</figcaption>
</figure>

Aufnahmerevision, Original-PNG-Hashes und Reproduktionseinstellungen stehen im [Herkunftsnachweis der Screenshots](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/docs/screenshots.md).

## Weitere Informationen

Die [Beispiel-README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md) beschreibt Katalog, Einstellungen, lokale Testdaten und Plattformkonfiguration ausführlicher. Um die Bibliothek in deine eigene App einzubauen, beginne mit [Erste Schritte](getting-started.md).
