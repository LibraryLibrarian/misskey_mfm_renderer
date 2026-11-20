---
id: interactions
slug: /interactions
title: Interactions
sidebar_label: Interactions
---

Le renderer signale les interactions ; l’application décide de leur sens. Il **n’ouvre pas** automatiquement d’URL, ne navigue pas vers des profils et n’envoie pas de requêtes de recherche.

## Exemple de retour local

Placez ce widget dans un `Scaffold` sous une `MaterialApp`, comme dans [Premiers pas](getting-started.md). Toutes les actions affichent une SnackBar locale ; aucun launcher ni compte réel n’est nécessaire.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class InteractionExample extends StatelessWidget {
  const InteractionExample({super.key});

  @override
  Widget build(BuildContext context) {
    void show(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return MfmText(
      text: '[Example](https://example.com) @alice #flutter\n'
          'Flutter Search\n'
          r'$[clickable.ev=demo Tap me]',
      config: MfmRenderConfig(
        localHost: 'example.com',
        onLinkTap: (url) => show('Link: $url'),
        onMentionTap: (acct) => show('Mention: $acct'),
        onHashtagTapDetails: (details) => show('Tag path: ${details.path}'),
        onSearchTap: (query) => show('Search: $query'),
        onClickableEvent: (eventId) => show('Event: $eventId'),
        onCodeCopied: (code) => show('Copied ${code.length} characters'),
        codeCopyTooltip: 'Copy code',
      ),
    );
  }
}
```

## Contrats des callbacks

| Callback | Valeur et comportement |
| --- | --- |
| `onLinkTap` | URL d’origine de la source, pas une destination fiable/filtrée. Aucun lancement automatique sans callback. |
| `onMentionTap` | Compte normalisé. L’hôte est résolu depuis celui explicitement présent dans la mention, puis `author.host`, puis `localHost` ; sans hôte, le compte brut est conservé. |
| `onHashtagTapDetails` | Tag, `isNote` et chemin de navigation encodé. Prioritaire sur `onHashtagTap`. |
| `onHashtagTap` | Repli avec le tag seul si le callback détaillé est absent. |
| `onSearchTap` | Requête de recherche ; l’affichage publié n’est pas le champ modifiable de l’exemple de développement. |
| `onClickableEvent` | Valeur `ev` de `$[clickable.ev=demo ...]` ; sans `ev`, chaîne vide. Sans callback, le contenu est du texte ordinaire. |
| `onCodeCopied` | Code complet après écriture dans le presse-papiers. Remplace la SnackBar de succès par défaut, pas l’écriture elle-même. |

Pour les hashtags, `isNote: true` produit `/tags/<encoded-tag>`, et `false` produit `/user-tags/<encoded-tag>`. Ce sont des chemins relatifs, pas un choix automatique de serveur ou de navigateur de l’application.

## La politique URL et événements appartient à l’application

Traitez les valeurs de callback comme du contenu de publication non fiable. Avant d’ouvrir une URL, validez schéma URI et destination selon votre politique ; ne transmettez pas aveuglément des schémas arbitraires à un launcher. La sélection de profil/serveur, l’authentification, la confirmation des navigations externes et les identifiants clickable autorisés relèvent aussi de l’application. N’interprétez pas un identifiant d’événement comme du code exécutable.

## Retour de copie et accessibilité

Le bouton de copie est visible par défaut. `showCodeBlockCopyButton: false` le masque. `codeCopyTooltip` est son **libellé Semantics**, pas une infobulle visible au survol. Sans `onCodeCopied`, la SnackBar de succès par défaut n’apparaît que si un `ScaffoldMessenger` existe ; `codeCopiedMessage` en modifie le texte. Les valeurs par défaut sont localisées pour le japonais/les autres paramètres de langue.

Conservez `uses-material-design: true` dans la configuration Flutter de l’application pour utiliser les glyphes d’icônes Material intégrés. Si vous remplacez les widgets d’interaction, fournissez des libellés et un comportement de focus équivalents.

## Dépannage

Si une pression ne fait rien, vérifiez le callback correspondant et l’analyse complète (pas `simple`/`plain`). Lorsque les deux callbacks de hashtag sont fournis, seul celui des détails est utilisé. Si une mention mène au mauvais hôte, vérifiez l’`author` par publication et le `localHost` partagé plutôt que de déduire l’hôte du texte affiché.

Suite : [Configuration](configuration.md) · [Émojis personnalisés](custom-emoji.md) · [Animation et accessibilité](animation-accessibility.md)
