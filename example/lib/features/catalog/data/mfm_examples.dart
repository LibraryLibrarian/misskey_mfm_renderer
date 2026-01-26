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
          syntax: r'$[ruby.振り仮名 漢字]',
          mfm: r'$[ruby.かんじ 漢字]',
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
