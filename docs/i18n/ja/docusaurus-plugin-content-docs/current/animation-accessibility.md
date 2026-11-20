---
id: animation-accessibility
slug: /animation-accessibility
title: アニメーションとアクセシビリティ
sidebar_label: アニメーションとアクセシビリティ
---

アニメーションは既定で有効です。また`MfmText`は既定でOSの「動きを減らす」設定（`MediaQuery.disableAnimations`）に追従します。設定が有効な間は`enableAnimation: false`と同じ表示になり、設定の変更にも追従します。

## 動きを減らす設定

この挙動は`followPlatformReducedMotion`で制御します。

| 値 | 結果 |
| --- | --- |
| `null`（既定）または`true` | OSの設定に追従します。有効な間はMFMアニメーションを止め、後述の静止表示にします。 |
| `false` | OSの設定を無視します。MFMアニメーションの有無は`enableAnimation`／`enableAdvancedMfm`だけで決まります。 |

OSの設定はアニメーションを止める方向にだけ働き、`enableAnimation: false`で止めたアニメーションを再開させることはありません。子の設定で明示した`true`／`false`は親を上書きし、`null`は親の値を継承します。`MfmRenderConfig.useAnimation`は設定値だけから求めるため、OSの設定を含みません。

アプリ独自の「効果を無効にする」設定がある場合は`enableAnimation`に組み合わせてください。OSの設定が有効でも利用者がMFMアニメーションを再生できるようにするには、`followPlatformReducedMotion: false`も指定します。[導入ページ](getting-started.md)の`MaterialApp`配下で使用します。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MotionExample extends StatelessWidget {
  const MotionExample({super.key, required this.userPrefersAnimation});

  /// アプリの設定。例えば初期値をOSの設定から決める。
  final bool userPrefersAnimation;

  @override
  Widget build(BuildContext context) {
    return MfmText(
      text: r'$[tada Hello] $[rainbow Color]',
      config: MfmRenderConfig(
        enableAnimation: userPrefersAnimation,
        // アプリの設定にOSの設定を反映済みのため追従しない。
        followPlatformReducedMotion: false,
      ),
    );
  }
}
```

## 2つのスイッチの違い

| 設定 | 結果 |
| --- | --- |
| `enableAnimation: false` | MFMのアニメーションを止め、実装されている静的な装飾・効果は維持します。`tada`は拡大を維持、`rainbow`は静的グラデーション、`sparkle`は効果なしで内容を表示します。 |
| `enableAdvancedMfm: false` | 高度なサイズ・位置の処理も無効化します。単なる動きの制御ではありません。 |
| OSの「動きを減らす」設定（`followPlatformReducedMotion`が`null`／`true`） | `enableAnimation: false`と同じ表示になります。 |
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

MFMアニメーションを止めても動く場合は、まず画像アニメーションとMFM効果を切り分けてください。大きな静的効果も止めたい場合は`enableAdvancedMfm: false`を検討し、結果を確認してください。動きを減らす設定が反映されない場合は、明示・継承した設定で`followPlatformReducedMotion`が`false`になっていないか、`MfmText`より上の`MediaQuery`が`disableAnimations`を伝えているかを確認してください。

次へ：[MFMの描画](rendering.md) · [カスタム絵文字](custom-emoji.md) · [サンプルアプリ](example.md)
