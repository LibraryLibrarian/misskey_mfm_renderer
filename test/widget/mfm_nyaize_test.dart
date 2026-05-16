import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('MfmText / nyaize 適用', () {
    testWidgets('enableNyaize=false の場合は変換しない（デフォルト）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: 'なにぬねの'),
          ),
        ),
      );

      expect(_findSpanWithText(_rootSpan(tester), 'なにぬねの'), isNotNull);
      expect(_findSpanWithText(_rootSpan(tester), 'にゃにぬねの'), isNull);
    });

    testWidgets('enableNyaize=true の場合はテキストノードが変換される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'なにぬねの',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      expect(_findSpanWithText(_rootSpan(tester), 'にゃにぬねの'), isNotNull);
    });

    testWidgets('inlineCode の中身は変換されない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'なにぬ`なにぬ`なにぬ',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      // インラインコードの内側はWidgetSpan経由でTextウィジェットとして描画されるため、
      // 元のテキストがそのまま画面上に存在することを確認する
      expect(find.text('なにぬ'), findsOneWidget);
    });

    testWidgets('plain タグの中身は変換されない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '<plain>なにぬねの</plain>',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      // plain サブツリーは原文のまま、外側のテキストノードのみ変換される
      expect(_findSpanWithText(_rootSpan(tester), 'なにぬねの'), isNotNull);
    });

    testWidgets('quote の中身は変換されない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '> なにぬねの',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      // quote 配下は原文のまま保持されることを確認
      // QuoteNode は WidgetSpan として描画されるため、ウィジェットツリーから探す
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasOriginal = richTexts.any(
        (rt) => _findSpanWithText(rt.text as TextSpan, 'なにぬねの') != null,
      );
      expect(hasOriginal, isTrue);
    });

    testWidgets('リンクのラベルは変換されない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '[なにぬ](https://example.com)',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      expect(_findSpanWithText(_rootSpan(tester), 'なにぬ'), isNotNull);
      expect(_findSpanWithText(_rootSpan(tester), 'にゃにぬ'), isNull);
    });
  });
}

TextSpan _rootSpan(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.byType(RichText).first);
  return richText.text as TextSpan;
}

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
