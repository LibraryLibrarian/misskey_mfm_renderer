---
id: overview
slug: /
title: Überblick
sidebar_label: Überblick
---

# misskey_mfm_renderer

Rendere [Misskey Flavored Markdown (MFM)](https://misskey-hub.net/en/docs/for-users/features/mfm/) mit `MfmText` in Flutter. MFM erweitert bekannte Textformatierungen um benutzerdefinierte Emojis, Transformationen und Animationen.

Die Bibliothek wandelt MFM-Text oder bereits geparste Knoten in Flutter-Widgets um. Sie lädt keine Timeline und stellt keine vollständige Misskey-Anwendung bereit. Deine Anwendung liefert den Text, wählt die Darstellungseinstellungen und verarbeitet Interaktionen.

## Einstieg

- [Erste Schritte](getting-started.md): ersten MFM-Text ohne Serververbindung anzeigen.
- [Beispiel-App](example.md): Katalog durchsuchen und Text sowie Einstellungen im Playground ausprobieren.
- [Darstellung](rendering.md): Eingaben, Anzeigemodi, unterstützte Syntax und Einschränkungen.
- [Konfiguration](configuration.md): gemeinsame Stile, Farben, Schriftarten und Katzensprache.
- [Benutzerdefinierte Emojis](custom-emoji.md): Einrichtung, Ressourcenverantwortung, entfernte Beiträge und eigene Builder.
- [Interaktionen](interactions.md): Callbacks und Navigationsrichtlinien der Anwendung.
- [Animation und Barrierefreiheit](animation-accessibility.md): reduzierte Bewegung und Grenzen beim Vorlesen.
- [API-Referenz](https://pub.dev/documentation/misskey_mfm_renderer/latest/): generierte API-Dokumentation des neuesten veröffentlichten Pakets.

Die kopierbaren Beispiele beziehen sich auf das veröffentlichte Paket aus „Erste Schritte“. Funktionen und Screenshots der Entwicklungsversion sind auf der Beispielseite gesondert gekennzeichnet.

## Darstellbare Inhalte

- Textformatierung, Zitate, Code, Links, Erwähnungen und Hashtags.
- Unicode-Emojis und benutzerdefinierte Emojis mit konfigurierbarer Auflösung und Darstellung.
- MFM-`fn`-Funktionen für Größe, Transformationen, Stile und Animationen.

Farben, Textstile, Callbacks und Animationseinstellungen passen die Darstellung an. Der [Darstellungsleitfaden](rendering.md) beschreibt unterstützte Funktionen und Einschränkungen; nicht jede Misskey-Funktion ist damit zugesichert.

## Unterstützte Umgebungen

Das Paket unterstützt **Android, iOS, macOS, Linux und Windows**. Es benötigt Flutter **3.38.1 oder neuer** und Dart **3.10.0 oder neuer**.

**Web wird nicht unterstützt.** Web-Builds können zwar kompilieren, die standardmäßige Emoji-Einrichtung hat jedoch keinen Web-Speicher, und Web-Darstellung wurde nicht getestet. Diese Website ist Dokumentation, keine Browserversion der Flutter-Beispiel-App.

Gerenderter Text kann nicht ausgewählt werden. Anwendungen mit einer Kopierfunktion sollten den ursprünglichen MFM-Text verwenden.

Benutzerdefinierte Emojis verwenden das mitgelieferte `misskey_emoji`. Die Standardeinrichtung besitzt einen persistenten SQLite-Speicher und benötigt Initialisierung und Freigabe. Das [minimale Textbeispiel](getting-started.md) benötigt sie nicht. Lies den [Emoji-Leitfaden](custom-emoji.md), bevor du nativen Speicher und Bildladen konfigurierst.

## Veröffentlichtes Paket und Entwicklungsbeispiele

Die Installationsanleitung verwendet eine veröffentlichte Paketabhängigkeit. Der Branch `develop`, dessen README und die Beispiel-App können unveröffentlichte Änderungen enthalten. Prüfe das [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md), bevor du dich auf eine als unveröffentlicht gekennzeichnete Funktion verlässt.
