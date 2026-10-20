---
id: getting-started
slug: /getting-started
title: Erste Schritte
sidebar_label: Erste Schritte
---

Beginne mit einer vorhandenen Flutter-Anwendung mit Flutter **3.38.1 oder neuer** und Dart **3.10.0 oder neuer**. Führe das Beispiel auf einer unterstützten nativen Plattform aus, nicht in Chrome oder auf einem anderen Web-Ziel.

## Paket installieren

Ergänze diesen Eintrag neben der Flutter-SDK-Abhängigkeit in der `pubspec.yaml` deiner Anwendung:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

Löse anschließend die Abhängigkeiten im Anwendungsverzeichnis auf:

```bash
flutter pub get
```

Dies ist eine veröffentlichte Paketabhängigkeit. Sie verwendet nicht den unveröffentlichten Quellcode aus dem Branch `develop`.

## MFM-Text anzeigen

Verwende in einer neuen oder temporären Anwendung Folgendes als `lib/main.dart`. In einer bestehenden Anwendung fügst du stattdessen `MfmText` zu deinem Bildschirm hinzu, ohne den Anwendungseinstieg zu ersetzen.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  runApp(const MfmDemoApp());
}

class MfmDemoApp extends StatelessWidget {
  const MfmDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: MfmText(text: '**Hello** from *MFM*!'),
          ),
        ),
      ),
    );
  }
}
```

Das Ergebnis ist „Hello from MFM!“, mit **Hello** in Fettdruck und *MFM* in Kursivschrift. `MfmText` parst den Quelltext und wendet die entsprechende Formatierung an.

Wähle ein natives Gerät aus der Liste und ersetze `<device-id>` durch dessen ID:

```bash
flutter devices
flutter run -d <device-id>
```

Dieses Beispiel initialisiert weder einen Emoji-Client noch einen persistenten Speicher und sendet für die Textdarstellung keine Serveranfrage. Paketdownloads und native Build-Hooks können dennoch Netzwerkzugriff benötigen; dies ist keine vollständig offline ausführbare Build-Anleitung.

## Und benutzerdefinierte Emojis?

Ein Shortcode wie `:custom_emoji:` konfiguriert nicht automatisch einen Server und löst kein Bild auf. Das minimale Beispiel verzichtet bewusst darauf und benötigt auch keine zusätzliche direkte Abhängigkeit von `misskey_client`.

[Benutzerdefinierte Emojis](custom-emoji.md) erläutert die veröffentlichte Einrichtungs-API, Ressourcenverantwortung, asynchrone Freigabe und den Kontext entfernter Beiträge.

## Nächste Schritte

[Starte die Beispiel-App](example.md), um MFM-Funktionen sowie verschiedene Texte und Einstellungen auszuprobieren. Parameterdefinitionen findest du in der [API-Referenz](https://pub.dev/documentation/misskey_mfm_renderer/latest/).
