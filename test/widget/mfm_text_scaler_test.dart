import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _style = TextStyle(fontFamily: 'Ahem', fontSize: 14, height: 1);

Widget _host(
  Widget child, {
  TextScaler scaler = TextScaler.noScaling,
  TextStyle style = _style,
  MediaQueryData? mediaQuery,
  bool withMediaQuery = true,
}) {
  final body = DefaultTextStyle(
    style: style,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 750, child: child),
    ),
  );
  return Directionality(
    textDirection: TextDirection.ltr,
    child: withMediaQuery
        ? MediaQuery(
            data: mediaQuery ?? MediaQueryData(textScaler: scaler),
            child: body,
          )
        : body,
  );
}

Finder get _paragraphs => find.descendant(
  of: find.byType(MfmText),
  matching: find.byWidgetPredicate((widget) => widget is RichText),
);

Finder _paragraphWith(String text) => find
    .descendant(
      of: find.byType(MfmText),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      ),
    )
    .last;

Size _glyphSize(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(_paragraphWith(text));
  final index = paragraph.text.toPlainText().indexOf(text);
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      )
      .first;
  final start = paragraph.localToGlobal(Offset(box.left, box.top));
  final end = paragraph.localToGlobal(Offset(box.right, box.bottom));
  return Size((end.dx - start.dx).abs(), (end.dy - start.dy).abs());
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) =>
      fontSize <= 14 ? fontSize * 2 : fontSize + 14;

  @override
  double get textScaleFactor => 2;
}

void main() {
  for (final sample in [
    (name: 'body', source: 'a', label: 'a'),
    (name: 'x2', source: r'$[x2 a]', label: 'a'),
    (name: 'small', source: '<small>a</small>', label: 'a'),
    (name: 'quote', source: '> a', label: 'a'),
    (name: 'center', source: '<center>a</center>', label: 'a'),
    (name: 'x2 in quote', source: r'> $[x2 a]', label: 'a'),
    (
      name: 'small in center',
      source: '<center><small>a</small></center>',
      label: 'a',
    ),
    (name: 'unixtime', source: r'$[unixtime 0]', label: 'time'),
    (name: 'search label', source: 'query [Search]', label: 'Search'),
    (name: 'inline code', source: '`a`', label: 'a'),
    (name: 'static rainbow', source: r'$[rainbow a]', label: 'a'),
    (name: 'rainbow inline code', source: r'$[rainbow `a`]', label: 'a'),
    (name: 'mention capsule', source: '@alice', label: '@alice'),
    (name: 'code block', source: '```\na\n```', label: 'a'),
    (name: 'custom emoji', source: ':custom:', label: 'e'),
    (name: 'unicode emoji builder', source: '🍮', label: 'u'),
  ]) {
    testWidgets('${sample.name} glyph scales exactly twice, once', (
      tester,
    ) async {
      final sizes = <Size>[];
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(
          _host(
            MfmText(
              text: sample.source,
              config: MfmRenderConfig(
                enableAnimation: false,
                showCodeBlockCopyButton: false,
                unixtimeOptions: MfmUnixtimeOptions(
                  formatter: (_) => 'time',
                  autoUpdate: false,
                ),
                emojiBuilder: (_, context) =>
                    Text('e', style: context.textStyle),
                unicodeEmojiBuilder: (_, context) =>
                    Text('u', style: context.textStyle),
              ),
            ),
            scaler: TextScaler.linear(scale),
          ),
        );
        sizes.add(_glyphSize(tester, sample.label));
        expect(tester.takeException(), isNull);
      }
      // Glyph rounding differs slightly per SDK; double scaling would be 4x.
      expect(sizes[1].width, closeTo(sizes[0].width * 2, .05));
      expect(sizes[1].height, closeTo(sizes[0].height * 2, .05));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('ruby base and reading scale twice without a second transform', (
    tester,
  ) async {
    final sizes = <Size>[];
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          const MfmText(text: r'$[ruby 漢字 かんじ]'),
          scaler: TextScaler.linear(scale),
        ),
      );
      final ruby = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_MfmRubyLayout',
      );
      final box = tester.renderObject<RenderBox>(ruby);
      final start = box.localToGlobal(Offset.zero);
      final end = box.localToGlobal(box.size.bottomRight(Offset.zero));
      sizes.add(Size(end.dx - start.dx, end.dy - start.dy));
      // ベース、ルビの順に子のRichTextを持つ。
      final styles = tester
          .widgetList<RichText>(
            find.descendant(
              of: ruby,
              matching: find.byWidgetPredicate((widget) => widget is RichText),
            ),
          )
          .map((text) => text.text.style!)
          .toList();
      expect(styles.first.fontSize, 14 * scale);
      expect(styles.last.fontSize, 7 * scale);
      expect(tester.takeException(), isNull);
    }
    expect(sizes[1].width, closeTo(sizes[0].width * 2, .01));
    expect(sizes[1].height, closeTo(sizes[0].height * 2, .01));
  });

  testWidgets('search editor scales once alongside its label', (tester) async {
    final heights = <double>[];
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          const MfmText(text: 'query [Search]'),
          scaler: TextScaler.linear(scale),
        ),
      );
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final start = editable.localToGlobal(Offset.zero);
      final end = editable.localToGlobal(
        Offset(0, editable.preferredLineHeight),
      );
      heights.add(end.dy - start.dy);
    }
    expect(heights[1], closeTo(heights[0] * 2, .01));
  });

  for (final sample in [
    (source: ':custom:', size: 28.0, scale: 3.0),
    (source: r'$[x2 :custom:]', size: 56.0, scale: 6.0),
    (source: '<small>:custom:</small>', size: 28 / 1.2, scale: 3.0),
    (source: '> :custom:', size: 28.0, scale: 3.0),
    (source: '<center>:custom:</center>', size: 28.0, scale: 3.0),
  ]) {
    testWidgets('emoji context resolves text scaling in ${sample.source}', (
      tester,
    ) async {
      final contexts = <MfmEmojiContext>[];
      await tester.pumpWidget(
        _host(
          MfmText(
            text: sample.source,
            rootScale: 3,
            config: MfmRenderConfig(
              baseTextStyle: _style,
              emojiBuilder: (_, context) {
                contexts.add(context);
                return Text('e', style: context.textStyle);
              },
            ),
          ),
          scaler: const TextScaler.linear(2),
        ),
      );
      final context = contexts.single;
      expect(context.fontSize, closeTo(sample.size, 1e-6));
      expect(context.textStyle!.fontSize, closeTo(sample.size, 1e-6));
      expect(context.scale, sample.scale);
      expect(_style.fontSize, 14);
    });
  }

  testWidgets('quote pixel margins, padding and border do not scale', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          const MfmText(text: '> a'),
          scaler: TextScaler.linear(scale),
        ),
      );
      final quote = find.descendant(
        of: find.byType(MfmText),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.margin == const EdgeInsets.all(8),
        ),
      );
      final container = tester.widget<Container>(quote);
      expect(container.padding, const EdgeInsets.fromLTRB(12, 6, 0, 6));
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(border.left.width, 3);
      final origin = tester.getTopLeft(quote);
      final textOrigin = tester.getTopLeft(_paragraphWith('a'));
      expect(textOrigin.dx - origin.dx, closeTo(8 + 3 + 12, .01));
      expect(textOrigin.dy - origin.dy, closeTo(8 + 6, .01));
    }
  });

  testWidgets('pixel letter spacing matches across the WidgetSpan boundary', (
    tester,
  ) async {
    for (final source in ['a', '> a']) {
      await tester.pumpWidget(
        _host(
          MfmText(text: source),
          scaler: const TextScaler.linear(2),
          style: _style.copyWith(letterSpacing: 2),
        ),
      );
      expect(_glyphSize(tester, 'a').width, closeTo(28 + 2, .01));
    }
  });

  testWidgets('nonlinear scaling resolves the root and preserves x2 ratios', (
    tester,
  ) async {
    expect(const _NonlinearScaler().scale(14), 28);
    expect(const _NonlinearScaler().scale(28), 42);
    for (final source in [r'$[x2 a]', r'> $[x2 a]']) {
      await tester.pumpWidget(
        _host(MfmText(text: source), scaler: const _NonlinearScaler()),
      );
      expect(_glyphSize(tester, 'a').width, closeTo(56, .01));
      expect(_glyphSize(tester, 'a').height, closeTo(56, .01));
    }
  });

  testWidgets('missing MediaQuery keeps natural text size', (tester) async {
    await tester.pumpWidget(
      _host(const MfmText(text: 'a'), withMediaQuery: false),
    );
    final size = _glyphSize(tester, 'a');
    expect(size.width, closeTo(14, .01));
    expect(size.height, closeTo(14, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing and zero font sizes resolve without invalid scaling', (
    tester,
  ) async {
    for (final fontSize in <double?>[null, 0]) {
      await tester.pumpWidget(
        _host(
          MfmText(
            text: 'a',
            config: MfmRenderConfig(
              baseTextStyle: TextStyle(fontSize: fontSize),
            ),
          ),
          scaler: const TextScaler.linear(2),
        ),
      );
      final root = tester.widget<RichText>(_paragraphs.first);
      expect(root.text.style!.fontSize, (fontSize ?? 14) * 2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('subtree removes scaling and retains other MediaQuery values', (
    tester,
  ) async {
    final values = <MediaQueryData>[];
    const mediaQuery = MediaQueryData(
      textScaler: TextScaler.linear(2),
      padding: EdgeInsets.all(8),
      viewInsets: EdgeInsets.only(bottom: 20),
      size: Size(750, 600),
    );
    await tester.pumpWidget(
      _host(
        MfmText(
          text: ':probe:',
          config: MfmRenderConfig(
            emojiBuilder: (_, context) => Builder(
              builder: (context) {
                values.add(MediaQuery.of(context));
                return const SizedBox(width: 14, height: 14);
              },
            ),
          ),
        ),
        mediaQuery: mediaQuery,
      ),
    );
    expect(values.single.textScaler, TextScaler.noScaling);
    expect(values.single.padding, mediaQuery.padding);
    expect(values.single.viewInsets, mediaQuery.viewInsets);
    expect(values.single.size, mediaQuery.size);
  });

  testWidgets('padding updates rebuild the wrapper without rebuilding spans', (
    tester,
  ) async {
    var spanBuilds = 0;
    final fontSizes = <double>[];
    final values = <MediaQueryData>[];
    final child = MfmText(
      text: ':probe:',
      config: MfmRenderConfig(
        emojiBuilder: (_, context) {
          spanBuilds++;
          fontSizes.add(context.fontSize);
          return Builder(
            builder: (context) {
              values.add(MediaQuery.of(context));
              return const SizedBox(width: 14, height: 14);
            },
          );
        },
      ),
    );
    const data = MediaQueryData(textScaler: TextScaler.linear(2));
    await tester.pumpWidget(_host(child, mediaQuery: data));
    final original = tester.widget<RichText>(_paragraphs.first);
    expect(spanBuilds, 1);
    await tester.pumpWidget(
      _host(
        child,
        mediaQuery: data.copyWith(padding: const EdgeInsets.all(10)),
      ),
    );
    expect(spanBuilds, 1);
    expect(tester.widget<RichText>(_paragraphs.first), same(original));
    expect(
      tester.widget<RichText>(_paragraphs.first).text,
      same(original.text),
    );
    expect(values.last.padding, const EdgeInsets.all(10));
    expect(values.last.textScaler, TextScaler.noScaling);
    await tester.pumpWidget(
      _host(
        child,
        mediaQuery: data.copyWith(textScaler: const TextScaler.linear(3)),
      ),
    );
    expect(spanBuilds, 2);
    expect(fontSizes, [28, 42]);
    expect(values.last.textScaler, TextScaler.noScaling);
  });
}
