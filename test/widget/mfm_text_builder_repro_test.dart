import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _style = TextStyle(fontFamily: 'Ahem', fontSize: 14, height: 1);

Widget _host(Widget child, {double scale = 1, double width = 700}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: DefaultTextStyle(
        style: _style,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

Finder _paragraphWithText(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == text,
);

// RenderParagraph.size is local to WidgetSpan's automatic scale transform.
// Measure a glyph in global coordinates to catch both missing and double scale.
Size _paintedGlyphSize(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final box = paragraph
      .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
      .single;
  final start = paragraph.localToGlobal(Offset(box.left, box.top));
  final end = paragraph.localToGlobal(Offset(box.right, box.bottom));
  return Size((end.dx - start.dx).abs(), (end.dy - start.dy).abs());
}

List<MfmNode> _nestedBold(int depth) {
  MfmNode node = const TextNode('leaf');
  for (var i = 0; i < depth; i++) {
    node = BoldNode([node]);
  }
  return [node];
}

// Keep expected StackOverflowErrors concise, while restoring flutter_test's
// handler before making assertions. Unrelated framework errors also fail.
Future<List<Object>> _pumpCollectingErrors(
  WidgetTester tester,
  Widget widget,
) async {
  final errors = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exception);
    // ignore: avoid_print
    print(
      '[4] framework error: ${details.exception.runtimeType}; '
      '${details.stack?.toString().split('\n').take(4).join(' | ')}',
    );
  };
  try {
    await tester.pumpWidget(widget);
  } on Object catch (error) {
    errors.add(error);
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

class _RecognizerTracker {
  final created = <TapGestureRecognizer>{};
  final disposed = <TapGestureRecognizer>{};

  void onEvent(ObjectEvent event) {
    final object = event.object;
    if (object is! TapGestureRecognizer) return;
    if (event is ObjectCreated) created.add(object);
    if (event is ObjectDisposed) disposed.add(object);
  }

  int get liveCount => created.difference(disposed).length;

  void start() {
    expect(kFlutterMemoryAllocationsEnabled, isTrue);
    FlutterMemoryAllocations.instance.addListener(onEvent);
    addTearDown(() {
      FlutterMemoryAllocations.instance.removeListener(onEvent);
      // Clean up only after the lifecycle assertions have observed the leak.
      for (final recognizer in created.difference(disposed)) {
        recognizer.dispose();
      }
    });
  }
}

void main() {
  for (final sample in [
    (name: 'body', source: 'a', label: 'a'),
    (name: 'x2 inline span', source: r'$[x2 a]', label: 'a'),
    (name: 'quote WidgetSpan', source: '> a', label: 'a'),
    (name: 'center WidgetSpan', source: '<center>a</center>', label: 'a'),
    (name: 'x2 inside quote WidgetSpan', source: r'> $[x2 a]', label: 'a'),
    (name: 'unixtime Text', source: r'$[unixtime 0]', label: 'time'),
    (name: 'search label Text', source: '検索 [Search]', label: 'Search'),
  ]) {
    testWidgets('[1] ${sample.name} scales exactly twice, once', (
      tester,
    ) async {
      final sizes = <Size>[];
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(
          _host(
            MfmText(
              text: sample.source,
              config: MfmRenderConfig(
                baseTextStyle: _style,
                unixtimeOptions: MfmUnixtimeOptions(
                  formatter: (_) => 'time',
                  autoUpdate: false,
                ),
              ),
            ),
            scale: scale,
          ),
        );
        sizes.add(_paintedGlyphSize(tester, _paragraphWithText(sample.label)));
      }
      // ignore: avoid_print
      print('[1] ${sample.name}: scale=1 ${sizes[0]}, scale=2 ${sizes[1]}');
      expect(sizes[1].width, closeTo(sizes[0].width * 2, .01));
      expect(sizes[1].height, closeTo(sizes[0].height * 2, .01));
    });
  }

  testWidgets('[1] search editor text scales exactly twice, once', (
    tester,
  ) async {
    final heights = <double>[];
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(const MfmText(text: '検索 [Search]'), scale: scale),
      );
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final start = editable.localToGlobal(Offset.zero);
      final end = editable.localToGlobal(
        Offset(0, editable.preferredLineHeight),
      );
      heights.add((end.dy - start.dy).abs());
    }
    // ignore: avoid_print
    print('[1] search editor painted line heights: $heights');
    expect(heights[1], closeTo(heights[0] * 2, .01));
  });

  testWidgets('[2] nowrap preserves all three explicit newline rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MfmText(text: 'a\nb\nc', nowrap: true)),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    final visibleRows = [
      for (final offset in [0, 2, 4])
        paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: offset, extentOffset: offset + 1),
            )
            .isNotEmpty,
    ];
    expect(
      {'height': paragraph.size.height, 'visibleRows': visibleRows},
      {
        'height': 42.0,
        'visibleRows': [true, true, true],
      },
    );
  });

  for (final sample in [
    (name: 'root', source: 'abcdefghijklmnopqrst', height: 14.0),
    (
      name: 'x2 inline span',
      source: r'$[x2 abcdefghijklmnopqrst]',
      height: 28.0,
    ),
    (name: 'quote WidgetSpan', source: '> abcdefghijklmnopqrst', height: 14.0),
    (
      name: 'x2 inside quote WidgetSpan',
      source: r'> $[x2 abcdefghijklmnopqrst]',
      height: 28.0,
    ),
    (
      name: 'flip WidgetSpan',
      source: r'$[flip abcdefghijklmnopqrst]',
      height: 14.0,
    ),
  ]) {
    testWidgets('[2] nowrap ${sample.name} keeps a long line unwrapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(MfmText(text: sample.source, nowrap: true), width: 100),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        _paragraphWithText('abcdefghijklmnopqrst'),
      );
      // ignore: avoid_print
      print('[2] nowrap ${sample.name}: height=${paragraph.size.height}');
      expect(paragraph.size.height, closeTo(sample.height, .01));
    });
  }

  testWidgets('[2] investigate unlimited-line RichText ellipsis', (
    tester,
  ) async {
    for (final source in [
      'abcdefghijklmnopqrst\nshort\nabcdefghijklmnopqrst',
      'short\nabcdefghijklmnopqrst\nshort',
      'short\nshort\nshort',
    ]) {
      await tester.pumpWidget(
        _host(
          RichText(
            text: TextSpan(text: source, style: _style),
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          width: 100,
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      var offset = 0;
      final rowBoxes = <String>[];
      for (final line in source.split('\n')) {
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + line.length),
        );
        rowBoxes.add(boxes.toString());
        offset += line.length + 1;
      }
      final painter = TextPainter(
        text: TextSpan(text: source, style: _style),
        textDirection: TextDirection.ltr,
        ellipsis: '…',
      )..layout(maxWidth: 100);
      final metrics = painter.computeLineMetrics().map(
        (line) =>
            '(line=${line.lineNumber}, width=${line.width}, '
            'height=${line.height}, hardBreak=${line.hardBreak})',
      );
      // ignore: avoid_print
      print(
        '[2] ellipsis ${source.replaceAll('\n', r'\n')}: '
        'size=${paragraph.size}, exceeded=${paragraph.didExceedMaxLines}, '
        'rowBoxes=$rowBoxes, '
        'lineMetrics=${metrics.toList()}',
      );
      painter.dispose();
    }
  });

  for (final sample in [
    (name: 'URL', source: 'https://example.com/'),
    (name: 'link', source: '[link](https://example.com/)'),
    (name: 'text mention', source: '@alice'),
    (name: 'hashtag', source: '#tag'),
  ]) {
    MfmText text() => MfmText(
      text: sample.source,
      config: MfmRenderConfig(
        onLinkTap: (_) {},
        onMentionTap: (_) {},
        onHashtagTap: (_) {},
        mentionOptions: const MfmMentionOptions(
          presentation: MfmMentionPresentation.text,
        ),
      ),
    );

    testWidgets('[3] ${sample.name} recognizers are disposed on unmount', (
      tester,
    ) async {
      final tracker = _RecognizerTracker()..start();
      await tester.pumpWidget(_host(text()));
      expect(tracker.created, isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        tracker.liveCount,
        0,
        reason:
            '${tracker.created.length} created, '
            '${tracker.disposed.length} disposed after unmount',
      );
    });

    testWidgets('[3] ${sample.name} live recognizers stay bounded on rebuild', (
      tester,
    ) async {
      final tracker = _RecognizerTracker()..start();
      final liveCounts = <int>[];
      for (var i = 0; i < 5; i++) {
        // New widget instances rebuild the same MfmText element each time.
        await tester.pumpWidget(_host(text()));
        liveCounts.add(tracker.liveCount);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      // ignore: avoid_print
      print('[3] ${sample.name} live recognizers per build: $liveCounts');
      expect(liveCounts.first, greaterThan(0));
      expect(liveCounts, everyElement(lessThanOrEqualTo(liveCounts.first)));
    });
  }

  for (final depth in [1000, 2000, 5000, 10000, 20000]) {
    testWidgets('[4] depth $depth renders the innermost text without errors', (
      tester,
    ) async {
      final errors = await _pumpCollectingErrors(
        tester,
        _host(MfmText(parsedNodes: _nestedBold(depth))),
      );
      // ignore: avoid_print
      print(
        '[4] depth=$depth errors=${errors.map((e) => e.runtimeType).toList()}',
      );
      expect(errors.map((e) => e.runtimeType.toString()).toList(), isEmpty);
      // Inspect layout as well as the span's text: the leaf must be visible.
      final leaf = _paragraphWithText('leaf');
      expect(leaf, findsOneWidget);
      expect(_paintedGlyphSize(tester, leaf).height, greaterThan(0));
    });
  }

  testWidgets('[5] non-plain TextNode normalizes CRLF and CR to LF', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MfmText(parsedNodes: [TextNode('a\r\nb\rc')])),
    );
    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'a\nb\nc');
  });
}
