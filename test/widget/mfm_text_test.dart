import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_code_block.dart';

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

    testWidgets('emojiBuilderに絵文字名が渡される', (tester) async {
      var builderCalled = false;
      String? receivedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'Hello :custom: World',
              config: MfmRenderConfig(
                emojiBuilder: (name) {
                  builderCalled = true;
                  receivedName = name;
                  return Container(
                    key: Key('emoji-$name'),
                    width: 24,
                    height: 24,
                    color: Colors.green,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(builderCalled, isTrue);
      expect(receivedName, equals('custom'));
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

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.code, 'code block');
    });

    testWidgets('コードブロックが言語指定付きでシンタックスハイライトされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '```dart\nvoid main() {}\n```'),
          ),
        ),
      );

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.code, 'void main() {}');
      expect(codeBlock.language, 'dart');
    });

    testWidgets('言語指定なしのコードブロックがプレーンテキストで表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '```\nplain text code\n```'),
          ),
        ),
      );

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.code, 'plain text code');
      expect(codeBlock.language, isNull);
    });

    testWidgets('カスタムコードテーマが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '```dart\nvar x = 1;\n```',
              config: MfmRenderConfig(
                codeTheme: draculaTheme,
              ),
            ),
          ),
        ),
      );

      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.theme, draculaTheme);
    });

    testWidgets('コピーボタンの表示/非表示が制御できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '```dart\ncode\n```',
              config: MfmRenderConfig(
                showCodeBlockCopyButton: false,
              ),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MfmCodeBlock),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
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
      expect(find.text('Search'), findsOneWidget);
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

    testWidgets('リモート投稿者のホストで省略メンションを解決する', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                author: const MfmAuthorContext(host: 'remote.example'),
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@remote.example');
    });

    testWidgets('ローカル投稿者ではlocalHostで省略メンションを解決する', (
      tester,
    ) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                author: const MfmAuthorContext(),
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@local.example');
    });

    testWidgets('投稿者情報がなくてもlocalHostで省略メンションを解決する', (
      tester,
    ) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@local.example');
    });

    testWidgets('明示されたメンションホストを投稿者ホストより優先する', (
      tester,
    ) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice@explicit.example',
              config: MfmRenderConfig(
                author: const MfmAuthorContext(host: 'remote.example'),
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice@explicit.example');
      expect(tappedMention, '@alice@explicit.example');
    });

    testWidgets('Inherited configの投稿者ホストを明示コールバックと結合する', (
      tester,
    ) async {
      String? tappedMention;

      await tester.pumpWidget(
        MfmConfig(
          config: const MfmRenderConfig(
            author: MfmAuthorContext(host: 'remote.example'),
            localHost: 'local.example',
          ),
          child: MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '@alice',
                config: MfmRenderConfig(
                  onMentionTap: (acct) => tappedMention = acct,
                ),
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@remote.example');
    });

    testWidgets('解決コンテキストがなければ省略メンションをそのまま渡す', (
      tester,
    ) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice');
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

    testWidgets('英語ロケールで検索ボタンにSearchを表示する', (tester) async {
      String? tappedQuery;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
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

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(tappedQuery, 'flutter');
    });

    testWidgets('日本語ロケールで検索ボタンに検索を表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: const MfmText(text: 'flutter Search'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('検索'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('検索ボタンの明示ラベルがロケールより優先される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: const MfmText(
                  text: 'flutter Search',
                  config: MfmRenderConfig(searchButtonLabel: 'Find'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Find'), findsOneWidget);
      expect(find.text('検索'), findsNothing);
    });

    testWidgets('ローカライズ取得不可時はSearchを表示する', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: TextStyle(),
              child: MfmText(text: 'flutter Search'),
            ),
          ),
        ),
      );

      expect(find.text('Search'), findsOneWidget);
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

void _invokeSpanTap(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(find.byType(RichText));
  final textSpan = richText.text as TextSpan;
  final targetSpan = _findSpanWithText(textSpan, text);
  expect(targetSpan, isNotNull);
  final recognizer = targetSpan?.recognizer;
  expect(recognizer, isA<TapGestureRecognizer>());
  (recognizer! as TapGestureRecognizer).onTap?.call();
}
