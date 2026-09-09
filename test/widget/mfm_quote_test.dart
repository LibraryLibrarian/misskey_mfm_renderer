import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _baseStyle = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 14,
  height: 1,
  color: Color(0xFF123456),
);

void main() {
  group('MfmText 引用のブロック配置', () {
    testWidgets('前後のテキストと分離し3行と上下余白で高さ70pxになる', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            text: 'before\n> quote\nafter',
            config: MfmRenderConfig(baseTextStyle: _baseStyle),
          ),
        ),
      );

      final paragraph = _rootParagraph(tester);
      expect(paragraph.size, const Size(300, 70));
      expect(_textTop(paragraph, 'before'), 0);
      expect(_textTop(paragraph, 'after'), 56);
      expect(_quotes(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('連続する引用行を1つの引用内の2行として表示する', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            text: '> a\n> b',
            config: MfmRenderConfig(baseTextStyle: _baseStyle),
          ),
        ),
      );

      expect(_quotes(), findsOneWidget);
      final inner = tester.renderObject<RenderParagraph>(
        find.descendant(of: _quotes(), matching: find.byType(RichText)),
      );
      expect(inner.text.toPlainText(), 'a\nb');
      expect(inner.size.height, 28);
      expect(_textTop(inner, 'b') - _textTop(inner, 'a'), 14);
      expect(_rootParagraph(tester).size.height, 56);
    });

    testWidgets('引用直後のテキストを次の行に表示する', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            text: '> a\nafter',
            config: MfmRenderConfig(baseTextStyle: _baseStyle),
          ),
        ),
      );

      final paragraph = _rootParagraph(tester);
      expect(paragraph.size.height, 56);
      expect(_textTop(paragraph, 'after'), 42);
    });

    for (final beforeNewline in [false, true]) {
      for (final afterNewline in [false, true]) {
        testWidgets(
          'parsedNodesの境界改行で空行を増やさない'
          '(前$beforeNewline・後$afterNewline)',
          (tester) async {
            await tester.pumpWidget(
              _host(
                MfmText(
                  parsedNodes: [
                    TextNode(beforeNewline ? 'before\n' : 'before'),
                    const QuoteNode([TextNode('quote')]),
                    TextNode(afterNewline ? '\nafter' : 'after'),
                  ],
                  config: const MfmRenderConfig(baseTextStyle: _baseStyle),
                ),
              ),
            );

            final paragraph = _rootParagraph(tester);
            expect(paragraph.size, const Size(300, 70));
            expect(_textTop(paragraph, 'before'), 0);
            expect(_textTop(paragraph, 'after'), 56);
          },
        );
      }
    }

    testWidgets('有限幅では余白を含めて全幅を使い本家の余白と罫線幅になる', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            text: '> quote',
            config: MfmRenderConfig(baseTextStyle: _baseStyle),
          ),
        ),
      );

      final container = tester.widget<Container>(_quotes());
      expect(tester.getSize(_quotes()), const Size(300, 42));
      expect(container.margin, const EdgeInsets.all(8));
      expect(container.padding, const EdgeInsets.fromLTRB(12, 6, 0, 6));
      expect(_leftBorder(container).width, 3);
      final inner = tester.renderObject<RenderParagraph>(
        find.descendant(of: _quotes(), matching: find.byType(RichText)),
      );
      final quoteOrigin = tester.getTopLeft(_quotes());
      expect(
        inner.localToGlobal(Offset.zero) - quoteOrigin,
        const Offset(23, 14),
      );
      expect(inner.constraints.maxWidth, 269);
    });

    testWidgets('Row内の非Expandedでは例外なく自然幅になる', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MfmText(
                text: '> quote',
                config: MfmRenderConfig(baseTextStyle: _baseStyle),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // 文字5個×14pxに左右margin 16px・左padding 12px・罫線3pxを加える。
      expect(tester.getSize(_quotes()), const Size(101, 42));
      expect(_rootParagraph(tester).size, const Size(101, 42));
    });
  });

  group('MfmText 引用の文字色と罫線色', () {
    for (final colorCase in [
      (name: '明示色', color: const Color(0xFF123456)),
      (name: '明るい色', color: const Color(0xFFC7D1D8)),
      (name: '半透明色', color: const Color(0x80123456)),
      (name: '色未指定', color: null),
    ]) {
      for (final small in [false, true]) {
        testWidgets('${colorCase.name}は未減光の色に累積opacityを1回適用する(small $small)', (
          tester,
        ) async {
          const quote = QuoteNode([TextNode('quote')]);
          await tester.pumpWidget(
            _host(
              MfmText(
                parsedNodes: [
                  if (small) const SmallNode([quote]) else quote,
                ],
                config: MfmRenderConfig(
                  baseTextStyle: TextStyle(
                    fontFamily: 'Ahem',
                    fontSize: 14,
                    height: 1,
                    color: colorCase.color,
                  ),
                ),
              ),
            ),
          );

          final container = tester.widget<Container>(_quotes());
          final color = _leftBorder(container).color;
          final baseColor = colorCase.color ?? const Color(0xFFFFFFFF);
          expect(color.withValues(alpha: 1), baseColor.withValues(alpha: 1));
          expect(
            color.a,
            closeTo(baseColor.a * (small ? 0.49 : 0.7), 0.000001),
          );
          final richText = tester.widget<RichText>(
            find.descendant(of: _quotes(), matching: find.byType(RichText)),
          );
          expect(richText.text.style!.color, color);
          expect(find.byType(Opacity), findsNothing);
        });
      }
    }

    testWidgets('ネストした引用もルート色から減光して兄弟には漏らさない', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            parsedNodes: [
              QuoteNode([
                QuoteNode([TextNode('nested')]),
                TextNode('outer'),
              ]),
              TextNode('sibling'),
            ],
            config: MfmRenderConfig(baseTextStyle: _baseStyle),
          ),
        ),
      );

      expect(_quotes(), findsNWidgets(2));
      final containers = tester.widgetList<Container>(_quotes()).toList();
      for (var i = 0; i < containers.length; i++) {
        final color = _leftBorder(containers[i]).color;
        expect(color.withValues(alpha: 1), _baseStyle.color);
        expect(color.a, closeTo(i == 0 ? 0.7 : 0.49, 0.000001));
        final richText = tester.widget<RichText>(
          find
              .descendant(
                of: find.byWidget(containers[i]),
                matching: find.byType(RichText),
              )
              .first,
        );
        expect(richText.text.style!.color, color);
      }
      expect(_rootParagraph(tester).text.style!.color, _baseStyle.color);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('fg内の引用は実効色ではなくルートの未減光色に戻す', (tester) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            parsedNodes: [
              SmallNode([
                FnNode(
                  name: 'fg',
                  args: {'color': 'ff0000'},
                  children: [
                    QuoteNode([TextNode('quote')]),
                  ],
                ),
              ]),
            ],
            config: MfmRenderConfig(baseTextStyle: _baseStyle),
          ),
        ),
      );

      final color = _leftBorder(tester.widget<Container>(_quotes())).color;
      expect(color.withValues(alpha: 1), _baseStyle.color);
      expect(color.a, closeTo(0.49, 0.000001));
      final richText = tester.widget<RichText>(
        find.descendant(of: _quotes(), matching: find.byType(RichText)),
      );
      expect(richText.text.style!.color, color);
    });

    testWidgets('baseTextStyle未指定ではDefaultTextStyleの色を使う', (tester) async {
      await tester.pumpWidget(_host(const MfmText(text: '> quote')));

      final color = _leftBorder(tester.widget<Container>(_quotes())).color;
      expect(color, _baseStyle.color!.withValues(alpha: 0.7));
      final richText = tester.widget<RichText>(
        find.descendant(of: _quotes(), matching: find.byType(RichText)),
      );
      expect(richText.text.style!.color, color);
    });
  });
}

Widget _host(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: DefaultTextStyle(
        style: _baseStyle,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: child),
        ),
      ),
    ),
  );
}

Finder _quotes() {
  return find.descendant(
    of: find.byType(MfmText),
    matching: find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.border is Border;
    }),
  );
}

BorderSide _leftBorder(Container container) {
  return ((container.decoration! as BoxDecoration).border! as Border).left;
}

RenderParagraph _rootParagraph(WidgetTester tester) {
  return tester.renderObject<RenderParagraph>(
    find
        .descendant(
          of: find.byType(MfmText),
          matching: find.byType(RichText),
        )
        .first,
  );
}

double _textTop(RenderParagraph paragraph, String text) {
  final start = paragraph.text.toPlainText().indexOf(text);
  expect(start, greaterThanOrEqualTo(0));
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + text.length),
      )
      .single
      .top;
}
