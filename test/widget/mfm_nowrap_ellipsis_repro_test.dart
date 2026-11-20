import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/utils/nowrap_paragraph.dart';

const _width = 200.0;
const _long = 'abcdefghijklmnopqrstuvwx';
const _short = 'abcd';
const _style = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 14,
  height: 1,
  color: Color(0xFF00FF00),
);

String _source(String effect, String content) =>
    effect == 'ruby' ? '\$[ruby $content reading]' : '\$[$effect $content]';

void main() {
  group('[7] nowrap ellipsis inline widget regression', () {
    for (final effect in ['rotate.deg=0', 'blur', 'border', 'ruby']) {
      testWidgets('$effect followed by tail keeps its painted contents', (
        tester,
      ) async {
        await _pump(tester, '${_source(effect, _long)} tail');
        await _expectVisibleInline(tester);
      });

      testWidgets('$effect alone keeps its painted contents', (tester) async {
        await _pump(tester, _source(effect, _long));
        await _expectVisibleInline(tester);
      });

      testWidgets('$effect and tail fitting within width stay visible', (
        tester,
      ) async {
        await _pump(tester, '${_source(effect, _short)} tail');
        await _expectVisibleInline(tester);
        expect(_root(tester).didExceedMaxLines, isFalse);
      });

      testWidgets('$effect and tail remain visible with nowrap false', (
        tester,
      ) async {
        await _pump(tester, '${_source(effect, _long)} tail', nowrap: false);
        await _expectVisibleInline(tester);
      });
    }

    testWidgets('tail alone paints without a placeholder', (tester) async {
      await _pump(tester, ' tail');
      expect(_root(tester).firstChild, isNull);
      expect(await _glyphPixels(tester), greaterThan(0));
      expect(_root(tester).didExceedMaxLines, isFalse);
    });

    testWidgets('long plain text still uses single line ellipsis', (
      tester,
    ) async {
      await _pump(tester, '$_long tail');
      final root = _root(tester);
      expect(root.overflow, TextOverflow.ellipsis);
      expect(root.size.height, 14);
      expect(root.didExceedMaxLines, isTrue);
      expect(_boxes(root, 0), isNotEmpty);
      expect(_boxes(root, _long.length - 1), isEmpty);
    });
  });

  group('[7] leading inline widget clipping', () {
    for (final direction in TextDirection.values) {
      for (final effect in ['rotate.deg=0', 'blur', 'border', 'ruby']) {
        testWidgets('$direction preserves the leading $effect and hides tail', (
          tester,
        ) async {
          await _pump(
            tester,
            '${_source(effect, _long)} tail',
            direction: direction,
          );
          final root = _root(tester);
          expect(root.overflow, TextOverflow.clip);
          expect(root.softWrap, isTrue);
          expect(root.maxLines, 1);
          expect(root.firstChild!.size.width, _width);
          expect(_inlineOffset(root), Offset.zero);
          _expectTailOutside(root, 1, 6);
          await _expectVisibleInline(tester);
          await tester.pump();
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(root.debugNeedsLayout, isFalse);
        });
      }

      for (final prefix in ['a ', ' ', '\u200b']) {
        testWidgets('$direction keeps ellipsis after prefix ${prefix.runes}', (
          tester,
        ) async {
          for (final effect in ['rotate.deg=0', 'blur', 'border', 'ruby']) {
            await _pump(
              tester,
              '$prefix${_source(effect, _long)} tail',
              direction: direction,
            );
            final root = _root(tester);
            expect(root.overflow, TextOverflow.ellipsis, reason: effect);
            expect(root.softWrap, isFalse);
            expect(root.maxLines, isNull);
            expect(_inlineOffset(root), isNull, reason: effect);
            expect(root.didExceedMaxLines, isTrue);
            expect(tester.takeException(), isNull);
          }
        });
      }

      testWidgets('$direction keeps ellipsis with a fitting emojiBuilder', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            MfmText(
              text: ':small: $_long',
              nowrap: true,
              config: MfmRenderConfig(
                emojiBuilder: (_, context) =>
                    SizedBox(width: context.fontSize, height: context.fontSize),
              ),
            ),
            direction: direction,
          ),
        );
        final root = _root(tester);
        expect(root.overflow, TextOverflow.ellipsis);
        expect(root.didExceedMaxLines, isTrue);
        expect(_inlineOffset(root), isNotNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$direction keeps long URL ellipsis', (tester) async {
        await _pump(
          tester,
          'https://example.com/a-very-long-path-that-must-not-wrap',
          direction: direction,
        );
        expect(_root(tester).overflow, TextOverflow.ellipsis);
        expect(_root(tester).maxLines, isNull);
        expect(_root(tester).didExceedMaxLines, isTrue);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$direction restores ellipsis as available width changes', (
        tester,
      ) async {
        const child = MfmText(
          text: r'$[rotate.deg=0 abcdefghijklmnopqrstuvwx] tail',
          nowrap: true,
        );
        RenderParagraph? previous;
        for (final width in [200.0, 500.0, 200.0]) {
          await tester.pumpWidget(
            _host(child, width: width, direction: direction),
          );
          final root = _root(tester);
          if (previous != null) expect(root, same(previous));
          previous = root;
          expect(
            root.overflow,
            width == 200 ? TextOverflow.clip : TextOverflow.ellipsis,
          );
          expect(root.maxLines, width == 200 ? 1 : isNull);
          expect(root.softWrap, width == 200);
          expect(_inlineOffset(root), isNotNull);
          await tester.pump();
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('tight constraints recheck independent inline state updates', (
      tester,
    ) async {
      final key = GlobalKey<_ResizableInlineState>();
      var builds = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 40,
            child: MfmText(
              text: ':changing: $_long',
              nowrap: true,
              config: MfmRenderConfig(
                emojiBuilder: (_, _) {
                  builds++;
                  return _ResizableInline(key: key);
                },
              ),
            ),
          ),
        ),
      );
      final root = _root(tester);
      expect(root.constraints.isTight, isTrue);
      expect(root.size, const Size(_width, 40));
      expect(
        tester.widget<RichText>(find.byType(RichText).first).runtimeType,
        RichText,
      );
      expect(root.overflow, TextOverflow.ellipsis);
      for (final width in [200.0, 20.0, 200.0]) {
        key.currentState!.setWidth(width);
        await tester.pump();
        expect(_root(tester), same(root));
        expect(
          root.overflow,
          width == 200 ? TextOverflow.clip : TextOverflow.ellipsis,
        );
        expect(root.size, const Size(_width, 40));
        expect(_inlineOffset(root), isNotNull);
        expect(builds, 1);
        await tester.pump();
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('tight constraints recheck RichText widget updates', (
      tester,
    ) async {
      final config = MfmRenderConfig(
        emojiBuilder: (_, _) => const SizedBox(width: _width, height: 14),
      );
      RenderParagraph? previous;
      for (final prefix in ['', 'a ', '']) {
        await tester.pumpWidget(
          _host(
            SizedBox(
              height: 40,
              child: MfmText(
                text: '$prefix:large: tail',
                nowrap: true,
                config: config,
              ),
            ),
          ),
        );
        final root = _root(tester);
        if (previous != null) expect(root, same(previous));
        previous = root;
        expect(root.constraints.isTight, isTrue);
        expect(root.size, const Size(_width, 40));
        expect(
          root.overflow,
          prefix.isEmpty ? TextOverflow.clip : TextOverflow.ellipsis,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('an earlier visible WidgetSpan prevents fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MfmText(
            text: ':small: ${_source('rotate.deg=0', _long)} tail',
            nowrap: true,
            config: MfmRenderConfig(
              emojiBuilder: (_, _) => const SizedBox(width: 14, height: 14),
            ),
          ),
        ),
      );
      final root = _root(tester);
      expect(root.overflow, TextOverflow.ellipsis);
      expect(_inlineOffset(root), isNotNull);
      expect(
        (root.childAfter(root.firstChild!)!.parentData! as TextParentData)
            .offset,
        isNull,
      );
    });

    testWidgets(
      'text metadata and literal placeholders do not change offsets',
      (
        tester,
      ) async {
        for (final prefix in ['😀', '\ufffc']) {
          await tester.pumpWidget(
            _host(
              _nowrapRichText(
                text: TextSpan(
                  style: _style,
                  children: [
                    TextSpan(text: prefix, semanticsLabel: ''),
                    const TextSpan(
                      children: [
                        WidgetSpan(
                          child: SizedBox(width: _width, height: 14),
                        ),
                        TextSpan(text: ' tail'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          expect(_root(tester).overflow, TextOverflow.ellipsis);
          expect(_inlineOffset(_root(tester)), isNull);
        }
      },
    );

    testWidgets('dry size, intrinsic dimensions and baselines agree', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        for (final loose in [false, true]) {
          final child = _MeasureBeforeLayout(
            child: _nowrapRichText(text: _measuredSpan),
          );
          for (final width in [200.0, 500.0, 200.0]) {
            await tester.pumpWidget(
              _host(
                loose
                    ? Align(alignment: Alignment.topLeft, child: child)
                    : child,
                width: width,
                direction: direction,
              ),
            );
            final measured = tester.renderObject<_MeasureBeforeLayoutBox>(
              find.byType(_MeasureBeforeLayout),
            );
            expect(measured.drySize, measured.size);
            expect(measured.intrinsicHeight, measured.size.height);
            expect(
              measured.dryBaseline,
              closeTo(measured.actualBaseline!, .01),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('two paragraph passes reuse the inline child layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _nowrapRichText(
            text: const TextSpan(
              style: _style,
              children: [
                WidgetSpan(
                  child: _CountLayout(
                    child: SizedBox(width: _width, height: 14),
                  ),
                ),
                TextSpan(text: ' tail'),
              ],
            ),
          ),
        ),
      );
      final counter = tester.renderObject<_CountLayoutBox>(
        find.byType(_CountLayout),
      );
      expect(_root(tester).overflow, TextOverflow.clip);
      expect(counter.layouts, 1);
      await tester.pump();
      expect(counter.layouts, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('rescued widgets receive pointer and semantics actions', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      const key = ValueKey('rescued inline');
      try {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            _host(
              MfmText(
                text: ':large: tail',
                nowrap: true,
                config: MfmRenderConfig(
                  emojiBuilder: (_, _) => Semantics(
                    key: key,
                    label: 'rescued inline',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => taps++,
                      child: const SizedBox(width: _width, height: 20),
                    ),
                  ),
                ),
              ),
              direction: direction,
            ),
          );
          final root = _root(tester);
          expect(root.overflow, TextOverflow.clip);
          final hits = BoxHitTestResult();
          expect(root.hitTest(hits, position: const Offset(25, 10)), isTrue);
          expect(hits.path.length, greaterThan(1));
          final previous = taps;
          await tester.tapAt(root.localToGlobal(const Offset(25, 10)));
          expect(taps, previous + 1);
          final node = tester.getSemantics(find.byKey(key));
          expect(node.getSemanticsData().label, contains('rescued inline'));
          expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
            isTrue,
          );
          root.owner!.semanticsOwner!.performAction(
            node.id,
            ui.SemanticsAction.tap,
          );
          expect(taps, previous + 2);
          expect(tester.takeException(), isNull);
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'selection stays registered across fallback and width changes',
      (
        tester,
      ) async {
        final registrar = _Registrar();
        final child = _nowrapRichText(
          text: _measuredSpan,
          selectionRegistrar: registrar,
          selectionColor: const Color(0xFF123456),
        );
        for (final width in [200.0, 500.0, 200.0]) {
          await tester.pumpWidget(_host(child, width: width));
          expect(registrar.selectables, hasLength(1));
          registrar.selectables.single.dispatchSelectionEvent(
            const SelectAllSelectionEvent(),
          );
          await tester.pump();
          expect(
            registrar.selectables.single.getSelectedContent()!.plainText,
            ' tail',
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('root paragraphs inherit the ambient locale on updates', (
      tester,
    ) async {
      const child = MfmText(text: 'abc', nowrap: true);
      for (final language in ['ja', 'fr']) {
        await tester.pumpWidget(
          _host(
            Localizations(
              locale: Locale(language),
              delegates: const [DefaultWidgetsLocalizations.delegate],
              child: child,
            ),
          ),
        );
        expect(_root(tester).locale, Locale(language));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('RichText properties and selection registrations update', (
      tester,
    ) async {
      final first = _Registrar();
      final second = _Registrar();
      const strut = StrutStyle(fontSize: 20, forceStrutHeight: true);
      const height = ui.TextHeightBehavior(applyHeightToFirstAscent: false);
      for (final update in [false, true]) {
        final registrar = update ? second : first;
        await tester.pumpWidget(
          _host(
            _nowrapRichText(
              text: const TextSpan(text: 'abc', style: _style),
              textAlign: update ? TextAlign.end : TextAlign.center,
              textDirection: update ? TextDirection.ltr : TextDirection.rtl,
              textScaler: TextScaler.linear(update ? 2 : 1.5),
              locale: Locale(update ? 'fr' : 'ja'),
              strutStyle: strut,
              textWidthBasis: TextWidthBasis.longestLine,
              textHeightBehavior: height,
              selectionRegistrar: registrar,
              selectionColor: const Color(0xFF123456),
            ),
          ),
        );
        final root = _root(tester);
        expect(root.textAlign, update ? TextAlign.end : TextAlign.center);
        expect(
          root.textDirection,
          update ? TextDirection.ltr : TextDirection.rtl,
        );
        expect(root.textScaler, TextScaler.linear(update ? 2 : 1.5));
        expect(root.locale, Locale(update ? 'fr' : 'ja'));
        expect(root.strutStyle, strut);
        expect(root.textWidthBasis, TextWidthBasis.longestLine);
        expect(root.textHeightBehavior, height);
        expect(root.registrar, same(registrar));
        expect(root.selectionColor, const Color(0xFF123456));
        expect(registrar.selectables, hasLength(1));
        registrar.selectables.single.dispatchSelectionEvent(
          const SelectAllSelectionEvent(),
        );
        expect(
          registrar.selectables.single.getSelectedContent()!.plainText,
          'abc',
        );
        if (update) expect(first.selectables, isEmpty);
        expect(tester.takeException(), isNull);
      }
    });
  });
}

Widget _host(
  Widget child, {
  double width = _width,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: DefaultTextStyle(
      style: _style,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: RepaintBoundary(child: child),
        ),
      ),
    ),
  ),
);

Widget _nowrapRichText({
  required InlineSpan text,
  TextAlign textAlign = TextAlign.start,
  TextDirection? textDirection,
  TextScaler textScaler = TextScaler.noScaling,
  Locale? locale,
  StrutStyle? strutStyle,
  TextWidthBasis textWidthBasis = TextWidthBasis.parent,
  ui.TextHeightBehavior? textHeightBehavior,
  SelectionRegistrar? selectionRegistrar,
  Color? selectionColor,
}) => MfmNowrapParagraph(
  child: RichText(
    text: text,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    textAlign: textAlign,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
    strutStyle: strutStyle,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionRegistrar: selectionRegistrar,
    selectionColor: selectionColor,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  String text, {
  bool nowrap = true,
  TextDirection direction = TextDirection.ltr,
}) => tester.pumpWidget(
  _host(
    MfmText(
      text: text,
      nowrap: nowrap,
      config: const MfmRenderConfig(enableAnimation: false),
    ),
    direction: direction,
  ),
);

RenderParagraph _root(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(find.byType(RichText).first);

List<ui.TextBox> _boxes(RenderParagraph paragraph, int offset) =>
    paragraph.getBoxesForSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + 1),
    );

Future<void> _expectVisibleInline(WidgetTester tester) async {
  final root = _root(tester);
  final child = root.firstChild!;
  // A laid-out RichText and nonempty child glyph boxes do not prove painting:
  // RenderParagraph skips children with a null TextParentData offset.
  // Check both placement and actual green glyph pixels. Ruby paints through
  // its own RenderBox/TextPainters, so it has no child RichText to find.
  final offset = (child.parentData! as TextParentData).offset;
  final pixels = await _glyphPixels(tester);
  expect(
    (hasPlaceholderBox: _boxes(root, 0).isNotEmpty, positioned: offset != null),
    (hasPlaceholderBox: true, positioned: true),
    reason: 'inline size=${child.size}; offset=$offset; glyph pixels=$pixels',
  );
  expect(pixels, greaterThan(0), reason: 'inline content must actually paint');
  expect(tester.takeException(), isNull);
}

Future<int> _glyphPixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      ))!.buffer.asUint8List();
      var count = 0;
      for (var y = 0; y < image.height; y++) {
        // The first ellipsis occupies x=0..14 and short inline text ends at
        // x>=56. Sampling x=20..39 excludes both a lone ellipsis and the tail.
        for (var x = 20; x < 40; x++) {
          final index = (y * image.width + x) * 4;
          if (bytes[index + 1] > bytes[index] * 2 &&
              bytes[index + 1] > bytes[index + 2] * 2 &&
              bytes[index + 3] > 0) {
            count++;
          }
        }
      }
      return count;
    } finally {
      image.dispose();
    }
  }))!;
}

Offset? _inlineOffset(RenderParagraph paragraph) =>
    (paragraph.firstChild!.parentData! as TextParentData).offset;

void _expectTailOutside(RenderParagraph paragraph, int start, int end) {
  final bounds = Offset.zero & paragraph.size;
  for (final box in paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  )) {
    expect(box.toRect().intersect(bounds).isEmpty, isTrue);
  }
}

const _measuredSpan = TextSpan(
  style: _style,
  children: [
    WidgetSpan(
      child: SizedBox(width: _width, height: 40),
    ),
    TextSpan(text: ' tail'),
  ],
);

class _MeasureBeforeLayout extends SingleChildRenderObjectWidget {
  const _MeasureBeforeLayout({required super.child});

  @override
  _MeasureBeforeLayoutBox createRenderObject(BuildContext context) =>
      _MeasureBeforeLayoutBox();
}

class _MeasureBeforeLayoutBox extends RenderProxyBox {
  Size? drySize;
  double? dryBaseline;
  double? actualBaseline;
  double? intrinsicHeight;

  @override
  void performLayout() {
    drySize = child!.getDryLayout(constraints);
    dryBaseline = child!.getDryBaseline(constraints, TextBaseline.alphabetic);
    intrinsicHeight = child!.getMinIntrinsicHeight(constraints.maxWidth);
    final minimum = child!.getMinIntrinsicWidth(double.infinity);
    final maximum = child!.getMaxIntrinsicWidth(double.infinity);
    super.performLayout();
    actualBaseline = child!.getDistanceToBaseline(TextBaseline.alphabetic);
    expect(child!.getMinIntrinsicWidth(double.infinity), minimum);
    expect(child!.getMaxIntrinsicWidth(double.infinity), maximum);
    expect(child!.getMaxIntrinsicHeight(constraints.maxWidth), intrinsicHeight);
  }
}

class _CountLayout extends SingleChildRenderObjectWidget {
  const _CountLayout({required super.child});

  @override
  _CountLayoutBox createRenderObject(BuildContext context) => _CountLayoutBox();
}

class _CountLayoutBox extends RenderProxyBox {
  int layouts = 0;

  @override
  void performLayout() {
    layouts++;
    super.performLayout();
  }
}

class _Registrar implements SelectionRegistrar {
  final selectables = <Selectable>{};

  @override
  void add(Selectable selectable) => selectables.add(selectable);

  @override
  void remove(Selectable selectable) => selectables.remove(selectable);
}

class _ResizableInline extends StatefulWidget {
  const _ResizableInline({super.key});

  @override
  State<_ResizableInline> createState() => _ResizableInlineState();
}

class _ResizableInlineState extends State<_ResizableInline> {
  double _width = 20;

  void setWidth(double value) => setState(() => _width = value);

  @override
  Widget build(BuildContext context) => SizedBox(width: _width, height: 14);
}
