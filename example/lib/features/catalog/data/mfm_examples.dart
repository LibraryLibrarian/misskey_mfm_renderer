/// MFMサンプルのカテゴリ
class MfmCategory {
  const MfmCategory({
    required this.title,
    required this.examples,
  });

  final String title;
  final List<MfmExample> examples;
}

/// MFMサンプル
class MfmExample {
  const MfmExample({
    required this.name,
    required this.syntax,
    required this.mfm,
    this.description,
  });

  /// サンプル名
  final String name;

  /// MFM構文（表示用）
  final String syntax;

  /// 実際のMFMテキスト
  final String mfm;

  /// 説明（オプション）
  final String? description;
}

/// 全MFMサンプルデータ
class MfmExamples {
  MfmExamples._();

  static const List<MfmCategory> categories = [
    // テキスト整形
    MfmCategory(
      title: 'テキスト整形',
      examples: [
        MfmExample(
          name: 'Bold',
          syntax: '**text**',
          mfm: '**太字テキスト**',
        ),
        MfmExample(
          name: 'Italic',
          syntax: '*text*',
          mfm: '*斜体テキスト*',
        ),
        MfmExample(
          name: 'Strike',
          syntax: '~~text~~',
          mfm: '~~打ち消し線~~',
        ),
        MfmExample(
          name: 'Small',
          syntax: '<small>text</small>',
          mfm: '<small>小さいテキスト</small>',
        ),
      ],
    ),

    // ブロック要素
    MfmCategory(
      title: 'ブロック要素',
      examples: [
        MfmExample(
          name: 'Quote',
          syntax: '> text',
          mfm: '> 引用テキスト',
        ),
        MfmExample(
          name: 'Center',
          syntax: '<center>text</center>',
          mfm: '<center>中央揃え</center>',
        ),
        MfmExample(
          name: 'Code Block',
          syntax: '```code```',
          mfm: '```dart\nvoid main() {\n  print("Hello");\n}\n```',
        ),
        MfmExample(
          name: 'Code Block (JavaScript)',
          syntax: '```javascript\ncode\n```',
          mfm:
              '```javascript\n'
              'function hello() {\n'
              '  console.log("Hello, World!");\n'
              '  return true;\n'
              '}\n'
              '```',
          description: 'JavaScript コードのシンタックスハイライト',
        ),
        MfmExample(
          name: 'Code Block (Python)',
          syntax: '```python\ncode\n```',
          mfm:
              '```python\n'
              'def greet(name):\n'
              '    print(f"Hello, {name}!")\n'
              '\n'
              'greet("World")\n'
              '```',
          description: 'Python コードのシンタックスハイライト',
        ),
        MfmExample(
          name: 'Code Block (JSON)',
          syntax: '```json\ncode\n```',
          mfm:
              '```json\n'
              '{\n'
              '  "name": "misskey",\n'
              '  "version": "1.0.0",\n'
              '  "features": ["mfm", "notes"]\n'
              '}\n'
              '```',
          description: 'JSON のシンタックスハイライト',
        ),
        MfmExample(
          name: 'Code Block (Dart)',
          syntax: '```dart\ncode\n```',
          mfm:
              '```dart\n'
              'List<MfmNode> _parseText() {\n'
              '  final source = text;\n'
              '  if (source == null || source.isEmpty) {\n'
              '    return [];\n'
              '  }\n'
              '\n'
              '  final parser = simple ? MfmParser().buildSimple() : '
              'MfmParser().build();\n'
              '  final result = parser.parse(source);\n'
              '  try {\n'
              '    return result.value;\n'
              '  } on FormatException {\n'
              '    // パース失敗時はプレーンテキストとして返す\n'
              '    return [TextNode(source)];\n'
              '  }\n'
              '}\n'
              '```',
          description: '既存コードの抜粋（Dart）',
        ),
        MfmExample(
          name: 'Code Block (言語指定なし)',
          syntax: '```\ncode\n```',
          mfm:
              '```\n'
              'This is plain text code\n'
              'without any language specification.\n'
              '```',
          description: '言語指定なしの場合はプレーンテキスト表示',
        ),
        MfmExample(
          name: 'Inline Code',
          syntax: '`code`',
          mfm: 'インライン`コード`の例',
        ),
      ],
    ),

    // リンク・参照
    MfmCategory(
      title: 'リンク・参照',
      examples: [
        MfmExample(
          name: 'URL',
          syntax: 'https://example.com',
          mfm: 'https://misskey.io',
        ),
        MfmExample(
          name: 'Link',
          syntax: '[label](url)',
          mfm: '[Misskey公式](https://misskey.io)',
        ),
        MfmExample(
          name: 'Mention',
          syntax: '@user',
          mfm: '@example_user',
        ),
        MfmExample(
          name: 'Hashtag',
          syntax: '#tag',
          mfm: '#MisskeyMFM',
        ),
      ],
    ),

    // 絵文字
    MfmCategory(
      title: '絵文字',
      examples: [
        MfmExample(
          name: 'Unicode Emoji',
          syntax: '絵文字をそのまま',
          mfm: '🎉 こんにちは！ 😊',
        ),
        MfmExample(
          name: 'Custom Emoji',
          syntax: ':emoji_name:',
          mfm: ':wave: :smile:',
          description: 'カスタム絵文字（プレースホルダー表示）',
        ),
      ],
    ),

    // fn関数 - サイズ
    MfmCategory(
      title: 'fn関数 - サイズ',
      examples: [
        MfmExample(
          name: 'x2',
          syntax: r'$[x2 text]',
          mfm: r'$[x2 2倍サイズ]',
        ),
        MfmExample(
          name: 'x3',
          syntax: r'$[x3 text]',
          mfm: r'$[x3 3倍サイズ]',
        ),
        MfmExample(
          name: 'x4',
          syntax: r'$[x4 text]',
          mfm: r'$[x4 4倍サイズ]',
        ),
      ],
    ),

    // fn関数 - 変換
    MfmCategory(
      title: 'fn関数 - 変換',
      examples: [
        MfmExample(
          name: 'Flip (horizontal)',
          syntax: r'$[flip text]',
          mfm: r'$[flip 左右反転]',
        ),
        MfmExample(
          name: 'Flip (vertical)',
          syntax: r'$[flip.v text]',
          mfm: r'$[flip.v 上下反転]',
        ),
        MfmExample(
          name: 'Rotate',
          syntax: r'$[rotate.deg=45 text]',
          mfm: r'$[rotate.deg=45 45度回転]',
        ),
        MfmExample(
          name: 'Scale',
          syntax: r'$[scale.x=2,y=0.5 text]',
          mfm: r'$[scale.x=2,y=0.5 拡大縮小]',
        ),
        MfmExample(
          name: 'Position',
          syntax: r'$[position.x=1,y=1 text]',
          mfm: r'$[position.x=1,y=1 位置移動]',
        ),
      ],
    ),

    // fn関数 - スタイル
    MfmCategory(
      title: 'fn関数 - スタイル',
      examples: [
        MfmExample(
          name: 'Foreground Color',
          syntax: r'$[fg.color=ff0000 text]',
          mfm: r'$[fg.color=ff0000 赤い文字]',
        ),
        MfmExample(
          name: 'Background Color',
          syntax: r'$[bg.color=00ff00 text]',
          mfm: r'$[bg.color=00ff00 緑の背景]',
        ),
        MfmExample(
          name: 'Border',
          syntax: r'$[border.color=0000ff text]',
          mfm: r'$[border.color=0000ff 青い枠線]',
        ),
        MfmExample(
          name: 'Font',
          syntax: r'$[font.monospace text]',
          mfm: r'$[font.monospace 等幅フォント]',
        ),
      ],
    ),

    // fn関数 - 特殊
    MfmCategory(
      title: 'fn関数 - 特殊',
      examples: [
        MfmExample(
          name: 'Blur',
          syntax: r'$[blur text]',
          mfm: r'$[blur ぼかし（タップで解除）]',
        ),
        MfmExample(
          name: 'Ruby',
          syntax: r'$[ruby 漢字 振り仮名]',
          mfm: r'$[ruby 漢字 かんじ]',
        ),
      ],
    ),

    // fn関数 - アニメーション
    MfmCategory(
      title: 'fn関数 - アニメーション',
      examples: [
        MfmExample(
          name: 'Spin (Z軸)',
          syntax: r'$[spin text]',
          mfm: r'$[spin 回転]',
          description: '通常のZ軸回転',
        ),
        MfmExample(
          name: 'Spin (X軸)',
          syntax: r'$[spin.x text]',
          mfm: r'$[spin.x X軸回転]',
          description: '3D X軸回転',
        ),
        MfmExample(
          name: 'Spin (Y軸)',
          syntax: r'$[spin.y text]',
          mfm: r'$[spin.y Y軸回転]',
          description: '3D Y軸回転',
        ),
        MfmExample(
          name: 'Spin (逆回転)',
          syntax: r'$[spin.left text]',
          mfm: r'$[spin.left 左回り]',
          description: '逆方向に回転',
        ),
        MfmExample(
          name: 'Spin (往復)',
          syntax: r'$[spin.alternate text]',
          mfm: r'$[spin.alternate 往復回転]',
          description: '往復で回転',
        ),
        MfmExample(
          name: 'Spin (速度調整)',
          syntax: r'$[spin.speed=0.5s text]',
          mfm: r'$[spin.speed=0.5s 高速回転]',
          description: 'アニメーション速度を指定',
        ),
        MfmExample(
          name: 'Jump',
          syntax: r'$[jump text]',
          mfm: r'$[jump ジャンプ!]',
          description: '跳ねるアニメーション',
        ),
        MfmExample(
          name: 'Jump (速度調整)',
          syntax: r'$[jump.speed=0.5s text]',
          mfm: r'$[jump.speed=0.5s 速くジャンプ!]',
        ),
        MfmExample(
          name: 'Bounce',
          syntax: r'$[bounce text]',
          mfm: r'$[bounce バウンス]',
          description: '弾むアニメーション',
        ),
        MfmExample(
          name: 'Bounce (速度調整)',
          syntax: r'$[bounce.speed=0.5s text]',
          mfm: r'$[bounce.speed=0.5s 速くバウンス]',
        ),
        MfmExample(
          name: 'Shake',
          syntax: r'$[shake text]',
          mfm: r'$[shake ガタガタ]',
          description: '震えるアニメーション',
        ),
        MfmExample(
          name: 'Shake (速度調整)',
          syntax: r'$[shake.speed=0.3s text]',
          mfm: r'$[shake.speed=0.3s 激しく震える]',
        ),
        MfmExample(
          name: 'Twitch',
          syntax: r'$[twitch text]',
          mfm: r'$[twitch ビクビク]',
          description: 'ランダムに動くアニメーション',
        ),
        MfmExample(
          name: 'Twitch (速度調整)',
          syntax: r'$[twitch.speed=0.3s text]',
          mfm: r'$[twitch.speed=0.3s 激しく動く]',
        ),
        MfmExample(
          name: 'Jelly',
          syntax: r'$[jelly text]',
          mfm: r'$[jelly ぷるぷる]',
          description: 'ゼリーのように揺れる',
        ),
        MfmExample(
          name: 'Jelly (速度調整)',
          syntax: r'$[jelly.speed=0.5s text]',
          mfm: r'$[jelly.speed=0.5s 速く揺れる]',
        ),
        MfmExample(
          name: 'Tada',
          syntax: r'$[tada text]',
          mfm: r'$[tada じゃーん!]',
          description: '150%サイズで揺れるアニメーション',
        ),
        MfmExample(
          name: 'Tada (速度調整)',
          syntax: r'$[tada.speed=0.5s text]',
          mfm: r'$[tada.speed=0.5s 速くじゃーん!]',
        ),
        MfmExample(
          name: 'Rainbow',
          syntax: r'$[rainbow text]',
          mfm: r'$[rainbow 虹色]',
          description: 'レインボーカラーアニメーション',
        ),
        MfmExample(
          name: 'Rainbow (速度調整)',
          syntax: r'$[rainbow.speed=0.5s text]',
          mfm: r'$[rainbow.speed=0.5s 速く虹色]',
        ),
        MfmExample(
          name: 'Sparkle',
          syntax: r'$[sparkle text]',
          mfm: r'$[sparkle ✨キラキラ✨]',
          description: 'スパークルエフェクト',
        ),
        MfmExample(
          name: 'Sparkle (短いテキスト)',
          syntax: r'$[sparkle text]',
          mfm: r'通常のテキスト紛れて $[sparkle ここだけ] 反映がされる',
          description: 'エフェクトを特定のテキスト周辺のみに適用',
        ),
        MfmExample(
          name: 'Sparkle (長いテキスト)',
          syntax: r'$[sparkle text]',
          mfm: r'$[sparkle 長めのテキストでsparkleエフェクトの範囲を確認するためのサンプル]',
          description: '長めのテキストに対して全体にまんべんなくエフェクトが適用',
        ),
        MfmExample(
          name: 'アニメーション遅延',
          syntax: r'$[spin.delay=1s text]',
          mfm: r'$[spin.delay=1s 1秒後に回転]',
          description: 'アニメーション開始を遅延',
        ),
      ],
    ),

    // 組み合わせ
    MfmCategory(
      title: '組み合わせ例',
      examples: [
        MfmExample(
          name: 'ネスト',
          syntax: '複数のMFMを組み合わせ',
          mfm: r'**$[fg.color=ff6600 オレンジの太字]**',
        ),
        MfmExample(
          name: '複合例',
          syntax: '様々な要素を含むテキスト',
          mfm: r'''こんにちは！ 😊

**太字**や*斜体*、~~打ち消し~~も使えます。

> 引用も可能

$[x2 大きな文字]も$[fg.color=ff0000 色付き文字]も！

@user さんへの #MFM のデモです。''',
        ),
      ],
    ),
  ];
}
