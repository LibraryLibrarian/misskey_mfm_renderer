import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_border.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_link_span.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_mention_text_span.dart';

const _url = 'https://outside.test/a';
const ValueKey<String> _emojiKey = ValueKey('label-emoji');

Future<void> _mount(
  WidgetTester tester,
  String text, {
  void Function(String)? onLinkTap,
  void Function(String)? onClickableEvent,
  String? localHost = 'self.test',
  List<MfmNode>? nodes,
  double fontSize = 20,
  double width = 600,
  bool animation = false,
  bool nyaize = false,
  bool nowrap = false,
  Widget Function(String, MfmEmojiContext)? emojiBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: MfmText(
            text: nodes == null ? text : null,
            parsedNodes: nodes,
            nowrap: nowrap,
            config: MfmRenderConfig(
              localHost: localHost,
              enableAnimation: animation,
              enableNyaize: nyaize,
              onClickableEvent: onClickableEvent,
              baseTextStyle: TextStyle(fontSize: fontSize, height: 1.5),
              onLinkTap: onLinkTap,
              emojiBuilder: emojiBuilder,
            ),
          ),
        ),
      ),
    ),
  );
}

Offset _glyph(WidgetTester tester, String text) {
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byWidgetPredicate((w) => w is RichText || w is MfmRainbowRichText),
  )) {
    final index = paragraph.text.toPlainText().indexOf(text);
    if (index < 0) continue;
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: index, extentOffset: index + 1),
        )
        .first;
    return paragraph.localToGlobal(box.toRect().center);
  }
  throw TestFailure('Actual glyph not found: $text');
}

List<SemanticsNode> _nodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester
        .renderObject(find.byType(MfmText))
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return nodes;
}

void _tapSemantics(WidgetTester tester, SemanticsNode node) {
  tester
      .renderObject(find.byType(MfmText))
      .owner!
      .semanticsOwner!
      .performAction(
        node.id,
        SemanticsAction.tap,
      );
}

void main() {
  for (final entry in <({String url, String? host, bool external})>[
    (url: _url, host: 'self.test', external: true),
    (url: 'https://SELF.test./a', host: 'self.TEST', external: false),
    (url: 'http://self.test/a', host: 'self.test', external: false),
    (url: 'https://self.test:8443/a', host: 'self.test', external: false),
    (url: 'https://self.test/a', host: 'self.test:443', external: false),
    (url: 'http://self.test/a', host: 'self.test:443', external: true),
    (url: 'https://xn--wgv71a119e.jp/a', host: '日本語.jp', external: false),
    (url: 'https://[::1]/a', host: '[::1]:443', external: false),
    (url: _url, host: null, external: true),
    (url: _url, host: '', external: true),
    (url: _url, host: 'not a host', external: true),
    (url: 'mailto:someone@example.test', host: null, external: false),
    (url: '/relative', host: null, external: false),
    (url: 'https://[invalid', host: null, external: false),
  ]) {
    for (final silent in [false, true]) {
      testWidgets(
        'AST classification ${entry.url} host=${entry.host} silent=$silent',
        (tester) async {
          final calls = <String>[];
          await _mount(
            tester,
            '',
            localHost: entry.host,
            onLinkTap: calls.add,
            nodes: [
              LinkNode(
                silent: silent,
                url: entry.url,
                children: const [TextNode('LABEL')],
              ),
            ],
          );
          expect(
            find.byType(Icon),
            entry.external ? findsOneWidget : findsNothing,
          );
          await tester.tapAt(_glyph(tester, 'LABEL'));
          expect(calls, [entry.url]);
          if (entry.url.startsWith('http') && entry.url != 'https://[invalid') {
            await _mount(
              tester,
              '',
              localHost: entry.host,
              onLinkTap: calls.add,
              nodes: [UrlNode(url: entry.url)],
            );
            expect(
              find.byType(Icon),
              entry.external ? findsOneWidget : findsNothing,
            );
            await tester.tapAt(
              _glyph(
                tester,
                entry.external ? 'http' : 'a',
              ),
            );
            expect(calls, [entry.url, entry.url]);
          }
        },
      );
    }
  }

  testWidgets('parsed silent label and icon share the raw callback', (
    tester,
  ) async {
    final calls = <String>[];
    const raw = 'https://outside.test/%E3%81%AA?q=%2F#part';
    await _mount(tester, '?[LABEL]($raw)', onLinkTap: calls.add);
    expect(find.byType(Icon), findsOneWidget);
    await tester.tapAt(_glyph(tester, 'LABEL'));
    await tester.tap(find.byType(Icon));
    expect(calls, [raw, raw]);
  });

  test(
    'adapter preserves metadata, subclasses and child recognizer ownership',
    () {
      final link = TapGestureRecognizer()..onTap = () {};
      final child = TapGestureRecognizer()..onTap = () {};
      addTearDown(link.dispose);
      addTearDown(child.dispose);
      void enter(PointerEnterEvent event) {}
      void exit(PointerExitEvent event) {}
      final original = TextSpan(
        text: 'A',
        style: const TextStyle(fontSize: 17),
        semanticsLabel: 'spoken',
        semanticsIdentifier: 'identifier',
        locale: const Locale('ja'),
        spellOut: true,
        onEnter: enter,
        onExit: exit,
        children: [TextSpan(text: 'owned', recognizer: child)],
      );
      final adapted = adaptMfmLinkSpan(original, link) as TextSpan;
      expect(adapted.recognizer, same(link));
      expect(adapted.style, original.style);
      expect(adapted.semanticsLabel, 'spoken');
      expect(adapted.semanticsIdentifier, 'identifier');
      expect(adapted.locale, const Locale('ja'));
      expect(adapted.spellOut, isTrue);
      expect(adapted.onEnter, same(enter));
      expect(adapted.onExit, same(exit));
      expect(adapted.mouseCursor, SystemMouseCursors.click);
      expect(adapted.children!.single, same(original.children!.single));
      final rainbow =
          adaptMfmLinkSpan(
                const MfmRainbowSpan(
                  opacity: .49,
                  text: 'RAINBOW',
                  semanticsLabel: 'rainbow',
                ),
                link,
              )
              as MfmRainbowSpan;
      expect(rainbow.opacity, .49);
      expect(rainbow.recognizer, same(link));
      expect(rainbow.semanticsLabel, 'rainbow');
      final mention = adaptMfmLinkSpan(
        const MfmMentionTextSpan(
          children: [
            TextSpan(text: '@name'),
            TextSpan(text: '@host'),
          ],
        ),
        link,
      );
      expect(mention, isA<MfmMentionTextSpan>());
      final info = mention.getSemanticsInformation();
      expect(info.single.text, '@name@host');
      expect(info.single.recognizer, same(link));
      const unknown = _UnknownSpan(text: 'unknown');
      expect(adaptMfmLinkSpan(unknown, link), same(unknown));
      const widget = WidgetSpan(
        alignment: PlaceholderAlignment.aboveBaseline,
        baseline: TextBaseline.ideographic,
        style: TextStyle(fontSize: 13),
        child: SizedBox(width: 10),
      );
      final bridge = adaptMfmLinkSpan(widget, link) as WidgetSpan;
      expect(bridge.alignment, widget.alignment);
      expect(bridge.baseline, widget.baseline);
      expect(bridge.style, widget.style);
    },
  );

  testWidgets(
    'icon retains raw URL metrics and does not inherit final label style',
    (
      tester,
    ) async {
      await _mount(
        tester,
        r'[LABEL $[fg.color=ff0000 <small>END</small>]](https://outside.test/a)',
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon!.codePoint, 0xe45c);
      expect(icon.icon!.fontFamily, 'MaterialIcons');
      expect(icon.icon!.matchTextDirection, isTrue);
      expect(icon.size, 18);
      expect(icon.color, const MfmColorScheme.light().link);
      expect(icon.semanticLabel, 'External link');
      final padding = tester.widget<Padding>(
        find
            .ancestor(of: find.byType(Icon), matching: find.byType(Padding))
            .first,
      );
      expect(padding.padding, const EdgeInsets.only(left: 2));
      final root = tester.widget<RichText>(find.byType(RichText).first).text;
      final icons = <WidgetSpan>[];
      void visit(InlineSpan span) {
        if (span is WidgetSpan) icons.add(span);
        if (span is TextSpan) span.children?.forEach(visit);
      }

      visit(root);
      expect(icons.last.alignment, PlaceholderAlignment.baseline);
      expect(icons.last.baseline, TextBaseline.alphabetic);
    },
  );

  for (final label in [
    '**BOLD**',
    '<i>ITALIC</i>',
    '~~STRIKE~~',
    '<small>SMALL</small>',
    r'$[fg.color=ff0000 FOREGROUND]',
    r'$[bg.color=00ff00 BACKGROUND]',
    r'$[scale.x=1.2 SCALE]',
    r'$[position.x=0.2 POSITION]',
    r'$[rainbow RAINBOW]',
  ]) {
    for (final animation in [false, true]) {
      testWidgets('rich label real glyph tap $label animation=$animation', (
        tester,
      ) async {
        final calls = <String>[];
        await _mount(
          tester,
          '[$label]($_url)',
          animation: animation,
          onLinkTap: calls.add,
        );
        final word = RegExp(r'[A-Z]+').firstMatch(label)!.group(0)!;
        await tester.tapAt(_glyph(tester, word));
        expect(calls, [_url]);
        expect(find.byType(Icon), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final entry in [
    (text: '[LABEL]($_url)', alpha: 1.0, size: 20.0),
    (text: '<small>[LABEL]($_url)</small>', alpha: .7, size: 16.0),
    (
      text: '<small><small>[LABEL]($_url)</small></small>',
      alpha: .49,
      size: 12.8,
    ),
    (text: '> <small>[LABEL]($_url)</small>', alpha: .49, size: 16.0),
  ]) {
    testWidgets('label icon applies cumulative opacity once ${entry.text}', (
      tester,
    ) async {
      await _mount(tester, entry.text);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color!.a, closeTo(entry.alpha, .001));
      expect(icon.size, closeTo(entry.size * .9, .001));
    });
  }

  testWidgets(
    'semantic-only child action takes precedence without deleting its label',
    (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final calls = <String>[];
      var childCalls = 0;
      await _mount(
        tester,
        '[:test:]($_url)',
        onLinkTap: calls.add,
        emojiBuilder: (_, _) => Semantics(
          label: 'OWNED',
          onTap: () => childCalls++,
          child: const SizedBox(key: _emojiKey, width: 40, height: 30),
        ),
      );
      final owned = _nodes(
        tester,
      ).singleWhere((n) => n.label.contains('OWNED'));
      _tapSemantics(tester, owned);
      expect(childCalls, 1);
      expect(calls, isEmpty);
      // A semantics-only action is not a pointer recognizer.
      await tester.tapAt(tester.getCenter(find.byKey(_emojiKey)));
      expect(childCalls, 1);
      expect(calls, [_url]);
      semantics.dispose();
    },
  );

  testWidgets('subtree nyaize suppression and emoji fallback are retained', (
    tester,
  ) async {
    final calls = <String>[];
    await _mount(
      tester,
      r'[な **な** $[ruby な な] :missing:](https://outside.test/a)',
      onLinkTap: calls.add,
      nyaize: true,
    );
    final plain = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .join();
    expect(plain, contains('な な'));
    expect(plain, isNot(contains('にゃ')));
    await tester.tapAt(_glyph(tester, ':missing:'));
    expect(calls, [_url]);
  });

  testWidgets(
    'long labels wrap inline and whitespace between lines is not a link',
    (
      tester,
    ) async {
      final calls = <String>[];
      await _mount(
        tester,
        '[AAAA BBBB CCCC DDDD]($_url)',
        width: 120,
        onLinkTap: calls.add,
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText).first,
      );
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 19),
      );
      expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
      final first = boxes.first.toRect();
      final second = boxes.firstWhere((box) => box.top > first.top).toRect();
      expect(second.top, greaterThan(first.bottom));
      await tester.tapAt(
        paragraph.localToGlobal(Offset(10, (first.bottom + second.top) / 2)),
      );
      expect(calls, isEmpty);
      await tester.tapAt(_glyph(tester, 'DDDD'));
      expect(calls, [_url]);
      await _mount(
        tester,
        '[AAAA BBBB CCCC DDDD]($_url)',
        width: 120,
        onLinkTap: calls.add,
        nowrap: true,
      );
      expect(tester.widget<RichText>(find.byType(RichText).first).maxLines, 1);
    },
  );

  testWidgets('glyph and icon taps deliver the raw URL once', (tester) async {
    final calls = <String>[];
    final semantics = tester.ensureSemantics();
    await _mount(tester, '[LABEL]($_url)', onLinkTap: calls.add);
    await tester.tapAt(_glyph(tester, 'LABEL'));
    expect(calls, [_url]);
    await tester.tap(find.byType(Icon));
    expect(calls, [_url, _url]);
    final label = _nodes(tester).singleWhere((node) => node.label == 'LABEL');
    expect(label.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    _tapSemantics(tester, label);
    expect(calls, [_url, _url, _url]);
    semantics.dispose();
  });

  testWidgets('emoji-only label keeps passive semantics and real taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final calls = <String>[];
    await _mount(
      tester,
      '[:test:]($_url)',
      onLinkTap: calls.add,
      emojiBuilder: (_, _) => const SizedBox(
        key: _emojiKey,
        width: 30,
        height: 30,
        child: Text('PASSIVE'),
      ),
    );
    await tester.tapAt(tester.getCenter(find.byKey(_emojiKey)));
    expect(calls, [_url]);
    final label = _nodes(
      tester,
    ).singleWhere((n) => n.label == 'PASSIVE\nExternal link');
    expect(label.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    _tapSemantics(tester, label);
    expect(calls, [_url, _url]);
    semantics.dispose();
  });

  testWidgets('ruby-only label accepts base and annotation pointer taps', (
    tester,
  ) async {
    final calls = <String>[];
    await _mount(
      tester,
      r'[$[ruby BASE annotation]](https://outside.test/a)',
      onLinkTap: calls.add,
    );
    final ruby = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
    );
    final rect = tester.getRect(ruby);
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 3));
    expect(calls, [_url]);
    await tester.tapAt(Offset(rect.center.dx, rect.top + 3));
    expect(calls, [_url, _url]);
  });

  for (final boundary in [false, true]) {
    testWidgets('child gestures and semantics win boundary=$boundary', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var childCalls = 0;
      final calls = <String>[];
      await _mount(
        tester,
        '[:test:]($_url)',
        onLinkTap: calls.add,
        emojiBuilder: (_, _) => Semantics(
          container: boundary,
          child: GestureDetector(
            onTap: () => childCalls++,
            child: const SizedBox(
              key: _emojiKey,
              width: 40,
              height: 30,
              child: Text('CHILD'),
            ),
          ),
        ),
      );
      await tester.tapAt(tester.getCenter(find.byKey(_emojiKey)));
      expect(childCalls, 1);
      expect(calls, isEmpty);
      final child = _nodes(tester).singleWhere((n) => n.label == 'CHILD');
      expect(child.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      _tapSemantics(tester, child);
      expect(childCalls, 2);
      expect(calls, isEmpty);
      semantics.dispose();
    });
  }

  for (final text in ['LABEL', ':test:']) {
    testWidgets('callback null/add/replace/remove and state updates: $text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final first = <String>[];
      final second = <String>[];
      var mounts = 0;
      Widget emoji(String _, MfmEmojiContext context) => _StateProbe(
        key: _emojiKey,
        onMount: () => mounts++,
      );
      Future<void> pump(
        void Function(String)? callback,
        String url, {
        double size = 20,
      }) => _mount(
        tester,
        '[$text]($url)',
        onLinkTap: callback,
        emojiBuilder: emoji,
        fontSize: size,
      );
      Future<void> tap() => tester.tapAt(
        text == 'LABEL'
            ? _glyph(tester, 'LABEL')
            : tester.getCenter(find.byKey(_emojiKey)),
      );
      await pump(null, _url);
      expect(
        _nodes(
          tester,
        ).where((n) => n.getSemanticsData().hasAction(SemanticsAction.tap)),
        isEmpty,
      );
      await tap();
      expect(first, isEmpty);
      await pump(first.add, _url);
      await tap();
      expect(first, [_url]);
      final mounted = mounts;
      await pump(second.add, 'https://self.test/changed', size: 24);
      expect(mounts, mounted);
      expect(find.byType(Icon), findsNothing);
      await tap();
      expect(first, [_url]);
      expect(second, ['https://self.test/changed']);
      final action = _nodes(
        tester,
      ).singleWhere((n) => n.getSemanticsData().hasAction(SemanticsAction.tap));
      _tapSemantics(tester, action);
      expect(second, [
        'https://self.test/changed',
        'https://self.test/changed',
      ]);
      await pump(null, _url);
      await tap();
      expect(second, hasLength(2));
      expect(
        _nodes(
          tester,
        ).where((n) => n.getSemanticsData().hasAction(SemanticsAction.tap)),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('plain widget without accessible text remains pointer tappable', (
    tester,
  ) async {
    final calls = <String>[];
    await _mount(
      tester,
      '[:test:]($_url)',
      onLinkTap: calls.add,
      emojiBuilder: (_, _) =>
          const SizedBox(key: _emojiKey, width: 40, height: 30),
    );
    await tester.tapAt(tester.getCenter(find.byKey(_emojiKey)));
    expect(calls, [_url]);
  });

  testWidgets(
    'explicit passive boundary keeps content separate from fallback',
    (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final calls = <String>[];
      await _mount(
        tester,
        '[:test:]($_url)',
        onLinkTap: calls.add,
        emojiBuilder: (_, _) => Semantics(
          container: true,
          label: 'BOUNDARY',
          child: const SizedBox(width: 40, height: 30),
        ),
      );
      final label = _nodes(tester).singleWhere((n) => n.label == 'BOUNDARY');
      // A child-requested boundary is not rewritten or merged into the link.
      expect(label.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      final fallback = _nodes(
        tester,
      ).singleWhere((n) => n.getSemanticsData().hasAction(SemanticsAction.tap));
      _tapSemantics(tester, fallback);
      expect(calls, [_url]);
      semantics.dispose();
    },
  );

  testWidgets(
    'drag, cancellation, adjacent text and widget exterior do not tap',
    (
      tester,
    ) async {
      final calls = <String>[];
      await _mount(
        tester,
        'BEFORE [LABEL :test:]($_url) AFTER',
        onLinkTap: calls.add,
        emojiBuilder: (_, _) =>
            const SizedBox(key: _emojiKey, width: 40, height: 30),
      );
      await tester.tapAt(_glyph(tester, 'BEFORE'));
      await tester.tapAt(_glyph(tester, 'AFTER'));
      final rect = tester.getRect(find.byKey(_emojiKey));
      await tester.tapAt(rect.bottomCenter + const Offset(0, 10));
      for (final point in [_glyph(tester, 'LABEL'), rect.center]) {
        final drag = await tester.startGesture(point);
        await drag.moveBy(const Offset(80, 80));
        await drag.up();
        final cancelled = await tester.startGesture(point);
        await cancelled.cancel();
      }
      expect(calls, isEmpty);
    },
  );

  testWidgets('inner border uses rectangle but outer border still clips hits', (
    tester,
  ) async {
    final calls = <String>[];
    await _mount(
      tester,
      r'[$[border.width=8,radius=15 LABEL]](https://outside.test/a)',
      onLinkTap: calls.add,
    );
    var rect = tester.getRect(find.byType(MfmBorder));
    await tester.tapAt(rect.topLeft + const Offset(1, 1));
    expect(calls, [_url]);
    await tester.tapAt(_glyph(tester, 'LABEL'));
    expect(calls, [_url, _url]);
    calls.clear();
    await _mount(
      tester,
      r'$[border.width=8,radius=15 [LABEL](https://outside.test/a)]',
      onLinkTap: calls.add,
    );
    rect = tester.getRect(find.byType(MfmBorder));
    await tester.tapAt(rect.topLeft + const Offset(1, 1));
    expect(calls, isEmpty);
    await tester.tapAt(_glyph(tester, 'LABEL'));
    expect(calls, [_url]);
  });

  testWidgets('clickable and blur keep their child interactions', (
    tester,
  ) async {
    final calls = <String>[];
    final events = <String>[];
    await _mount(
      tester,
      r'[$[clickable.ev=child LABEL]](https://outside.test/a)',
      onLinkTap: calls.add,
      onClickableEvent: events.add,
    );
    await tester.tapAt(_glyph(tester, 'LABEL'));
    expect(events, ['child']);
    expect(calls, isEmpty);
    await _mount(
      tester,
      r'[$[blur LABEL]](https://outside.test/a)',
      onLinkTap: calls.add,
    );
    final before = tester
        .widget<ImageFiltered>(find.byType(ImageFiltered))
        .imageFilter;
    await tester.tapAt(_glyph(tester, 'LABEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, isEmpty);
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).imageFilter,
      isNot(before),
    );
  });
}

class _StateProbe extends StatefulWidget {
  const _StateProbe({super.key, required this.onMount});
  final VoidCallback onMount;
  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 40, height: 30, child: Text('STATE'));
}

class _UnknownSpan extends TextSpan {
  const _UnknownSpan({super.text});
}
