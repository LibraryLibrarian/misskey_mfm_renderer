import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _pixelsKey = Key('ruby pixels');
const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _style = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 20,
  height: 1,
  color: _blue,
);

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: DefaultTextStyle(
      style: _style,
      child: Center(
        child: RepaintBoundary(key: _pixelsKey, child: child),
      ),
    ),
  ),
);

// Measure painted glyphs/images, without relying on ruby's widget structure.
Future<({Rect red, Rect blue})> _ink(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelsKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      ))!;
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      Rect? red;
      Rect? blue;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final offset = (y * image.width + x) * 4;
          if (bytes[offset + 3] < 128) continue;
          final pixel = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
          if (bytes[offset] > 200 && bytes[offset + 2] < 50) {
            red = red?.expandToInclude(pixel) ?? pixel;
          }
          if (bytes[offset + 2] > 200 && bytes[offset] < 50) {
            blue = blue?.expandToInclude(pixel) ?? pixel;
          }
        }
      }
      expect(red, isNotNull, reason: 'The base must actually be painted.');
      expect(blue, isNotNull, reason: 'The reading must actually be painted.');
      return (red: red!, blue: blue!);
    } finally {
      image.dispose();
    }
  }))!;
}

void _expectReadingAboveBase(({Rect red, Rect blue}) ink) {
  expect(
    ink.blue.bottom,
    lessThanOrEqualTo(ink.red.top),
    reason: 'The reading must be above the base, rather than inline after it.',
  );
  expect(
    ink.blue.center.dx,
    closeTo(ink.red.center.dx, 1),
    reason: 'The reading must be horizontally centered over the base.',
  );
}

List<SemanticsNode> _semanticsNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node
        .debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        )
        .forEach(visit);
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

String _semanticsLabels(WidgetTester tester) =>
    _semanticsNodes(tester).map((node) => node.label).join('\n');

void main() {
  group('MfmText ruby', () {
    for (final example in [
      (name: 'rotated base', text: r'$[ruby $[fg.color=ff0000 $[rotate a]] あ]'),
      (
        name: 'animated base',
        text: r'$[ruby $[fg.color=ff0000 $[spin abc]] よみ]',
      ),
    ]) {
      testWidgets('places the reading above the ${example.name}', (
        tester,
      ) async {
        await tester.pumpWidget(_host(MfmText(text: example.text)));
        _expectReadingAboveBase(await _ink(tester));
      });
    }

    testWidgets('places the reading above a custom emoji image', (
      tester,
    ) async {
      final image = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(
          recorder,
        ).drawRect(const Rect.fromLTWH(0, 0, 20, 20), Paint()..color = _red);
        final picture = recorder.endRecording();
        try {
          return await picture.toImage(20, 20);
        } finally {
          picture.dispose();
        }
      }))!;
      try {
        await tester.pumpWidget(
          _host(
            MfmText(
              text: r'$[ruby :ruby_fixture: よみ]',
              config: MfmRenderConfig(
                emojiBuilder: (name, context) => RawImage(
                  image: image,
                  width: context.fontSize,
                  height: context.fontSize,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(RawImage), findsOneWidget);
        _expectReadingAboveBase(await _ink(tester));
      } finally {
        await tester.pumpWidget(const SizedBox());
        image.dispose();
      }
    });

    testWidgets('exposes both the linked base and reading in semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            MfmText(
              text: r'$[ruby [kanji](https://example.com/) yomi]',
              config: MfmRenderConfig(
                localHost: 'example.com',
                onLinkTap: (_) {},
              ),
            ),
          ),
        );
        expect(
          _semanticsLabels(tester),
          allOf(contains('kanji'), contains('yomi')),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('tapping the painted linked base invokes onLinkTap once', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          MfmText(
            text: r'$[ruby [kanji](https://example.com/) yomi]',
            config: MfmRenderConfig(
              localHost: 'example.com',
              onLinkTap: taps.add,
            ),
          ),
        ),
      );
      // The bottom quarter is inside the base, below the reading. The root
      // paragraph's public placeholder boxes locate the painted ruby region.
      final root = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(MfmText),
              matching: find.byType(RichText),
            )
            .first,
      );
      final ruby = root
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single
          .toRect();
      await tester.tapAt(
        root.localToGlobal(
          Offset(ruby.center.dx, ruby.bottom - ruby.height / 4),
        ),
      );
      expect(taps, ['https://example.com/']);
    });

    testWidgets('disposes painters after text/style replacement and unmount', (
      tester,
    ) async {
      final created = Set<TextPainter>.identity();
      final disposed = Set<TextPainter>.identity();
      void listener(ObjectEvent event) {
        final object = event.object;
        if (object is! TextPainter) return;
        if (event is ObjectCreated) created.add(object);
        if (event is ObjectDisposed && created.contains(object)) {
          disposed.add(object);
        }
      }

      FlutterMemoryAllocations.instance.addListener(listener);
      try {
        for (final example in [
          (text: r'$[ruby kanji yomi]', size: 20.0),
          (text: r'$[ruby changed reading]', size: 20.0),
          (text: r'$[ruby **changed** reading]', size: 28.0),
        ]) {
          await tester.pumpWidget(
            _host(
              MfmText(
                text: example.text,
                config: MfmRenderConfig(
                  baseTextStyle: _style.copyWith(fontSize: example.size),
                ),
              ),
            ),
          );
        }
        await tester.pumpWidget(const SizedBox());
        expect(
          created,
          isNotEmpty,
          reason: 'Allocation tracking must be active.',
        );
        expect(
          created.difference(disposed),
          isEmpty,
          reason:
              'Every TextPainter created during the ruby lifecycle must be '
              'disposed (${created.length} created, '
              '${disposed.length} disposed).',
        );
      } finally {
        try {
          await tester.pumpWidget(const SizedBox());
        } finally {
          FlutterMemoryAllocations.instance.removeListener(listener);
        }
      }
    });

    testWidgets('uses the same RTL base ordering as RichText', (tester) async {
      await tester.pumpWidget(
        _host(
          RichText(
            textDirection: TextDirection.rtl,
            text: const TextSpan(
              style: _style,
              children: [
                TextSpan(text: 'ab'),
                TextSpan(
                  text: '!',
                  style: TextStyle(color: _red),
                ),
              ],
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      final reference = await _ink(tester);
      final expected = reference.red.center.dx - reference.blue.center.dx;
      expect(
        expected,
        lessThan(0),
        reason: 'RTL puts the neutral ! before ab.',
      );

      await tester.pumpWidget(
        _host(
          const MfmText(
            text: r'$[ruby $[fg.color=0000ff ab]$[fg.color=ff0000 !] x]',
            config: MfmRenderConfig(
              baseTextStyle: TextStyle(
                fontFamily: 'Ahem',
                fontSize: 20,
                height: 1,
                color: Colors.green,
              ),
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      final actual = await _ink(tester);
      expect(
        actual.red.center.dx - actual.blue.center.dx,
        closeTo(expected, 1),
        reason: 'Ruby must follow the surrounding Directionality for its base.',
      );
    });

    for (final linked in [false, true]) {
      testWidgets('reads the base before the reading (linked: $linked)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _host(
              MfmText(
                text: linked
                    ? r'$[ruby [kanji](https://example.com/) yomi]'
                    : r'$[ruby kanji yomi]',
                config: MfmRenderConfig(
                  localHost: 'example.com',
                  onLinkTap: (_) {},
                ),
              ),
            ),
          );
          final labelled = _semanticsNodes(
            tester,
          ).where((node) => node.label.isNotEmpty).toList();
          expect(labelled.map((node) => node.label), ['kanji', 'yomi']);
          if (linked) {
            final base = labelled.first.getSemanticsData();
            expect(base.flagsCollection.isLink, isTrue);
            expect(base.hasAction(ui.SemanticsAction.tap), isTrue);
          }
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('taps both parts of an outer link once per tap', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          MfmText(
            text: r'[$[ruby kanji yomi]](https://example.com/)',
            config: MfmRenderConfig(
              localHost: 'example.com',
              onLinkTap: taps.add,
            ),
          ),
        ),
      );
      Finder textPart(String text) => find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      );
      await tester.tap(textPart('kanji'));
      expect(taps, ['https://example.com/']);
      await tester.tap(textPart('yomi'));
      expect(taps, ['https://example.com/', 'https://example.com/']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps dry sizes and baselines consistent with layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            child: MfmText(text: r'$[ruby abcdefghij yomi]'),
          ),
        ),
      );
      final rootFinder = find.byType(RichText).first;
      final root = tester.renderObject<RenderParagraph>(rootFinder);
      expect(root.getDryLayout(root.constraints), root.size);
      final rootSpan = tester.widget<RichText>(rootFinder).text as TextSpan;
      final rubySpan = rootSpan.children!.single as WidgetSpan;

      // Baselineが実layout中に問い合わせたbaselineを、子の配置から求める。
      const baseline = 100.0;
      await tester.pumpWidget(
        _host(
          Baseline(
            baseline: baseline,
            baselineType: TextBaseline.alphabetic,
            child: SizedBox(width: 60, child: rubySpan.child),
          ),
        ),
      );
      final rubyFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_MfmRubyLayout',
      );
      final ruby = tester.renderObject<RenderBox>(rubyFinder);
      final actualBaseline =
          baseline -
          (tester.getTopLeft(rubyFinder) -
                  tester.getTopLeft(find.byType(Baseline)))
              .dy;
      expect(ruby.size, const Size(60, 90));
      expect(ruby.getDryLayout(ruby.constraints), ruby.size);
      expect(
        ruby.getDryBaseline(ruby.constraints, TextBaseline.alphabetic),
        closeTo(actualBaseline, 1e-6),
      );
      expect(ruby.getMinIntrinsicWidth(double.infinity), 200);
      expect(ruby.getMaxIntrinsicWidth(double.infinity), 200);
      expect(ruby.getMinIntrinsicHeight(60), 90);
      expect(ruby.getMaxIntrinsicHeight(60), 90);

      // 別幅でのdry計測が、実layoutの寸法や配置を変更しないことも確認する。
      final actualPosition = tester.getTopLeft(rubyFinder);
      expect(
        ruby.getDryLayout(const BoxConstraints(maxWidth: 120)),
        const Size(120, 50),
      );
      ruby.getDryBaseline(
        const BoxConstraints(maxWidth: 120),
        TextBaseline.alphabetic,
      );
      expect(ruby.size, const Size(60, 90));
      expect(tester.getTopLeft(rubyFinder), actualPosition);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'scales both base and reading with MediaQuery TextScaler',
      (tester) async {
        const ruby = MfmText(text: r'$[ruby $[fg.color=ff0000 kanji] yomi]');
        await tester.pumpWidget(_host(ruby));
        final normal = await _ink(tester);
        await tester.pumpWidget(_host(ruby, scale: 2));
        final scaled = await _ink(tester);
        expect(
          [
            scaled.red.width,
            scaled.red.height,
            scaled.blue.width,
            scaled.blue.height,
          ],
          [
            greaterThan(normal.red.width),
            greaterThan(normal.red.height),
            greaterThan(normal.blue.width),
            greaterThan(normal.blue.height),
          ],
          reason: 'Both base and reading must grow with TextScaler.linear(2).',
        );
      },
      // 本文の TextScaler 設計が決まるまで保留
      skip: true,
    );
  });
}
