---
id: animation-accessibility
slug: /animation-accessibility
title: Animation et accessibilité
sidebar_label: Animation et accessibilité
---

L’animation est activée par défaut. Le renderer **ne relie pas automatiquement** ses indicateurs à la préférence de réduction des mouvements du système. Établissez cette liaison au niveau de l’application.

## Respecter la réduction des mouvements

Utilisez ce widget sous la `MaterialApp` de [Premiers pas](getting-started.md). Il observe `MediaQuery.disableAnimations`. Une préférence applicative « désactiver les effets » peut être combinée au même booléen.

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

## Deux réglages, deux rôles

| Réglage | Résultat |
| --- | --- |
| `enableAnimation: false` | Désactive les animations MFM en conservant les formats/effets statiques là où ils sont implémentés. `tada` reste agrandi, `rainbow` devient un dégradé statique et `sparkle` garde son contenu sans effet. |
| `enableAdvancedMfm: false` | Désactive aussi les comportements avancés de taille/position ; ce n’est pas un simple réglage de réduction des mouvements. |
| Les deux activés | Animations MFM autorisées (`useAnimation == true`). |

Aucun indicateur n’arrête les **images d’émojis GIF/APNG/WebP animées**. Contrôlez-les via votre builder d’images/émojis et votre politique applicative, par exemple avec des images fixes. Une configuration parente désactivant les animations ne s’annule pas simplement en passant la valeur par défaut `true` à un enfant ; voir [Configuration](configuration.md).

Les arguments d’animation MFM `speed`/`delay` sont en secondes, par exemple `$[spin.speed=2s text]`, pas `2000ms`. Gardez `$[...]` dans des chaînes brutes Dart.

## Lecture, focus et contenu masqué

- `blur` est un effet purement visuel. Son contenu n’est pas exclu de la sémantique et peut être lu par les technologies d’assistance. **Ne l’utilisez jamais pour cacher des données confidentielles.**
- Les annotations ruby et WidgetSpans intégrés peuvent produire un ordre de lecture ou une prononciation différents du texte visible. Testez TalkBack/VoiceOver sur la cible réelle plutôt que de supposer une conformité totale à l’accessibilité.
- La sélection du texte n’est pas implémentée. Si la copie ou une vue de lecture alternative est nécessaire, fournissez-la dans l’application à partir du contenu original et de règles de conversion explicites.
- Donnez des libellés pertinents aux widgets d’émojis/interactions personnalisés et assurez un contraste suffisant dans les deux palettes MFM. Les libellés de copie sont décrits dans [Interactions](interactions.md).
- Testez les grandes tailles de texte système, liens longs, citations et navigation clavier/focus dans l’écran englobant. Une capture ne prouve pas la prise en charge d’un lecteur d’écran.

## Performances et dépannage

Pour les fils denses, évitez de recréer inutilement les instances de resolver/configuration, réutilisez les nœuds analysés lorsque le contenu est inchangé et limitez les widgets animés visibles. Mesurez sur le matériel cible avant de définir une politique. La bibliothèque ne garantit pas une fréquence d’images particulière et ne suspend pas automatiquement tous les effets hors écran.

Si du mouvement persiste, distinguez d’abord les images animées des effets MFM. Pour désactiver aussi des effets grands/statiques, envisagez `enableAdvancedMfm: false` et vérifiez le résultat. Si la réduction des mouvements semble ignorée, examinez l’intégration de `MediaQuery` et la configuration héritée.

Suite : [Rendu](rendering.md) · [Émojis personnalisés](custom-emoji.md) · [Application d’exemple](example.md)
