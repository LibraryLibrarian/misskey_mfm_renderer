---
id: getting-started
slug: /getting-started
title: Getting started
sidebar_label: Getting started
---

Start with an existing Flutter application using Flutter **3.38.1 or later** and Dart **3.10.0 or later**. Run the example on a supported native platform, not Chrome or another Web target.

## Install the package

Add this entry alongside the Flutter SDK dependency in your application's `pubspec.yaml`:

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

Then resolve dependencies from the application directory:

```bash
flutter pub get
```

This is a published package dependency. It does not use the unreleased source from the repository's `develop` branch.

## Display MFM text

In a new or disposable application, use the following as `lib/main.dart`. When integrating with an existing application, add the `MfmText` widget to your screen instead of replacing your application entry point.

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

The result is “Hello from MFM!”, with **Hello** in bold and *MFM* in italics. `MfmText` parses the source string and applies the corresponding formatting.

Choose a native device from the list and replace `<device-id>` below with its ID:

```bash
flutter devices
flutter run -d <device-id>
```

This example does not initialize a custom-emoji client or persistent store and does not make a server request to render its text. Package downloads and native build hooks may still need network access; it is not a fully offline build recipe.

## What about custom emoji?

Adding a shortcode such as `:custom_emoji:` does not automatically configure a server or resolve an image. The minimal example deliberately avoids that setup, and no additional direct dependency on `misskey_client` is needed for it.

See [Custom emoji](custom-emoji.md) for the published setup API, ownership, asynchronous cleanup and remote-post context.

## Next steps

[Run the example app](example.md) to browse MFM features and try different text and display settings. For parameter definitions, use the [API reference](https://pub.dev/documentation/misskey_mfm_renderer/latest/).
