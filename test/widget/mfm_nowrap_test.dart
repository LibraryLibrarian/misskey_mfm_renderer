import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_code_block.dart';

const _baseStyle = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 14,
  height: 1,
  color: Color(0xFF123456),
);

void main() {
  group('MfmText.nowrap', () {
    testWidgets('改行を1行に省略しRichTextの省略設定を使う', (tester) async {
      await tester.pumpWidget(
        _host(const MfmText(text: 'a\nb\nc', nowrap: true)),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      expect(richText.maxLines, 1);
      expect(richText.softWrap, isFalse);
      expect(richText.overflow, TextOverflow.ellipsis);
      expect(paragraph.size.height, 14);
      expect(
        paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 2, extentOffset: 3),
        ),
        isEmpty,
      );
    });

    testWidgets('引用を全幅化せず1行内の自然幅で表示する', (tester) async {
      await tester.pumpWidget(
        _host(const MfmText(text: '> quote', nowrap: true)),
      );

      final quote = _quoteFinder();
      expect(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(LayoutBuilder),
        ),
        findsNothing,
      );
      expect(tester.getSize(quote), const Size(101, 42));
      expect(tester.getSize(find.byType(RichText).first).height, 42);
      expect(tester.takeException(), isNull);
    });

    testWidgets('長いURLとテキストを折り返さない', (tester) async {
      for (final text in [
        'https://example.com/a-very-long-path-that-must-not-wrap',
        'a-very-long-unbroken-text-that-must-not-wrap',
      ]) {
        await tester.pumpWidget(
          _host(MfmText(text: text, nowrap: true), width: 100),
        );

        final richText = tester.widget<RichText>(find.byType(RichText));
        expect(richText.softWrap, isFalse);
        expect(tester.getSize(find.byType(RichText)).height, 14);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('有限幅では他のWidgetSpanブロックでも例外にならない', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            text: '<center>center</center>\n```\ncode\n```\n\\[x^2\\]',
            nowrap: true,
          ),
        ),
      );

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('幅無制約でも引用と長文を例外なく描画する', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: _baseStyle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MfmText(
                  text: '> quote with a very long line that is ellipsized',
                  nowrap: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Widget _host(Widget child, {double width = 300}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: DefaultTextStyle(
        style: _baseStyle,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

Finder _quoteFinder() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final decoration = widget.decoration;
    return decoration is BoxDecoration && decoration.border is Border;
  });
}
