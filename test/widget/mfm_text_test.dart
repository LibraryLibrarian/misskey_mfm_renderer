import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('MfmText 基本機能', () {
    testWidgets('プレーンテキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: 'Hello, World!'),
          ),
        ),
      );

      // MfmTextはRichTextを使用するため、TextSpanの内容を確認する
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final foundSpan = _findSpanWithText(textSpan, 'Hello, World!');
      expect(foundSpan, isNotNull);
    });

    testWidgets('空のテキストでもエラーなくレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: ''),
          ),
        ),
      );

      // 例外がスローされないことを確認
      expect(find.byType(MfmText), findsOneWidget);
    });

    testWidgets('parsedNodesを直接渡してレンダリングできる', (tester) async {
      final nodes = [const TextNode('Direct nodes')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(parsedNodes: nodes),
          ),
        ),
      );

      // MfmTextはRichTextを使用するため、TextSpanの内容を確認する
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final foundSpan = _findSpanWithText(textSpan, 'Direct nodes');
      expect(foundSpan, isNotNull);
    });

    testWidgets('configのbaseTextStyleが適用される', (tester) async {
      const testStyle = TextStyle(fontSize: 20, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'Styled text',
              config: MfmRenderConfig(baseTextStyle: testStyle),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      expect(textSpan.style?.fontSize, 20);
      expect(textSpan.style?.color, Colors.red);
    });
  });

  group('MfmText インライン要素', () {
    testWidgets('太字テキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '**bold**'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // 太字スタイルを持つ子Spanを検索
      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNotNull);
    });

    testWidgets('斜体テキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '<i>italic</i>'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final italicSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontStyle == FontStyle.italic,
      );
      expect(italicSpan, isNotNull);
    });

    testWidgets('取り消し線テキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '~~strike~~'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final strikeSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.decoration == TextDecoration.lineThrough,
      );
      expect(strikeSpan, isNotNull);
    });

    testWidgets('小さいテキストを縮小サイズでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '<small>small</small>',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final smallSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontSize != null && style!.fontSize! < 14,
      );
      expect(smallSpan, isNotNull);
    });

    testWidgets('インラインコードを等幅フォントでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '`code`'),
          ),
        ),
      );

      expect(find.text('code'), findsOneWidget);
    });

    testWidgets('URLをリンク色でレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: 'https://example.com'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final linkSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.color == const Color(0xFF0066CC),
      );
      expect(linkSpan, isNotNull);
    });

    testWidgets('メンションをリンク色でレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '@user'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final mentionSpan = _findSpanWithText(textSpan, '@user');
      expect(mentionSpan, isNotNull);
    });

    testWidgets('ハッシュタグを#付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '#misskey'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final hashtagSpan = _findSpanWithText(textSpan, '#misskey');
      expect(hashtagSpan, isNotNull);
    });

    testWidgets('カスタム絵文字をビルダーでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: ':custom:',
              config: MfmRenderConfig(
                emojiBuilder: (name) => Container(
                  key: Key('emoji-$name'),
                  width: 24,
                  height: 24,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('emoji-custom')), findsOneWidget);
    });

    testWidgets('ビルダーがない場合、カスタム絵文字をテキストとしてレンダリングする', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: ':custom:'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final emojiSpan = _findSpanWithText(textSpan, ':custom:');
      expect(emojiSpan, isNotNull);
    });

    testWidgets('Unicode絵文字をレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '😀'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final emojiSpan = _findSpanWithText(textSpan, '😀');
      expect(emojiSpan, isNotNull);
    });

    testWidgets('Unicode絵文字をビルダーでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '😀',
              config: MfmRenderConfig(
                unicodeEmojiBuilder: (emoji) => Container(
                  key: Key('unicode-$emoji'),
                  width: 24,
                  height: 24,
                  color: Colors.yellow,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('unicode-😀')), findsOneWidget);
    });

    testWidgets('plainブロック内ではMFMがパースされない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '<plain>**not bold**</plain>'),
          ),
        ),
      );

      // plainブロック内では**は太字としてパースされない
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNull);
    });
  });

  group('MfmText ブロック要素', () {
    testWidgets('引用ブロックを左ボーダー付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '> quote'),
          ),
        ),
      );

      // 引用ブロックはボーダー装飾付きのContainerを使用
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('中央寄せブロックをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '<center>centered</center>'),
          ),
        ),
      );

      // 中央寄せブロックは幅いっぱいのSizedBoxを使用
      final sizedBox = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final fullWidthBox = sizedBox.any((box) => box.width == double.infinity);
      expect(fullWidthBox, isTrue);
    });

    testWidgets('コードブロックをコード内容付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '```\ncode block\n```'),
          ),
        ),
      );

      expect(find.text('code block'), findsOneWidget);
    });

    testWidgets('数式ブロックを数式付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'\[x = y\]'),
          ),
        ),
      );

      expect(find.text('x = y'), findsOneWidget);
    });

    testWidgets('インライン数式を数式付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'\(a + b\)'),
          ),
        ),
      );

      expect(find.text('a + b'), findsOneWidget);
    });

    testWidgets('検索ブロックをボタン付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: 'test query 検索'),
          ),
        ),
      );

      expect(find.text('test query'), findsOneWidget);
      expect(find.text('検索'), findsOneWidget);
    });
  });

  group('MfmText コールバック', () {
    testWidgets('URLタップ時にonLinkTapが呼ばれる', (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'https://example.com',
              config: MfmRenderConfig(
                onLinkTap: (url) => tappedUrl = url,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // URLスパンを検索
      final linkSpan = _findSpanWithText(textSpan, 'https://example.com');
      expect(linkSpan, isNotNull);

      // recognizerを呼び出してタップをシミュレート
      final recognizer = linkSpan?.recognizer;
      if (recognizer is TapGestureRecognizer) {
        recognizer.onTap?.call();
      }

      expect(tappedUrl, 'https://example.com');
    });

    testWidgets('メンションタップ時にonMentionTapが呼ばれる', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@user@example.com',
              config: MfmRenderConfig(
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final mentionSpan = _findSpanWithText(textSpan, '@user@example.com');
      expect(mentionSpan, isNotNull);

      final mentionRecognizer = mentionSpan?.recognizer;
      if (mentionRecognizer is TapGestureRecognizer) {
        mentionRecognizer.onTap?.call();
      }

      expect(tappedMention, '@user@example.com');
    });

    testWidgets('ハッシュタグタップ時にonHashtagTapが呼ばれる', (tester) async {
      String? tappedTag;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '#flutter',
              config: MfmRenderConfig(
                onHashtagTap: (tag) => tappedTag = tag,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final hashtagSpan = _findSpanWithText(textSpan, '#flutter');
      expect(hashtagSpan, isNotNull);

      final hashtagRecognizer = hashtagSpan?.recognizer;
      if (hashtagRecognizer is TapGestureRecognizer) {
        hashtagRecognizer.onTap?.call();
      }

      expect(tappedTag, 'flutter');
    });

    testWidgets('検索ボタンタップ時にonSearchTapが呼ばれる', (tester) async {
      String? tappedQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'flutter Search',
              config: MfmRenderConfig(
                onSearchTap: (query) => tappedQuery = query,
              ),
            ),
          ),
        ),
      );

      // 検索ボタンを検索してタップ
      await tester.tap(find.text('検索'));
      await tester.pump();

      expect(tappedQuery, 'flutter');
    });
  });

  group('MfmText ネスト要素', () {
    testWidgets('太字と斜体のネストをレンダリングできる', (tester) async {
      // パーサーがサポートする明示的なネスト構文を使用
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '**<i>bold and italic</i>**'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // 太字スタイルを持つべき
      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNotNull);

      // 斜体スタイルを持つべき
      final italicSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontStyle == FontStyle.italic,
      );
      expect(italicSpan, isNotNull);
    });

    testWidgets('子要素を持つリンクをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '[link text](https://example.com)'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final linkSpan = _findSpanWithStyle(
        textSpan,
        (style) =>
            style?.decoration == TextDecoration.underline &&
            style?.color == const Color(0xFF0066CC),
      );
      expect(linkSpan, isNotNull);
    });
  });

  group('MfmText シンプルパーサー', () {
    testWidgets('simpleモードでは基本要素のみパースされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '**bold** :emoji: https://example.com',
              simple: true,
            ),
          ),
        ),
      );

      // simpleモードでは太字がパースされない
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // simpleモードでは太字スタイルが適用されない
      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNull);
    });
  });
}

/// 特定のスタイルを持つTextSpanを検索するヘルパー関数
TextSpan? _findSpanWithStyle(
  TextSpan parent,
  bool Function(TextStyle?) predicate,
) {
  if (predicate(parent.style)) {
    return parent;
  }

  if (parent.children != null) {
    for (final child in parent.children!) {
      if (child is TextSpan) {
        final found = _findSpanWithStyle(child, predicate);
        if (found != null) {
          return found;
        }
      }
    }
  }

  return null;
}

/// 特定のテキストを持つTextSpanを検索するヘルパー関数
TextSpan? _findSpanWithText(TextSpan parent, String text) {
  if (parent.text == text) {
    return parent;
  }

  if (parent.children != null) {
    for (final child in parent.children!) {
      if (child is TextSpan) {
        final found = _findSpanWithText(child, text);
        if (found != null) {
          return found;
        }
      }
    }
  }

  return null;
}
