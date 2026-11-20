import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_code_block.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_search.dart';

const _baseStyle = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 14,
  height: 1,
  color: Color(0xFF123456),
);

void main() {
  group('MfmText.nowrap', () {
    testWidgets('明示的な改行を保持し自動折り返しだけを止める', (tester) async {
      await tester.pumpWidget(
        _host(const MfmText(text: 'a\nb\nc', nowrap: true)),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      expect(richText.maxLines, isNull);
      expect(richText.softWrap, isFalse);
      expect(richText.overflow, TextOverflow.clip);
      expect(paragraph.size.height, 42);
      expect(
        paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 2, extentOffset: 3),
        ),
        isNotEmpty,
      );
    });

    for (final sample in [
      (
        name: 'center',
        source: '<center>b</center>',
        node: const CenterNode([TextNode('b')]),
        placeholder: '\uFFFC',
        label: 'b',
      ),
      (
        name: 'quote',
        source: '> q',
        node: const QuoteNode([TextNode('q')]),
        placeholder: '\uFFFC',
        label: 'q',
      ),
      (
        name: 'code block',
        source: '```\ncode\n```',
        node: const CodeBlockNode(code: 'code'),
        placeholder: '\uFFFC',
        label: 'code',
      ),
      (
        name: 'search',
        source: 'query Search',
        node: const SearchNode(query: 'query', content: 'query Search'),
        placeholder: '\uFFFC',
        label: 'query',
      ),
    ]) {
      testWidgets('${sample.name} stays between visible separate lines', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(MfmText(text: 'a\n${sample.source}\nc', nowrap: true)),
        );
        _expectBlockLines(tester, sample.placeholder);
        if (sample.name == 'search') {
          expect(find.byType(MfmSearch), findsOneWidget);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            sample.label,
          );
          final block = tester.getRect(find.byType(MfmSearch));
          final root = tester.getRect(find.byType(RichText).first);
          expect(root.intersect(block), block);
        } else if (sample.placeholder == '\uFFFC') {
          final glyph = _richTextWith(sample.label);
          expect(glyph, findsOneWidget);
          expect(_glyphRect(tester, glyph, 0).isEmpty, isFalse);
          final root = tester.getRect(find.byType(RichText).first);
          expect(root.contains(_glyphRect(tester, glyph, 0).center), isTrue);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('${sample.name} keeps existing boundary line breaks', (
        tester,
      ) async {
        for (final newline in ['\n', '\r\n', '\r', '\u2028', '\u2029']) {
          await tester.pumpWidget(
            _host(
              MfmText(
                parsedNodes: [
                  BoldNode([TextNode('a$newline')]),
                  sample.node,
                  BoldNode([TextNode('${newline}c')]),
                ],
                nowrap: true,
              ),
            ),
          );
          final normalized = newline.startsWith('\r') ? '\n' : newline;
          _expectBlockLines(tester, sample.placeholder, newline: normalized);
        }
      });

      testWidgets('${sample.name} adds no boundary breaks with nowrap false', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(MfmText(text: 'a\n${sample.source}\nc')),
        );
        final rich = tester.widget<RichText>(find.byType(RichText).first);
        expect(rich.text.toPlainText(), 'a${sample.placeholder}c');
        expect(rich.softWrap, isTrue);
        expect(rich.overflow, TextOverflow.clip);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${sample.name} adds no leading or trailing blank line', (
        tester,
      ) async {
        for (final nodes in [
          [sample.node],
          [sample.node, const TextNode('c')],
          [const TextNode('a'), sample.node],
          [sample.node, sample.node],
        ]) {
          await tester.pumpWidget(
            _host(MfmText(parsedNodes: nodes, nowrap: true)),
          );
          final text = tester
              .widget<RichText>(find.byType(RichText).first)
              .text
              .toPlainText();
          expect(text.startsWith('\n'), isFalse);
          expect(text.endsWith('\n'), isFalse);
          expect(text, isNot(contains('\n\n')));
          expect('\n'.allMatches(text), hasLength(nodes.length - 1));
        }
      });
    }

    for (final nowrap in [true, false]) {
      testWidgets('math block keeps all glyphs inline with nowrap=$nowrap', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(MfmText(text: 'a\n\\[b\\]\nc', nowrap: nowrap)),
        );
        final finder = find.byType(RichText);
        final rich = tester.widget<RichText>(finder);
        expect(rich.text.toPlainText(), 'abc');
        expect(rich.softWrap, !nowrap);
        expect(
          rich.overflow,
          nowrap ? TextOverflow.ellipsis : TextOverflow.clip,
        );
        final bounds = tester.getRect(finder);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        final first = _glyphRect(tester, finder, 0);
        var previousRight = first.left;
        for (final offset in [0, 1, 2]) {
          final glyph = _glyphRect(tester, finder, offset);
          // The code font may have different ascent/descent from body text.
          expect(glyph.top, lessThan(first.bottom));
          expect(glyph.bottom, greaterThan(first.top));
          expect(glyph.left, greaterThanOrEqualTo(previousRight));
          previousRight = glyph.right;
          expect(bounds.contains(glyph.center), isTrue);
        }
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('math block preserves explicit sibling line breaks', (
      tester,
    ) async {
      for (final newline in ['\n', '\r\n', '\r', '\u2028', '\u2029']) {
        await tester.pumpWidget(
          _host(
            MfmText(
              parsedNodes: [
                TextNode('a$newline'),
                const MathBlockNode('b'),
                TextNode('${newline}c'),
              ],
              nowrap: true,
            ),
          ),
        );
        final normalized = newline.startsWith('\r') ? '\n' : newline;
        _expectBlockLines(tester, 'b', newline: normalized);
      }
    });

    testWidgets('nested bold separates its center from its sibling glyphs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            parsedNodes: [
              BoldNode([
                TextNode('a'),
                CenterNode([TextNode('b')]),
                TextNode('c'),
              ]),
            ],
            nowrap: true,
          ),
        ),
      );
      _expectBlockLines(tester, '\uFFFC');
      expect(tester.takeException(), isNull);
    });

    testWidgets('parsed quote separates blocks inside its child paragraph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MfmText(
            text: '> a\n> <center>b</center>\n> c',
            nowrap: true,
          ),
        ),
      );
      _expectBlockLines(tester, '\uFFFC', root: _richTextWith('a\n\uFFFC\nc'));
      expect(tester.takeException(), isNull);
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
      final quoteSize = tester.getSize(quote);
      expect(quoteSize.width, closeTo(101, 0.01));
      expect(quoteSize.height, 42);
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

        // URLの外部リンクiconもRichTextを持つため、ルートだけを見る。
        final root = find.byType(RichText).first;
        final richText = tester.widget<RichText>(root);
        expect(richText.softWrap, isFalse);
        expect(richText.maxLines, isNull);
        expect(richText.overflow, TextOverflow.ellipsis);
        expect(tester.getSize(root).height, 14);
        expect(
          tester.renderObject<RenderParagraph>(root).didExceedMaxLines,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
    });

    for (final separator in ['\n', '\u2028', '\u2029']) {
      testWidgets(
        '長い行でも強制改行U+${separator.codeUnitAt(0).toRadixString(16)}を保持する',
        (
          tester,
        ) async {
          const long = 'abcdefghijklmnopqrst';
          final source = '$long${separator}short$separator$long';
          await tester.pumpWidget(
            _host(MfmText(text: source, nowrap: true), width: 100),
          );
          final finder = find.byType(RichText);
          final rich = tester.widget<RichText>(finder);
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(rich.maxLines, isNull);
          expect(rich.softWrap, isFalse);
          expect(rich.overflow, TextOverflow.clip);
          expect(paragraph.size.height, 42);
          final rowTops = <double>[];
          for (final offset in [
            0,
            source.indexOf('short'),
            source.lastIndexOf(long),
          ]) {
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: offset, extentOffset: offset + 1),
            );
            expect(boxes, isNotEmpty);
            rowTops.add(boxes.single.top);
          }
          expect(rowTops.toSet(), hasLength(3));
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final sample in [
      (name: 'quote', source: '> abcdefghijklmnopqrst', size: 14.0),
      (
        name: 'center',
        source: '<center>abcdefghijklmnopqrst</center>',
        size: 14.0,
      ),
      (name: 'flip', source: r'$[flip abcdefghijklmnopqrst]', size: 14.0),
      (
        name: 'x2 in quote',
        source: r'> $[x2 abcdefghijklmnopqrst]',
        size: 28.0,
      ),
      (name: 'inline code', source: '`abcdefghijklmnopqrst`', size: 14.0),
      (
        name: 'rainbow quote',
        source: r'> $[rainbow abcdefghijklmnopqrst]',
        size: 14.0,
      ),
      (
        name: 'rainbow center',
        source: r'<center>$[rainbow abcdefghijklmnopqrst]</center>',
        size: 14.0,
      ),
      (
        name: 'rainbow flip',
        source: r'$[rainbow $[flip abcdefghijklmnopqrst]]',
        size: 14.0,
      ),
      (
        name: 'rainbow x2 in quote',
        source: r'> $[rainbow $[x2 abcdefghijklmnopqrst]]',
        size: 28.0,
      ),
      (
        name: 'rainbow inline code',
        source: r'$[rainbow `abcdefghijklmnopqrst`]',
        size: 14.0,
      ),
    ]) {
      for (final nowrap in [true, false]) {
        testWidgets(
          '${sample.name} nowrap=$nowrap controls automatic wrapping',
          (
            tester,
          ) async {
            await tester.pumpWidget(
              _host(
                MfmText(
                  text: sample.source,
                  nowrap: nowrap,
                  config: const MfmRenderConfig(enableAnimation: false),
                ),
                width: 100,
              ),
            );
            final finder = find
                .byWidgetPredicate(
                  (widget) =>
                      widget is RichText &&
                      widget.text.toPlainText() == 'abcdefghijklmnopqrst',
                )
                .last;
            final rich = tester.widget<RichText>(finder);
            final paragraph = tester.renderObject<RenderParagraph>(finder);
            expect(rich.maxLines, isNull);
            expect(rich.softWrap, !nowrap);
            expect(rich.overflow, TextOverflow.clip);
            expect(
              paragraph.size.height,
              nowrap ? closeTo(sample.size, .01) : greaterThan(sample.size),
            );
            if (sample.name.startsWith('rainbow')) {
              expect(rich, isA<MfmRainbowRichText>());
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('内側の明示改行をquoteとcenterとflipで保持する', (tester) async {
      const children = [TextNode('a\nb\nc')];
      for (final node in const <MfmNode>[
        QuoteNode(children),
        CenterNode(children),
        FnNode(name: 'flip', args: {}, children: children),
        FnNode(
          name: 'rainbow',
          args: {},
          children: [CenterNode(children)],
        ),
      ]) {
        await tester.pumpWidget(
          _host(
            MfmText(
              parsedNodes: [node],
              nowrap: true,
              config: const MfmRenderConfig(enableAnimation: false),
            ),
          ),
        );
        final finder = find
            .byWidgetPredicate(
              (widget) =>
                  widget is RichText && widget.text.toPlainText() == 'a\nb\nc',
            )
            .last;
        final rich = tester.widget<RichText>(finder);
        expect(rich.maxLines, isNull);
        expect(rich.softWrap, isFalse);
        expect(rich.overflow, TextOverflow.clip);
        expect(tester.getSize(finder).height, 42);
      }
    });

    testWidgets('nowrap falseは折り返しと明示改行を通常どおり表示する', (tester) async {
      for (final source in ['abcdefghijklmnopqrst', 'a\nb\nc']) {
        await tester.pumpWidget(
          _host(MfmText(text: source), width: 100),
        );
        final finder = find.byType(RichText);
        final rich = tester.widget<RichText>(finder);
        expect(rich.maxLines, isNull);
        expect(rich.softWrap, isTrue);
        expect(rich.overflow, TextOverflow.clip);
        expect(tester.getSize(finder).height, 42);
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

Finder _richTextWith(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == text,
);

Rect _glyphRect(WidgetTester tester, Finder finder, int offset) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: offset, extentOffset: offset + 1),
  );
  expect(boxes, hasLength(1));
  return boxes.single.toRect().shift(paragraph.localToGlobal(Offset.zero));
}

void _expectBlockLines(
  WidgetTester tester,
  String blockText, {
  String newline = '\n',
  Finder? root,
}) {
  final finder = root ?? find.byType(RichText).first;
  final rich = tester.widget<RichText>(finder);
  final text = 'a$newline$blockText${newline}c';
  expect(rich.text.toPlainText(), text);
  expect(rich.softWrap, isFalse);
  expect(rich.overflow, TextOverflow.clip);
  final first = _glyphRect(tester, finder, 0);
  final block = _glyphRect(tester, finder, 1 + newline.length);
  final last = _glyphRect(tester, finder, text.length - 1);
  expect(first.bottom, lessThanOrEqualTo(block.top));
  expect(block.bottom, lessThanOrEqualTo(last.top));
  final bounds = tester.getRect(finder);
  for (final rect in [first, block, last]) {
    expect(bounds.contains(rect.center), isTrue);
  }
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse);
  // All three glyph/placeholder rows are present, with no extra blank row.
  expect(
    bounds.height,
    closeTo(first.height + block.height + last.height, .01),
  );
}
