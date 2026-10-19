---
id: overview
slug: /
title: Overview
sidebar_label: Overview
---

# misskey_mfm_renderer

Render [Misskey Flavored Markdown (MFM)](https://misskey-hub.net/en/docs/for-users/features/mfm/) in Flutter with `MfmText`. MFM extends familiar text formatting with features such as custom emoji, transformations, and animations.

The library turns MFM text or parsed nodes into Flutter widgets. It does not fetch a timeline or provide a complete Misskey application. Your application supplies the text, chooses the rendering settings, and handles interactions.

## Start here

- [Getting started](getting-started.md): display your first MFM text without setting up a server connection.
- [Example app](example.md): browse the catalog and try text and settings in the Playground.
- [Detailed README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/README.md): the existing feature tables, configuration guides, and migration notes.
- [API reference](https://pub.dev/documentation/misskey_mfm_renderer/latest/): the generated API documentation for the latest published package.

This documentation foundation covers introduction and setup. Detailed guides are still maintained in the README; they have not yet been moved to this site.

## What you can render

- Text formatting, quotes, code, links, mentions, and hashtags.
- Unicode emoji and custom emoji, with configurable resolution and rendering.
- MFM `fn` functions for size, transforms, styles, and animation.

Rendering can be customized with colors, text styles, callbacks, and animation settings. The [README's supported-function table](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/README.md#supported-fn-functions) describes the supported functions and limitations; this is not a promise that every Misskey feature is implemented.

## Supported environments

The package supports **Android, iOS, macOS, Linux, and Windows**. It requires Flutter **3.38.1 or later** and Dart **3.10.0 or later**.

**Web is not supported.** Although Web builds can compile, the default custom-emoji setup has no Web store and Web rendering has not been tested. This website is documentation, not a browser version of the Flutter example.

Rendered text does not support text selection. Applications that need a copy action should use the original MFM text.

Custom emoji support uses `misskey_emoji`, which is included with this package. The default setup owns a persistent SQLite store and requires initialization and disposal. It is not needed for the [minimal text example](getting-started.md). See the existing [platform notes](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/README.md#platform-notes) before configuring native storage and image loading.

## Published package and development examples

The installation guide uses a published package dependency. The repository's `develop` branch, its README, and its bundled example can include changes that have not yet been published. Check the [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md) before relying on a feature marked as unreleased.
