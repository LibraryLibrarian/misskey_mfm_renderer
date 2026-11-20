import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/builder/mfm_node_builder.dart';
import 'package:misskey_mfm_renderer/src/utils/parse_text.dart';

const _style = TextStyle(fontFamily: 'Ahem', fontSize: 14, height: 1);

Widget _host(MfmText child, {TextStyle style = _style}) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(
    style: style,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 750, child: child),
    ),
  ),
);

MfmNode _nest(
  int depth,
  MfmNode node, {
  MfmNode Function(List<MfmNode>) wrap = BoldNode.new,
}) {
  var nested = node;
  for (var i = 0; i < depth; i++) {
    nested = wrap([nested]);
  }
  return nested;
}

Finder get _paragraphs => find.descendant(
  of: find.byType(MfmText),
  matching: find.byWidgetPredicate((widget) => widget is RichText),
);

TextSpan _rootSpan(WidgetTester tester) =>
    tester.widget<RichText>(_paragraphs.first).text as TextSpan;

List<TextSpan> _textSpans(InlineSpan root) {
  final result = <TextSpan>[];
  final stack = [root];
  while (stack.isNotEmpty) {
    final span = stack.removeLast();
    if (span is! TextSpan) continue;
    result.add(span);
    stack.addAll((span.children ?? []).reversed);
  }
  return result;
}

MfmNode _mixed(int depth) {
  MfmNode node = const TextNode('leaf');
  for (var i = 0; i < depth; i++) {
    final children = [node];
    node = switch (i % 12) {
      0 => FnNode(name: 'x2', args: const {}, children: children),
      1 => FnNode(name: 'spin', args: const {}, children: children),
      2 => FnNode(name: 'flip', args: const {}, children: children),
      3 => QuoteNode(children),
      4 => LinkNode(silent: false, url: '/link', children: children),
      5 => SmallNode(children),
      6 => CenterNode(children),
      7 => BoldNode(children),
      8 => ItalicNode(children),
      9 => StrikeNode(children),
      10 => PlainNode(children),
      _ => FnNode(name: 'ruby', args: const {}, children: children),
    };
  }
  return node;
}

const _allNodes = <MfmNode>[
  TextNode('な\r\nx\ry\nz|'),
  EmojiCodeNode('custom'),
  UnicodeEmojiNode('🍮'),
  UrlNode(url: 'https://example.test/raw'),
  MentionNode(username: 'alice', acct: '@alice'),
  HashtagNode('tag'),
  InlineCodeNode('な-inline'),
  CodeBlockNode(code: 'な-block'),
  MathInlineNode('inline-formula'),
  MathBlockNode('block-formula'),
  SearchNode(query: 'query', content: 'query [Search]'),
  BoldNode([TextNode('B')]),
  ItalicNode([TextNode('I')]),
  StrikeNode([TextNode('S')]),
  SmallNode([TextNode('s')]),
  QuoteNode([TextNode('Q')]),
  CenterNode([TextNode('C')]),
  LinkNode(silent: false, url: 'ignored', children: [TextNode('L')]),
  PlainNode([TextNode('P')]),
  FnNode(name: 'unknown', args: {}, children: [TextNode('F')]),
];

void main() {
  for (final depth in [100, 101]) {
    testWidgets('depth $depth applies styles only within the 100-level limit', (
      tester,
    ) async {
      final node = _nest(
        depth - 1,
        const BoldNode([TextNode('leaf')]),
        wrap: PlainNode.new,
      );
      await tester.pumpWidget(_host(MfmText(parsedNodes: [node])));
      final spans = _textSpans(_rootSpan(tester));
      expect(_rootSpan(tester).toPlainText(), 'leaf');
      expect(
        spans.where((span) => span.style?.fontWeight == FontWeight.bold),
        depth == 100 ? hasLength(1) : isEmpty,
      );
      final leaf = spans.singleWhere((span) => span.text == 'leaf');
      expect(leaf.style, isNull);
      expect(leaf.children, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  for (final depth in [150, 1000]) {
    testWidgets(
      'mixed functions and containers at depth $depth render safely',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            MfmText(
              parsedNodes: [_mixed(depth)],
              config: MfmRenderConfig(onLinkTap: (_) {}),
            ),
          ),
        );
        final leaf = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText() == 'leaf',
        );
        expect(leaf, findsWidgets);
        final paragraph = tester.renderObject<RenderParagraph>(leaf.last);
        final glyph = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        );
        expect(glyph, isNotEmpty);
        expect(glyph.first.toRect().width, greaterThan(0));
        expect(glyph.first.toRect().height, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('100000 nested bold nodes flatten without recursive traversal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(MfmText(parsedNodes: [_nest(100000, const TextNode('leaf'))])),
    );
    final root = _rootSpan(tester);
    expect(root.toPlainText(), 'leaf');
    expect(
      _textSpans(
        root,
      ).where((span) => span.style?.fontWeight == FontWeight.bold),
      hasLength(100),
    );
    expect(tester.takeException(), isNull);
  });

  for (final plain in [false, true]) {
    for (final nyaize in [false, true]) {
      testWidgets(
        'flattened nodes preserve content plain=$plain nyaize=$nyaize',
        (
          tester,
        ) async {
          // All node kinds are below the cutoff, including sibling subtrees.
          final node = _nest(99, const BoldNode(_allNodes));
          await tester.pumpWidget(
            _host(
              MfmText(
                parsedNodes: [node],
                plain: plain,
                config: MfmRenderConfig(enableNyaize: nyaize),
              ),
            ),
          );
          final text =
              '${nyaize ? 'にゃ' : 'な'}${plain ? ' x y z' : '\nx\ny\nz'}|'
              ':custom:🍮https://example.test/raw@alice#tag'
              'な-inlineな-blockinline-formulablock-formulaqueryBISsQCLPF';
          final root = _rootSpan(tester);
          expect(root.toPlainText(), text);
          final leaf = _textSpans(
            root,
          ).singleWhere((span) => span.text == text);
          expect(leaf.style, isNull);
          expect(leaf.children, isNull);
          expect(leaf.recognizer, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final kind in ['plain', 'quote', 'link']) {
    testWidgets('$kind above the cutoff keeps nyaize disabled', (tester) async {
      final children = [_nest(150, const TextNode('な\r\nx'))];
      final node = switch (kind) {
        'plain' => PlainNode(children),
        'quote' => QuoteNode(children),
        _ => LinkNode(silent: false, url: '/link', children: children),
      };
      await tester.pumpWidget(
        _host(
          MfmText(
            parsedNodes: [node],
            config: const MfmRenderConfig(enableNyaize: true),
          ),
        ),
      );
      expect(
        tester
            .widgetList<RichText>(_paragraphs)
            .map((p) => p.text.toPlainText()),
        contains('な\nx'),
      );
    });
  }

  test(
    'direct buildNode uses the same cutoff without consuming sibling depth',
    () {
      final builder = MfmNodeBuilder(
        config: const MfmRenderConfig(),
        colorScheme: const MfmColorScheme.light(),
        effectiveStyle: _style,
      );
      final node = _nest(1000, const TextNode('leaf'));
      final single = builder.buildNode(node);
      final siblings = builder.buildNodes([node, node]);
      for (final span in [single, ...siblings]) {
        expect(span.toPlainText(), 'leaf');
        expect(
          _textSpans(span).where((s) => s.style?.fontWeight == FontWeight.bold),
          hasLength(100),
        );
      }
    },
  );

  testWidgets('unchanged text reuses parsing while rebuilding styled spans', (
    tester,
  ) async {
    final start = debugMfmTextParseCount;
    await tester.pumpWidget(_host(const MfmText(text: '**leaf**')));
    expect(debugMfmTextParseCount - start, 1);
    final firstSpan = _rootSpan(tester);
    await tester.pumpWidget(
      _host(
        MfmText(
          text: '**leaf**',
          config: MfmRenderConfig(onLinkTap: (_) {}),
        ),
        style: _style.copyWith(fontSize: 20),
      ),
    );
    expect(debugMfmTextParseCount - start, 1);
    expect(_rootSpan(tester), isNot(same(firstSpan)));
    expect(_rootSpan(tester).style?.fontSize, 20);
    expect(_rootSpan(tester).toPlainText(), 'leaf');
  });

  testWidgets('changed text invalidates the parse cache', (tester) async {
    final start = debugMfmTextParseCount;
    await tester.pumpWidget(_host(const MfmText(text: 'first')));
    await tester.pumpWidget(_host(const MfmText(text: '**second**')));
    expect(debugMfmTextParseCount - start, 2);
    expect(_rootSpan(tester).toPlainText(), 'second');
    await tester.pumpWidget(_host(const MfmText(text: '')));
    expect(_rootSpan(tester).toPlainText(), isEmpty);
    await tester.pumpWidget(_host(const MfmText(text: 'first')));
    expect(debugMfmTextParseCount - start, 3);
    expect(_rootSpan(tester).toPlainText(), 'first');
  });

  testWidgets(
    'parser mode uses simple OR plain while spans keep current flags',
    (
      tester,
    ) async {
      final start = debugMfmTextParseCount;
      const source = '**leaf**\nline';
      await tester.pumpWidget(_host(const MfmText(text: source)));
      expect(_rootSpan(tester).toPlainText(), 'leaf\nline');
      await tester.pumpWidget(_host(const MfmText(text: source, simple: true)));
      expect(debugMfmTextParseCount - start, 2);
      expect(_rootSpan(tester).toPlainText(), source);
      await tester.pumpWidget(_host(const MfmText(text: source, plain: true)));
      expect(debugMfmTextParseCount - start, 2);
      expect(_rootSpan(tester).toPlainText(), '**leaf** line');
      await tester.pumpWidget(
        _host(const MfmText(text: source, simple: true, plain: true)),
      );
      expect(debugMfmTextParseCount - start, 2);
      await tester.pumpWidget(_host(const MfmText(text: source)));
      expect(debugMfmTextParseCount - start, 3);
      expect(_rootSpan(tester).toPlainText(), 'leaf\nline');
    },
  );

  testWidgets('parsedNodes bypasses the cache across source switches', (
    tester,
  ) async {
    final start = debugMfmTextParseCount;
    await tester.pumpWidget(
      _host(const MfmText(parsedNodes: [TextNode('provided')])),
    );
    expect(debugMfmTextParseCount, start);
    expect(_rootSpan(tester).toPlainText(), 'provided');
    await tester.pumpWidget(_host(const MfmText(text: '**cached**')));
    expect(debugMfmTextParseCount - start, 1);
    await tester.pumpWidget(
      _host(
        const MfmText(text: '**cached**', parsedNodes: [TextNode('override')]),
      ),
    );
    expect(_rootSpan(tester).toPlainText(), 'override');
    expect(debugMfmTextParseCount - start, 1);
    await tester.pumpWidget(_host(const MfmText(text: '**cached**')));
    expect(_rootSpan(tester).toPlainText(), 'cached');
    expect(debugMfmTextParseCount - start, 1);
    await tester.pumpWidget(
      _host(const MfmText(text: 'changed', parsedNodes: [])),
    );
    expect(_rootSpan(tester).toPlainText(), isEmpty);
    expect(debugMfmTextParseCount - start, 1);
    await tester.pumpWidget(_host(const MfmText(text: 'changed')));
    expect(_rootSpan(tester).toPlainText(), 'changed');
    expect(debugMfmTextParseCount - start, 2);
  });
}
