---
id: configuration
slug: /configuration
title: 設定
sidebar_label: 設定
---

描画設定とコールバックは`MfmRenderConfig`で指定します。`MfmConfig`は子孫の`MfmText`へ設定を共有するウィジェットです。`MfmRenderOptions`という型はありません。

## 設定を共有する

[導入ページ](getting-started.md)のアプリへ配置する例です。単一のウィジェットだけに適用する場合は、同じ設定を`MfmText(config: ...)`へ渡せます。

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

## 既定値と継承

| 設定 | 既定値・解決方法 |
| --- | --- |
| `enableAdvancedMfm`, `enableAnimation` | ともに`true`。`useAnimation`は両者の論理積です。 |
| `enableNyaize` | `false`。新しいコードでは明示的な`nyaizeMode`を推奨します。 |
| `baseTextStyle` | 設定値、なければ`DefaultTextStyle`。フォントサイズが未指定なら14です。 |
| `brightness` | 明示値、Materialテーマ、Cupertinoテーマ、プラットフォームの明暗設定の順で解決し、lightへフォールバックします。 |
| `lightColorScheme`, `darkColorScheme` | 継承値、または`MfmColorScheme.light()` / `.dark()`。自動採用するのは周囲の**明暗設定**であり、テーマの全配色ではありません。 |
| `codeTheme`, `codeDarkTheme` | lightはgithub。darkは明示的なdarkテーマ、`codeTheme`、atom-one-dark (`atomOneDarkTheme`)の順です。 |
| `showCodeBlockCopyButton` | `null`なら表示。`false`で非表示にします。 |
| `useLocaleSearchButtonLabel` | `false`。`searchButtonLabel`がなければ既定でもロケールから解決します。`true`は明示・継承ラベルを解除して現在のロケールを使い、`searchButtonLabel`より優先されます。 |

nullableな項目は通常、継承設定へフォールバックします。**既定値のboolは常に明示的な上書きになるわけではありません**。子の`enableAnimation: true`では親が無効化したアニメーションを再有効化できません。ノートごとに打ち消すのではなく、共通設定の境界で実効値を決定してください。`MfmConfig`はconfigのインスタンスが変わると依存先へ通知します。可能なら安定したインスタンスを再利用しつつ、テーマやアクセシビリティ設定の変化時には再構築してください。

## 配色・フォント・コード

`lightColorScheme` / `darkColorScheme`で、リンク、メンション、引用、コードなどのMFM配色を指定できます。一部の役割だけを変更する場合は各配色の`copyWith`が便利です。両テーマでコントラストを確認してください。

`fontFamilyResolver`は`serif`や`monospace`などのMFMフォント種別をフォントファミリー名へ変換します。`null`を返すと既定値になります。resolver自体はフォントを読み込みません。独自フォントはアプリへ同梱して宣言してください。このライブラリにGoogle Fontsの依存追加は不要です。

`codeTheme`と`codeDarkTheme`はハイライト用スタイルのmapを受け取ります。`codeDarkTheme`がない場合、独自の`codeTheme`はdark側のフォールバックにもなるため、明るい背景用の配色でコントラストが下がらないよう注意してください。コードコピーのコールバックとラベルは[操作とコールバック](interactions.md)で説明します。

## 猫語変換

- `MfmNyaizeMode.disabled`：変換しません。
- `MfmNyaizeMode.enabled`：投稿者にかかわらず対象テキストを変換します。
- `MfmNyaizeMode.respectAuthor`：`author.isCat`がtrueのとき変換します。

明示したモードは従来の`enableNyaize`より優先されます。表示上の選択であり、アカウント設定や保存済み本文を書き換えません。

## コピーとコンテキストのクリア

`copyWith(field: null)`は元の値を維持し、クリアしません。公開版のリセット用フラグは`clearAuthor`、`clearEmojiUrls`、`clearLocalHost`です。例えば`config.copyWith(clearAuthor: true, clearEmojiUrls: true)`で投稿固有の情報を除いて再利用できます。値と対応するclearフラグを同時に指定すると例外になります。手元のconfigをクリアしても、親の`MfmConfig`から継承される値は消えません。

絵文字ハンドルの`copyWith`はライフサイクルを共有します。独立して破棄できる新しいリソースではありません。[カスタム絵文字](custom-emoji.md)を参照してください。

## よくある問題

設定が反映されない場合は、最寄りの`MfmConfig`、既定値のbool、`enableAdvancedMfm`を確認してください。アプリと配色が異なる場合は、自動的な色の対応付けを期待せずMFM配色を指定してください。

次へ：[カスタム絵文字](custom-emoji.md) · [アニメーションとアクセシビリティ](animation-accessibility.md) · [MfmRenderConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmRenderConfig-class.html)
