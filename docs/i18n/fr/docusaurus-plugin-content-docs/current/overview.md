---
id: overview
slug: /
title: Vue d’ensemble
sidebar_label: Vue d’ensemble
---

# misskey_mfm_renderer

Affichez du [Misskey Flavored Markdown (MFM)](https://misskey-hub.net/en/docs/for-users/features/mfm/) dans Flutter avec `MfmText`. MFM enrichit la mise en forme habituelle avec des émojis personnalisés, des transformations et des animations.

La bibliothèque transforme du texte MFM ou des nœuds déjà analysés en widgets Flutter. Elle ne charge pas de fil de publications et ne constitue pas une application Misskey complète. Votre application fournit le texte, choisit les paramètres de rendu et traite les interactions.

## Pour commencer

- [Premiers pas](getting-started.md) : afficher un premier texte MFM sans connexion à un serveur.
- [Application d’exemple](example.md) : parcourir le catalogue et essayer textes et réglages dans le Playground.
- [Rendu](rendering.md) : entrées, modes d’affichage, syntaxe prise en charge et limites.
- [Configuration](configuration.md) : styles partagés, couleurs, polices et langage de chat.
- [Émojis personnalisés](custom-emoji.md) : initialisation, gestion des ressources, publications distantes et builders personnalisés.
- [Interactions](interactions.md) : callbacks et politique de navigation de l’application.
- [Animation et accessibilité](animation-accessibility.md) : réduction des mouvements et limites de lecture.
- [Référence API](https://pub.dev/documentation/misskey_mfm_renderer/latest/) : documentation générée de la dernière version publiée du paquet.

Les exemples à copier ciblent le paquet publié indiqué dans « Premiers pas ». Les fonctions et captures propres à la version de développement sont signalées séparément sur la page de l’exemple.

## Contenus affichables

- Mise en forme du texte, citations, code, liens, mentions et hashtags.
- Émojis Unicode et personnalisés, avec résolution et rendu configurables.
- Fonctions MFM `fn` pour la taille, les transformations, les styles et les animations.

Le rendu se personnalise avec les couleurs, styles de texte, callbacks et réglages d’animation. Le [guide du rendu](rendering.md) décrit les fonctions prises en charge et leurs limites ; il ne garantit pas que toutes les fonctions de Misskey sont implémentées.

## Environnements pris en charge

Le paquet prend en charge **Android, iOS, macOS, Linux et Windows**. Il nécessite Flutter **3.38.1 ou ultérieur** et Dart **3.10.0 ou ultérieur**.

**Le Web n’est pas pris en charge.** Une compilation Web peut réussir, mais la configuration par défaut des émojis ne dispose pas de stockage Web et le rendu Web n’a pas été testé. Ce site est une documentation, pas une version navigateur de l’exemple Flutter.

Le texte affiché n’est pas sélectionnable. Une application proposant la copie doit utiliser le texte MFM d’origine.

Les émojis personnalisés utilisent `misskey_emoji`, inclus avec ce paquet. La configuration par défaut possède un stockage SQLite persistant qui doit être initialisé puis libéré. L’[exemple minimal de texte](getting-started.md) n’en a pas besoin. Consultez le [guide des émojis](custom-emoji.md) avant de configurer le stockage natif et le chargement d’images.

## Paquet publié et exemples de développement

Le guide d’installation utilise une dépendance publiée. La branche `develop`, son README et l’application d’exemple peuvent contenir des changements non encore publiés. Consultez le [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md) avant de vous appuyer sur une fonction marquée comme non publiée.
