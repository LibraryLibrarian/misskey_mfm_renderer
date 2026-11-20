---
id: animation-accessibility
slug: /animation-accessibility
title: Animation et accessibilité
sidebar_label: Animation et accessibilité
---

L’animation est activée par défaut. Par défaut, `MfmText` suit aussi la préférence de réduction des mouvements du système (`MediaQuery.disableAnimations`) : tant qu’elle est activée, le rendu MFM est identique à celui de `enableAnimation: false` et suit les changements de ce réglage.

## Réduction des mouvements

`followPlatformReducedMotion` contrôle ce comportement.

| Valeur | Résultat |
| --- | --- |
| `null` (par défaut) ou `true` | Suit le réglage du système. Lorsqu’il est activé, les animations MFM s’arrêtent et le rendu statique décrit ci-dessous est utilisé. |
| `false` | Ignore le réglage du système. Seuls `enableAnimation` / `enableAdvancedMfm` déterminent si MFM est animé. |

Le réglage du système peut seulement arrêter les animations ; il ne réactive jamais celles désactivées par `enableAnimation: false`. Un `true` / `false` explicite dans la configuration enfant remplace la valeur du parent ; `null` en hérite. `MfmRenderConfig.useAnimation` est calculé uniquement à partir de la configuration et ne tient pas compte du réglage du système.

Si votre application possède sa propre préférence « désactiver les effets », combinez-la avec `enableAnimation`. Pour permettre aux utilisateurs de jouer les animations MFM même lorsque le réglage du système est activé, définissez aussi `followPlatformReducedMotion: false`. Utilisez ce widget sous la `MaterialApp` de [Premiers pas](getting-started.md).

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MotionExample extends StatelessWidget {
  const MotionExample({super.key, required this.userPrefersAnimation});

  /// Application preference, for example initialized from the OS setting.
  final bool userPrefersAnimation;

  @override
  Widget build(BuildContext context) {
    return MfmText(
      text: r'$[tada Hello] $[rainbow Color]',
      config: MfmRenderConfig(
        enableAnimation: userPrefersAnimation,
        // The application preference already reflects the OS setting.
        followPlatformReducedMotion: false,
      ),
    );
  }
}
```

## Deux réglages, deux rôles

| Réglage | Résultat |
| --- | --- |
| `enableAnimation: false` | Désactive les animations MFM en conservant les formats/effets statiques là où ils sont implémentés. `tada` reste agrandi, `rainbow` devient un dégradé statique et `sparkle` garde son contenu sans effet. |
| `enableAdvancedMfm: false` | Désactive aussi les comportements avancés de taille/position ; ce n’est pas un simple réglage de réduction des mouvements. |
| Réduction des mouvements du système avec `followPlatformReducedMotion` à `null`/`true` | Même rendu que `enableAnimation: false`. |
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

Si du mouvement persiste, distinguez d’abord les images animées des effets MFM. Pour désactiver aussi des effets grands/statiques, envisagez `enableAdvancedMfm: false` et vérifiez le résultat. Si la réduction des mouvements semble ignorée, vérifiez que `followPlatformReducedMotion` n’est pas `false` dans la configuration explicite ou héritée et que le `MediaQuery` au-dessus de `MfmText` signale `disableAnimations`.

Suite : [Rendu](rendering.md) · [Émojis personnalisés](custom-emoji.md) · [Application d’exemple](example.md)
