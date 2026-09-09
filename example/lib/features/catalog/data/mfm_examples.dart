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
          name: 'Italic (HTML)',
          syntax: '<i>text</i>',
          mfm: '<i>HTML形式の斜体</i>',
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
        MfmExample(
          name: 'Small (ネスト)',
          syntax: '<small><small>text</small></small>',
          mfm: '<small>外側 <small>内側はさらに小さく薄く表示</small></small>',
          description: 'ネストごとに文字サイズは0.8倍、不透明度は0.7倍になります',
        ),
        MfmExample(
          name: 'Plain',
          syntax: r'<plain>**text**$[x2 text]</plain>',
          mfm: r'<plain>**そのまま**$[x2 表示]</plain>',
          description: '内側の構文は解釈されず、そのまま表示されます',
        ),
        MfmExample(
          name: 'Center',
          syntax: '<center>text</center>',
          mfm: '<center>中央揃え</center>',
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
          name: 'Quote (複数行)',
          syntax: '> line 1\n> line 2',
          mfm: '> 1行目\n> 2行目',
        ),
        MfmExample(
          name: 'Quote (ネスト)',
          syntax: '>> text',
          mfm: '>> 二重の引用',
        ),
        MfmExample(
          name: 'Quote (fn内)',
          syntax: r'> $[x2 text]',
          mfm: r'> $[x2 大きい引用]',
        ),
        MfmExample(
          name: 'Quote (連続)',
          syntax: '> first\n\n> second',
          mfm: '> 1つ目の引用\n\n> 2つ目の引用',
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
        MfmExample(
          name: 'Math Block',
          syntax: r'\[ x^2 + y^2 = z^2 \]',
          mfm: r'\[ x^2 + y^2 = z^2 \]',
          description: '等幅の式文字列として表示され、LaTeX組版は行いません',
        ),
        MfmExample(
          name: 'Math Inline',
          syntax: r'\( E = mc^2 \)',
          mfm: r'質量とエネルギーの関係は \( E = mc^2 \) です。',
          description: '等幅の式文字列として表示され、LaTeX組版は行いません',
        ),
        MfmExample(
          name: 'Search',
          syntax: 'keyword 検索 / keyword [検索] / keyword Search',
          mfm: 'Misskey 検索\nMisskey [検索]\nMisskey Search',
          description: 'ボタンをタップすると onSearchTap が呼ばれます',
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
          name: 'URL (分解表示)',
          syntax: 'https://example.org/notes/abcdef?from=timeline#reply',
          mfm: 'https://example.org/notes/abcdef?from=timeline#reply',
          description: 'スキーム・クエリは減光、ホストは太字、ハッシュは斜体で外部リンクアイコンを表示します',
        ),
        MfmExample(
          name: 'URL (punycode)',
          syntax: 'https://xn--wgv71a119e.jp/%E3%83%86%E3%82%B9%E3%83%88',
          mfm: 'https://xn--wgv71a119e.jp/%E3%83%86%E3%82%B9%E3%83%88',
          description: 'ホストは日本語.jpに復号し、パスもデコードして表示します',
        ),
        MfmExample(
          name: 'URL (自ホスト)',
          syntax: 'https://misskey.io/@syuilo',
          mfm: 'https://misskey.io/@syuilo',
          description: 'localHost=misskey.ioではスキームとホストを省略して表示します',
        ),
        MfmExample(
          name: 'Link',
          syntax: '[label](url)',
          mfm: '[Misskey公式](https://misskey.io)',
        ),
        MfmExample(
          name: 'Link (ラベル付き)',
          syntax: '[label](https://example.org/@user)',
          mfm: '[ユーザープロフィール](https://example.org/@user)',
        ),
        MfmExample(
          name: 'Silent Link',
          syntax: '?[label](url)',
          mfm: '?[サイレントリンク](https://example.org)',
          description: 'レンダラーでは通常リンクと同じ表示になります',
        ),
        MfmExample(
          name: 'Mention',
          syntax: '@user',
          mfm: '@example_user',
        ),
        MfmExample(
          name: 'Mention (リモート)',
          syntax: '@user@host',
          mfm: '@user@misskey.example',
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
          name: 'Custom Emoji (misskey.io)',
          syntax: ':emoji1: :emoji2: :emoji3:',
          mfm: ':ai_smile_misskeyio: :ai_pointing_misskeyio: :misskey_loading:',
          description: 'Misskey.ioで実在するカスタム絵文字',
        ),
        MfmExample(
          name: 'Custom Emoji + Text (misskey.io)',
          syntax: 'テキスト :emoji: テキスト',
          mfm: 'こんにちは :pudding_cat: よろしく :icon_syuilo:',
          description: 'Misskey.ioの実在絵文字を混在表示',
        ),
        MfmExample(
          name: 'Custom Emoji (存在しない)',
          syntax: ':not_exist_emoji:',
          mfm: ':not_exist_emoji:',
          description: '存在しない絵文字はショートコードのまま表示されます',
        ),
        MfmExample(
          name: 'Custom Emoji (リモート)',
          syntax: ':ai_smile_misskeyio: :pudding_cat: :not_in_map:',
          mfm: ':ai_smile_misskeyio: :pudding_cat: :not_in_map:',
          description:
              '設定パネルの「リモート投稿として扱う」「emojiUrls を渡す」「絵文字の文脈を表示」で経路が変わります。'
              'ローカルresolver、直接URL、mapにキー無しならショートコード、'
              'mapなしならリモートエンドポイント取得となり、失敗時はショートコード表示です',
        ),
        MfmExample(
          name: 'Custom Emoji (x2)',
          syntax: r'$[x2 :ai_smile_misskeyio:]',
          mfm: r'$[x2 :ai_smile_misskeyio:]',
          description: '絵文字も x2 の中では拡大します',
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
          description: 'Advanced MFM をオフにすると拡大しません',
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
        MfmExample(
          name: 'x2 (ネスト)',
          syntax: r'$[x2 $[x2 text]]',
          mfm: r'$[x2 $[x2 ネスト]]',
          description: '実効サイズは3倍になり、3段目以降は拡大しません',
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
          name: 'Flip (both)',
          syntax: r'$[flip.h,v text]',
          mfm: r'$[flip.h,v 両方反転]',
        ),
        MfmExample(
          name: 'Rotate',
          syntax: r'$[rotate.deg=45 text]',
          mfm: r'$[rotate.deg=45 45度回転]',
        ),
        MfmExample(
          name: 'Rotate (負角度)',
          syntax: r'$[rotate.deg=-30 text]',
          mfm: r'$[rotate.deg=-30 左に30度回転]',
        ),
        MfmExample(
          name: 'Scale',
          syntax: r'$[scale.x=2,y=0.5 text]',
          mfm: r'$[scale.x=2,y=0.5 拡大縮小]',
        ),
        MfmExample(
          name: 'Scale (上限)',
          syntax: r'$[scale.x=10,y=10 text]',
          mfm: r'$[scale.x=10,y=10 上限]',
          description: '各軸の倍率は ±5 に制限されます',
        ),
        MfmExample(
          name: 'Position',
          syntax: r'$[position.x=1,y=1 text]',
          mfm: r'$[position.x=1,y=1 位置移動]',
        ),
        MfmExample(
          name: 'Position (負値)',
          syntax: r'$[position.x=-1,y=-0.5 text]',
          mfm: r'$[position.x=-1,y=-0.5 左上へ移動]',
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
          name: 'Foreground Color (3桁)',
          syntax: r'$[fg.color=f00 text]',
          mfm: r'$[fg.color=f00 3桁]',
        ),
        MfmExample(
          name: 'Foreground Color (RGBA)',
          syntax: r'$[fg.color=0f08 text]',
          mfm: r'$[fg.color=0f08 4桁RGBA]',
          description: '4桁のRGBA形式も指定できます',
        ),
        MfmExample(
          name: 'Foreground Color (不正値)',
          syntax: r'$[fg.color=zzz text]',
          mfm: r'$[fg.color=zzz 不正値→赤]',
          description: '3〜6桁の16進数以外は赤で表示されます',
        ),
        MfmExample(
          name: 'Background Color',
          syntax: r'$[bg.color=00ff00 text]',
          mfm: r'$[bg.color=00ff00 緑の背景]',
        ),
        MfmExample(
          name: 'Background Color (3桁)',
          syntax: r'$[bg.color=ff0 text]',
          mfm: r'$[bg.color=ff0 背景]',
        ),
        MfmExample(
          name: 'Border',
          syntax: r'$[border.color=0000ff text]',
          mfm: r'$[border.color=0000ff 青い枠線]',
        ),
        MfmExample(
          name: 'Border (オプション)',
          syntax: r'$[border.width=3,radius=8 text]',
          mfm: r'$[border.width=3,radius=8 枠線オプション]',
        ),
        MfmExample(
          name: 'Border (破線指定)',
          syntax: r'$[border.style=dashed text]',
          mfm: r'$[border.style=dashed 破線指定]',
          description: '破線・点線の指定は実線にフォールバックします',
        ),
        MfmExample(
          name: 'Border (既定色)',
          syntax: r'$[border text]',
          mfm: r'$[border 既定色]',
          description: '色を省略すると accent 色の枠線になります',
        ),
        MfmExample(
          name: 'Font',
          syntax: r'$[font.monospace text]',
          mfm: r'$[font.monospace 等幅フォント]',
        ),
        MfmExample(
          name: 'Font (serif)',
          syntax: r'$[font.serif text]',
          mfm: r'$[font.serif セリフ体]',
        ),
        MfmExample(
          name: 'Font (cursive)',
          syntax: r'$[font.cursive text]',
          mfm: r'$[font.cursive 筆記体]',
        ),
        MfmExample(
          name: 'Font (fantasy)',
          syntax: r'$[font.fantasy text]',
          mfm: r'$[font.fantasy ファンタジー]',
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
        MfmExample(
          name: 'Unixtime (過去)',
          syntax: r'$[unixtime 1700000000]',
          mfm: r'$[unixtime 1700000000]',
        ),
        MfmExample(
          name: 'Unixtime (未来)',
          syntax: r'$[unixtime 2000000000]',
          mfm: r'$[unixtime 2000000000]',
        ),
        MfmExample(
          name: 'Clickable',
          syntax: r'$[clickable.ev=hello text]',
          mfm: r'$[clickable.ev=hello タップで onClickableEvent]',
          description: 'タップすると onClickableEvent が呼ばれます',
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
          name: 'Spin (速度0)',
          syntax: r'$[spin.speed=0s text]',
          mfm: r'$[spin.speed=0s 通常表示]',
          description: 'speed が 0 のときは通常表示になります',
        ),
        MfmExample(
          name: 'Spin (負の遅延)',
          syntax: r'$[spin.delay=-0.5s text]',
          mfm: r'$[spin.delay=-0.5s 位相を進めて開始]',
          description: '0.5秒進んだ位相から開始します',
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
          name: 'Twitch / Shake (easing)',
          syntax: r'$[twitch text] $[shake text]',
          mfm: r'$[twitch twitch] $[shake shake]',
          description: 'どちらも隣接するキーフレーム間ごとに ease を適用します',
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
          description: '150%サイズで揺れ、Advanced MFM をオフにしても150%の拡大は残ります',
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
          name: 'Rainbow (無彩色)',
          syntax: r'$[rainbow $[fg.color=888 text]]',
          mfm: r'$[rainbow $[fg.color=888 灰色の本文]]',
          description: 'hue-rotateのため無彩色は色相が循環せず、明度だけがわずかに変化します',
        ),
        MfmExample(
          name: 'Rainbow (有彩色)',
          syntax: r'$[rainbow $[fg.color=f00 text]]',
          mfm: r'$[rainbow $[fg.color=f00 赤い文字]]',
          description: 'アニメーション無効時は静的な虹色で表示します',
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
        MfmExample(
          name: 'Nyaize',
          syntax: '通常の文章',
          mfm: 'なんとなく、明日はいい天気になりそうだな。Everyone, good morning!',
          description: '設定の nyaize モードと「投稿者は猫」で変化します',
        ),
        MfmExample(
          name: 'Plain / Nowrap',
          syntax: '複数行の長文',
          mfm:
              'これは複数行で表示するための少し長いテキストです。構文の **太字** も含みます。\n'
              '設定の plain では改行が空白になり、nowrap では1行に省略表示されます。',
          description: '設定の plain で改行が空白に、nowrap で1行に省略表示されます',
        ),
        MfmExample(
          name: '本家ノート風の複合例',
          syntax: 'メンション・タグ・URL・引用・コード・絵文字・fnを含む投稿',
          mfm: r'''@alice こんにちは、#MFM の確認です。
https://example.org/notes/abcdef?from=timeline#reply
> $[fg.color=0af 引用内の色付きテキスト]
> 2行目の引用です。
`inline code` と :ai_smile_misskeyio: を並べます。
```dart
final message = 'hello';
```
$[x2 $[rainbow 完了！]] ?[関連リンク](https://example.org/docs)''',
          description: '本家のノートに近い複数要素の組み合わせです',
        ),
      ],
    ),
  ];
}
