---
id: configuration
slug: /configuration
title: Configuration
sidebar_label: Configuration
---

Utilisez `MfmRenderConfig` pour les préférences de rendu et callbacks. `MfmConfig` partage une configuration avec les widgets `MfmText` descendants. Il n’existe pas de type `MfmRenderOptions`.

## Partager une configuration

Placez ce widget dans l’application de [Premiers pas](getting-started.md). Pour un seul widget, transmettez plutôt la même configuration via `MfmText(config: ...)`.

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

## Valeurs par défaut et héritage

| Réglage | Défaut / résolution |
| --- | --- |
| `enableAdvancedMfm`, `enableAnimation` | Tous deux `true` ; `useAnimation` est leur ET logique. |
| `enableNyaize` | `false` ; préférez un `nyaizeMode` explicite pour le nouveau code. |
| `baseTextStyle` | Style configuré, sinon `DefaultTextStyle` ; la taille de police absente vaut 14. |
| `brightness` | Valeur explicite, puis thème Material, thème Cupertino, luminosité de la plateforme, enfin mode clair. |
| `lightColorScheme`, `darkColorScheme` | Valeurs héritées ou préréglages `MfmColorScheme.light()` / `.dark()`. Seule la **luminosité** ambiante est adoptée automatiquement, pas toutes les couleurs du thème. |
| `codeTheme`, `codeDarkTheme` | Clair : github. Sombre : thème sombre explicite, puis `codeTheme`, puis atom-one-dark (`atomOneDarkTheme`). |
| `showCodeBlockCopyButton` | `null` signifie visible. `false` masque le bouton. |
| `useLocaleSearchButtonLabel` | `false`. Sans `searchButtonLabel`, le libellé dépend de la langue. `true` supprime un libellé explicite/hérité pour utiliser la langue actuelle ; il est prioritaire sur `searchButtonLabel`. |

Les champs nullables utilisent généralement les valeurs héritées comme repli. **Les booléens à leur valeur par défaut ne remplacent pas inconditionnellement l’héritage** : `enableAnimation: true` sur un enfant ne réactive pas les animations désactivées par le parent. Définissez le choix effectif au niveau de la configuration partagée, plutôt que de chercher à l’annuler publication par publication. `MfmConfig` avertit ses dépendants quand l’instance change ; réutilisez des instances stables si possible, mais reconstruisez-les lorsque le thème ou les paramètres d’accessibilité changent.

## Couleurs, polices et code

Fournissez `lightColorScheme` / `darkColorScheme` pour personnaliser les couleurs des liens MFM, mentions, citations, code et autres éléments. Leurs méthodes `copyWith` permettent de ne modifier que certains rôles. Vérifiez le contraste dans les deux thèmes.

`fontFamilyResolver` associe les types de police MFM, tels que `serif` ou `monospace`, à des noms de familles. Retournez `null` pour les valeurs par défaut. Le resolver ne charge pas de polices : intégrez et déclarez les polices personnalisées dans l’application. La bibliothèque ne nécessite pas de dépendance Google Fonts.

`codeTheme` et `codeDarkTheme` acceptent des maps de styles de coloration. Un `codeTheme` clair personnalisé sert aussi de repli sombre sans `codeDarkTheme` ; évitez un style clair peu contrasté en mode sombre. Les callbacks et libellés de copie sont décrits dans [Interactions](interactions.md).

## Langage de chat

- `MfmNyaizeMode.disabled` : aucune conversion.
- `MfmNyaizeMode.enabled` : conversion du texte éligible indépendamment de l’auteur.
- `MfmNyaizeMode.respectAuthor` : conversion lorsque `author.isCat` est true.

Un mode explicite est prioritaire sur l’ancien indicateur `enableNyaize`. Ce choix de rendu ne modifie ni le compte ni le MFM stocké.

## Copier et réinitialiser le contexte

`copyWith(field: null)` conserve le champ existant ; il ne l’efface **pas**. Les indicateurs de réinitialisation publiés sont `clearAuthor`, `clearEmojiUrls` et `clearLocalHost`. Par exemple, `config.copyWith(clearAuthor: true, clearEmojiUrls: true)` enlève le contexte propre à une publication avant réutilisation. Ne transmettez pas à la fois une valeur et son indicateur d’effacement : cela lève une exception. Effacer une configuration locale ne retire pas les valeurs héritées d’un `MfmConfig` englobant.

Le `copyWith` d’un handle d’émojis partage la responsabilité du cycle de vie ; ce n’est pas une nouvelle ressource libérable indépendamment. Voir [Émojis personnalisés](custom-emoji.md).

## Dépannage

Si un réglage semble ignoré, vérifiez le `MfmConfig` le plus proche, les booléens à leur valeur par défaut et `enableAdvancedMfm`. Si les couleurs diffèrent du thème de l’app, fournissez explicitement des palettes MFM plutôt que d’attendre une correspondance automatique.

Suite : [Émojis personnalisés](custom-emoji.md) · [Animation et accessibilité](animation-accessibility.md) · [MfmRenderConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmRenderConfig-class.html)
