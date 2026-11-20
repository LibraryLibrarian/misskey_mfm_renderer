---
id: custom-emoji
slug: /custom-emoji
title: Émojis personnalisés
sidebar_label: Émojis personnalisés
---

Les `:shortcodes:` propres à un serveur nécessitent une configuration d’émojis. Sans builder, ils restent du texte littéral. Installez le renderer selon [Premiers pas](getting-started.md).

## Catalogue et stockage par défaut

`MfmEmojiConfig.createDefault` relie un `MisskeyClient` géré par l’appelant à un catalogue persistant, un resolver et un builder d’images. Il retourne un **handle**, pas seulement une configuration. Le stockage se trouve par défaut dans le répertoire des documents de l’app ; `storagePath` le remplace. Le stockage par défaut utilise SQLite/Drift. Conservez le handle à l’échelle d’un écran ou de l’application, pas séparément pour chaque publication du fil.

L’exemple reçoit un client déjà créé. Puisqu’il importe directement `misskey_client`, déclarez ce paquet comme dépendance directe de l’application (compatible avec `^1.0.0-beta.6`, pas l’ancienne beta.5). Une synchronisation en ligne s’effectue en arrière-plan par défaut. Ne fournissez un vrai client pour un serveur délibérément choisi que si cet accès réseau est voulu.

Placez ce widget sous l’application de « Premiers pas ». Gardez son client fixe pendant toute sa durée de vie ; remplacez le widget avec une nouvelle clé lors d’un changement de serveur. Le client doit rester valide jusqu’à la fin du nettoyage asynchrone du handle. Si cet ordre doit être attendu à l’arrêt de l’application, gérez le handle hors de `State` et attendez sa libération avant de fermer le client.

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

## Gestion des ressources et nettoyage asynchrone

L’exemple attend l’initialisation même si le widget est retiré avant sa fin, puis libère le handle obtenu. Le `State.dispose` de Flutter ne peut pas être asynchrone ; le nettoyage s’exécute séparément et signale les erreurs de libération. N’abandonnez pas le Future d’initialisation, sous peine de perdre un handle créé tardivement.

- `await handle.dispose()` est idempotent et attend la synchronisation en arrière-plan avant de fermer le catalogue/stockage.
- Il **ne libère pas le client de l’appelant**.
- Les copies de `handle.copyWith(...)` partagent le cycle de vie. Libérer n’importe quelle copie libère les ressources communes ; ne libérez pas une copie par publication.
- `autoSync: false` désactive la synchronisation initiale en arrière-plan. `onSyncError` permet d’observer les échecs ; créer un handle avec succès ne prouve pas que la synchronisation serveur a réussi.
- `emojiRefreshListenable` peut avertir les émojis affichés lorsque le catalogue change. La synchronisation automatique par défaut fournit aussi ces notifications.

## Contexte des publications distantes

Dérivez une configuration par publication depuis `handle`, en fournissant `author: MfmAuthorContext(host: 'remote.example')` et `emojiUrls`, la map des noms d’émojis vers leurs URL d’images issue de la publication. Les auteurs locaux ont un host null. Le `localHost` du helper vient de l’origine du client.

Traitez la map comme immuable et remplacez-la lorsque les données changent. **Une map présente sans le code court demandé impose le repli littéral** ; ce n’est pas équivalent à une map absente. Nettoyez le contexte périmé avec les [indicateurs d’effacement publiés](configuration.md) lors de la réutilisation.

## Resolver existant ou builder personnalisé

Si l’application gère déjà un catalogue/resolver, utilisez `MfmEmojiConfig.fromResolver(resolver: ..., serverBaseUrl: ...)`. Il retourne une configuration, pas un handle propriétaire : l’appelant doit libérer son catalogue/stockage. `serverBaseUrl` permet des URL de repli distantes lorsqu’aucune URL directe n’est disponible ; sans lui, les émojis distants non résolus restent des codes courts.

Pour un contrôle complet, `emojiBuilder` reçoit `(String name, MfmEmojiContext context)`. `unicodeEmojiBuilder` reçoit la chaîne Unicode et le même contexte. Retournez un Widget et gérez vous-même chargement, erreurs et sémantique. Le contexte publié expose `fontSize`, `scale`, `normal`, `host`, `url` et `useOriginalSize`, mais **pas** le champ `textStyle` propre au développement. Un resolver personnalisé ou une URL directe contrôle l’accès réseau : appliquez à cet endroit la politique médias/hôtes de l’application.

## Taille, ligne de base et cache

- Hauteur par défaut du helper : **2em**, ou **1.25em** en contexte normal/plain. `emojiSize` indique une hauteur fixe, pas minimale. `MfmCustomEmoji.size` utilisé seul vaut 24 par défaut.
- Pour reproduire le helper, utilisez le décalage de ligne de base `size / 2 - context.fontSize * 0.25`, ou `context.fontSize * 0.25` dans le contexte normal/plain. Ne multipliez pas encore l’image par `context.scale` : la transformation de peinture englobante applique déjà l’échelle.
- `emojiMaxWidth` limite la largeur. `useOriginalSize` est une indication pour les builders personnalisés ; le helper ne peut pas choisir automatiquement entre URL originale et miniature si le resolver ne les distingue pas.
- Les caches d’URL et de ratio d’image sont des LRU à l’échelle du processus, de 256 entrées chacun. `cacheScope` isole les identités. Le défaut utilise l’identité du resolver ou l’URL directe ; recréer des closures de resolver à chaque build peut empêcher leur réutilisation.

## Plateformes et dépannage

Android/iOS/macOS/Linux/Windows natifs sont pris en charge, pas le Web. Suivez la configuration du stockage/réseau natif dans le [README de l’exemple](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md). Les téléchargements SQLite/dépendances à la compilation sont distincts de la synchronisation à l’exécution.

Si les codes courts restent visibles, vérifiez resolver, origine serveur, host/map par publication, erreurs de synchronisation, disponibilité des images et permissions réseau natives. Ne journalisez pas les jetons et ne prenez pas un repli en code court pour la preuve d’une erreur d’authentification. Pour des tests locaux déterministes, désactivez la synchronisation automatique et injectez stockage/resolvers factices ; ces tests ne valident pas la synchronisation réelle avec un serveur.

Suite : [Configuration](configuration.md) · [Interactions](interactions.md) · [MfmEmojiConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmEmojiConfig-class.html)
