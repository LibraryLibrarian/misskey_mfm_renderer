---
id: animation-accessibility
slug: /animation-accessibility
title: アニメーションとアクセシビリティ
sidebar_label: アニメーションとアクセシビリティ
---

アニメーションは既定で有効です。レンダラーはOSの「動きを減らす」設定とアニメーションフラグを**自動では連動させません**。アプリ側の境界で接続してください。

## 動きを減らす設定を反映する

[導入ページ](getting-started.md)の`MaterialApp`配下で使用します。`MediaQuery.disableAnimations`の変更を監視する例です。アプリ独自の「効果を無効にする」設定も同じboolへ組み合わせられます。

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

## 2つのスイッチの違い

| 設定 | 結果 |
| --- | --- |
| `enableAnimation: false` | MFMのアニメーションを止め、実装されている静的な装飾・効果は維持します。`tada`は拡大を維持、`rainbow`は静的グラデーション、`sparkle`は効果なしで内容を表示します。 |
| `enableAdvancedMfm: false` | 高度なサイズ・位置の処理も無効化します。単なる動きの制御ではありません。 |
| 両方有効 | MFMアニメーションを許可します（`useAnimation == true`）。 |

どちらも**GIF／APNG／WebP絵文字画像**のアニメーションは止めません。静止画像へ置き換えるなど、image／emoji builderとアプリの方針で制御してください。親で無効化したアニメーションは、子で既定の`true`を渡すだけでは再有効化できません。[設定](configuration.md)を参照してください。

MFMアニメーションの`speed`／`delay`は秒表記です。例えば`$[spin.speed=2s text]`を使用し、`2000ms`とは指定しません。Dart内の`$[...]`はraw文字列にしてください。

## 読み上げ・フォーカス・隠した内容

- `blur`は視覚効果だけです。内容はsemanticsから除外されず、支援技術で読み上げられる場合があります。**機密情報を隠す用途には使わないでください。**
- ルビや埋め込みWidgetSpanは、読み上げ順序や発音が見た目と異なる場合があります。完全なアクセシビリティ対応を仮定せず、対象端末のTalkBack／VoiceOverで確認してください。
- テキスト選択は未実装です。コピーや別の読み上げ表示が必要なら、元の内容と明示的なテキスト変換規則を使ってアプリ側に用意してください。
- 独自の絵文字・操作ウィジェットには意味のあるラベルを設け、MFMの両配色で十分なコントラストを確保してください。コードコピーのラベルは[操作とコールバック](interactions.md)で説明します。
- 大きいシステム文字サイズ、長いリンク、引用、画面全体のキーボード・フォーカス操作を確認してください。スクリーンショットだけでは読み上げ対応を確認できません。

## 負荷とよくある問題

密度の高いタイムラインでは、resolver／configインスタンスの不要な再作成を避け、同じ本文の解析結果を再利用し、同時に表示するアニメーション数を制限してください。対象端末で計測してから方針を決めてください。一定のフレームレートや画面外の全エフェクトの自動停止は保証しません。

MFMアニメーションを止めても動く場合は、まず画像アニメーションとMFM効果を切り分けてください。大きな静的効果も止めたい場合は`enableAdvancedMfm: false`を検討し、結果を確認してください。動きを減らす設定が反映されない場合は、`MediaQuery`との接続と継承設定を確認してください。

次へ：[MFMの描画](rendering.md) · [カスタム絵文字](custom-emoji.md) · [サンプルアプリ](example.md)
