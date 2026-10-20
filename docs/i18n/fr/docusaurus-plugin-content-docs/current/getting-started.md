---
id: getting-started
slug: /getting-started
title: Premiers pas
sidebar_label: Premiers pas
---

Partez d’une application Flutter existante utilisant Flutter **3.38.1 ou ultérieur** et Dart **3.10.0 ou ultérieur**. Exécutez l’exemple sur une plateforme native prise en charge, pas dans Chrome ni sur une autre cible Web.

## Installer le paquet

Ajoutez cette entrée à côté de la dépendance au SDK Flutter dans le fichier `pubspec.yaml` de votre application :

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

Résolvez ensuite les dépendances depuis le répertoire de l’application :

```bash
flutter pub get
```

Il s’agit d’une dépendance publiée, et non du code non publié de la branche `develop` du dépôt.

## Afficher du texte MFM

Dans une application neuve ou temporaire, utilisez le contenu suivant comme `lib/main.dart`. Pour une application existante, ajoutez plutôt le widget `MfmText` à votre écran sans remplacer le point d’entrée de l’application.

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

Le résultat est « Hello from MFM! », avec **Hello** en gras et *MFM* en italique. `MfmText` analyse la chaîne source et applique la mise en forme correspondante.

Choisissez un appareil natif dans la liste et remplacez `<device-id>` par son identifiant :

```bash
flutter devices
flutter run -d <device-id>
```

Cet exemple n’initialise ni client d’émojis personnalisés ni stockage persistant et n’envoie pas de requête au serveur pour afficher son texte. Les téléchargements de paquets et les hooks de compilation native peuvent néanmoins nécessiter le réseau : ce n’est pas une procédure de compilation entièrement hors ligne.

## Et les émojis personnalisés ?

Ajouter un code court tel que `:custom_emoji:` ne configure pas automatiquement un serveur et ne résout pas d’image. L’exemple minimal évite volontairement cette configuration et ne nécessite aucune dépendance directe supplémentaire à `misskey_client`.

Consultez [Émojis personnalisés](custom-emoji.md) pour l’API d’initialisation publiée, la gestion des ressources, le nettoyage asynchrone et le contexte des publications distantes.

## Étapes suivantes

[Lancez l’application d’exemple](example.md) pour parcourir les fonctions MFM et essayer différents textes et paramètres. La [référence API](https://pub.dev/documentation/misskey_mfm_renderer/latest/) définit les paramètres.
