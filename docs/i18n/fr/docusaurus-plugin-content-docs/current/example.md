---
id: example
slug: /example
title: Application d’exemple
sidebar_label: Application d’exemple
---

Le dépôt contient une application Flutter native permettant de parcourir les exemples MFM et de tester votre propre texte. Son interface est actuellement en **japonais**.

## Lancer l’application

Clonez la branche de développement dans un nouveau répertoire, ou utilisez votre copie existante :

```bash
git clone --branch develop https://github.com/LibraryLibrarian/misskey_mfm_renderer.git
cd misskey_mfm_renderer/example
```

Utilisez le SDK Flutter fixé par le dépôt (`fvm flutter` peut remplacer `flutter`). Listez les appareils disponibles et choisissez une cible native. Ce mode de démarrage est recommandé pour explorer le catalogue sans initialiser le service d’émojis en ligne :

```bash
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=MFM_EXAMPLE_OFFLINE=true
```

Remplacez `<device-id>` par l’identifiant choisi. Ce n’est pas une démonstration Web.

:::note Source de développement

L’exemple dépend du paquet parent via `path: ../`. Il présente le code extrait, y compris des fonctions non publiées, et ne correspond pas nécessairement au dernier paquet sur pub.dev. Consultez le [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md).

:::

## Parcourir et expérimenter

1. **Catalogue (Catalog)** : choisissez une catégorie, par exemple la mise en forme ou les fonctions `fn`. Les exemples associés sont regroupés sur une page.
2. **Essayer avec ces réglages (この設定で試す)** : envoyez le texte et les paramètres de l’exemple au Playground. L’action est une icône avec libellé d’accessibilité et infobulle.
3. **Playground** : modifiez le texte MFM et observez le résultat. L’action d’effacement vide le texte.
4. **Réglages d’affichage (表示設定)** : ouvrez les réglages pour modifier les options communes. Le langage de chat possède une page détaillant ses modes et l’attribut de chat de l’auteur simulé.

L’exemple ne modifie pas l’attribut de chat d’un vrai compte. Liens, mentions, hashtags, actions clickable et recherche affichent une SnackBar plutôt que d’ouvrir un navigateur ou d’envoyer une recherche.

## Comportement hors ligne et en ligne

Sans `MFM_EXAMPLE_OFFLINE=true`, le démarrage initialise les émojis pour misskey.io. Les réglages distinguent initialisation en ligne réussie, démarrage volontairement hors ligne et échec d’initialisation.

Avec l’indicateur hors ligne, l’initialisation des émojis est ignorée. Les contrôles réservés au mode en ligne pour l’auteur distant et `emojiUrls` sont désactivés. Les émojis serveur ordinaires restent des codes courts ; les exemples de repli local, d’avatar et de Twemoji explicitement configurés restent consultables.

L’indicateur contrôle le démarrage à l’exécution, pas l’environnement de compilation. La résolution des dépendances et le hook SQLite peuvent encore nécessiter le réseau. Il n’ajoute pas de prise en charge Web.

## Différences propres au développement

Les guides ciblent la dépendance publiée de « Premiers pas ». La copie de développement capturée contient aussi les changements ci-dessous ; ce tableau **n’est pas** une recette API à copier pour le paquet publié.

| Domaine | Copie de développement (hors API publiée utilisée par les guides) |
| --- | --- |
| Mentions | Présentation en capsule et `MfmMentionOptions`, options de présentation/provider d’avatar. |
| Horodatages | `MfmUnixtimeOptions`, format absolu/relatif et rafraîchissement périodique des libellés relatifs. |
| Émojis | `MfmTwemojiBuilder`, `textStyle` du contexte et `fallbackTextStyle` des émojis personnalisés. |
| Recherche et liens | Recherche modifiable et icônes externes des liens libellés (les URL brutes ont déjà ces icônes dans le paquet publié). |
| Bordures | Neuf styles étendus, RGBA et comportement de découpage. |

## Écrans réels de l’exemple

Ces captures non modifiées d’un émulateur Android proviennent de la **copie de développement**, avec des données fictives hors ligne et l’interface japonaise. Elles illustrent l’application sans garantir des pixels identiques pour le paquet publié. Elles ne représentent aucune vérification visuelle iOS.

<figure className="example-capture">

![Exemple Android de développement : catalogue de mise en forme, données fictives hors ligne, interface japonaise.](/img/example-text-format-android-develop.png)

<figcaption>Exemple Android de développement — catalogue de mise en forme, données fictives hors ligne, interface japonaise. Thème clair et réglages communs par défaut.</figcaption>
</figure>

<figure className="example-capture">

![Exemple Android de développement : Playground, données fictives hors ligne, interface japonaise.](/img/example-playground-android-develop.png)

<figcaption>Exemple Android de développement — Playground, données fictives hors ligne, interface japonaise. L’exemple sélectionné du catalogue est chargé avec ses réglages, sans modification.</figcaption>
</figure>

Révision, empreintes des PNG originaux et conditions de reproduction figurent dans la [provenance des captures](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/docs/screenshots.md).

## En savoir plus

Le [README de l’exemple](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md) détaille catalogue, réglages, données locales de test et configuration des plateformes. Pour intégrer la bibliothèque à votre application, commencez par [Premiers pas](getting-started.md).
