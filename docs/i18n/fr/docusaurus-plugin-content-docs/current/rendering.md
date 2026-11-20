---
id: rendering
slug: /rendering
title: Rendu MFM
sidebar_label: Rendu MFM
---

`MfmText` affiche du Misskey Flavored Markdown dans un widget Flutter natif. Installez le paquet publié selon [Premiers pas](getting-started.md) ; les exemples à copier ciblent cette API publiée, pas l’exemple de développement.

## Une zone de rendu bornée

Placez ce widget dans le corps de l’application Material de « Premiers pas ». Utilisez une **chaîne brute** Dart pour `$[...]`, afin que Dart n’interprète pas `$` comme une interpolation.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class RenderExample extends StatelessWidget {
  const RenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      child: MfmText(
        text: r'**Hello** $[fg.color=336699 blue] $[x2 large]',
        config: MfmRenderConfig(enableAnimation: false),
      ),
    );
  }
}
```

## Entrées et modes d’affichage

| Entrée | Comportement |
| --- | --- |
| `text` | Source MFM ; une chaîne vide n’affiche rien. |
| `parsedNodes` | `List<MfmNode>` déjà analysée par `misskey_mfm_parser`. Réutilisable pour le même contenu analysé ; prioritaire sur `text`. Déclarez une dépendance directe au parseur si vous l’importez dans l’application. |
| `simple: true` | Utilise le parseur simple : texte ordinaire, mentions, hashtags, URL et la plupart des formats ne sont pas traités comme du MFM complet. Les émojis Unicode/personnalisés restent pris en charge. |
| `plain: true` | Utilise aussi l’analyse simple ; les émojis reçoivent le contexte de taille normale. Ce n’est pas un filtre de sécurité HTML/Markdown généraliste. |
| `nowrap: true` | Une seule ligne avec points de suspension. Donnez au widget une largeur disponible finie. |
| `rootScale` | Échelle racine positive et finie (défaut `1.0`) ; concerne le rendu MFM, pas la préférence d’accessibilité de l’application. |
| `isNote` | `true` par défaut ; modifie les détails de navigation des hashtags, pas le parseur. Voir [Interactions](interactions.md). |

Fournissez `text` ou `parsedNodes` ; le constructeur vérifie par assertion que l’un existe. Une `FormatException` du parseur entraîne l’affichage de toute la source comme texte brut. Cela ne garantit pas que toute entrée mal formée provoque une exception ou soit filtrée. Pour le contexte hôte/émojis par publication, voir [Émojis personnalisés](custom-emoji.md).

## Syntaxe prise en charge

| Catégorie | Exemples / comportement |
| --- | --- |
| Texte | Gras `**text**`, italique `*text*`, barré `~~text~~`, petit `<small>text</small>`, centré `<center>text</center>`. |
| Navigation | URL, `[label](https://example.com)`, `@name`, `#tag` et blocs de recherche. La navigation passe par des callbacks. |
| Code et citation | Accents graves pour le code en ligne, blocs de code délimités avec coloration/copie et `> quote`. Les citations nécessitent une largeur de mise en page bornée. |
| Émojis | Émojis Unicode et `:shortcode:`. Les émojis de serveur nécessitent un builder/resolver. |
| Mathématiques | Les formules en ligne ou en bloc sont affichées en **texte à chasse fixe**, pas rendues en LaTeX. |
| Zone brute | `<plain>...</plain>` conserve littéralement le contenu. |

### Blocs de fonctions

| Famille | Comportement publié |
| --- | --- |
| `x2`, `x3`, `x4`, `scale`, `position` | Effets de taille et de position ; les réglages MFM avancés influencent leur application. |
| `fg`, `bg`, `font`, `border` | Couleurs du texte/fond, choix de police et bordures. Ne supposez pas que les options de bordure étendues de l’exemple de développement existent dans le paquet publié. |
| `flip`, `rotate` | Transformations statiques. |
| `blur` | Flou visuel dont le contenu peut être révélé ; aucune barrière de sécurité ou de masquage confidentiel. |
| `ruby`, `unixtime` | Annotations ruby et horodatages ; voir les différences de développement sur la [page de l’exemple](example.md). |
| `clickable` | Transmet un identifiant d’événement par callback. |
| `jelly`, `tada`, `jump`, `bounce`, `shake`, `twitch`, `spin`, `rainbow`, `sparkle` | Fonctions d’animation/effets. Pour désactiver le mouvement, voir [Animation et accessibilité](animation-accessibility.md). |

Les fonctions inconnues conservent l’enveloppe littérale `$[name ...]` tout en affichant leurs enfants ; aucun effet inconnu n’est appliqué. La prise en charge ne garantit pas un rendu identique au pixel près à celui de Misskey dans le navigateur.

## Limites et dépannage

- **Pas de Web** et **pas de sélection de texte**. Le rendu utilise RichText avec des widgets intégrés, pas SelectableText.
- Si des citations ou contenus longs débordent, utilisez un parent borné, tel qu’un `Expanded` dans une Row.
- Les polices et glyphes manquants dépendent de la plateforme. Utilisez la [configuration du texte/des polices](configuration.md), sans supposer des polices identiques sur chaque OS.
- `toPlainText()` sur un span rendu n’est pas un export fiable du texte sémantique : widgets intégrés et transformations visuelles peuvent différer de la source. Conservez l’original ou définissez une conversion propre à l’application.
- Un resolver d’émojis absent ou en échec laisse le code court visible. Cela n’indique pas un échec du parseur MFM.

Suite : [Configuration](configuration.md) · [Émojis personnalisés](custom-emoji.md) · [Référence API](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
