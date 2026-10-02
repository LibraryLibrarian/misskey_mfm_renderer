import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/mfm_border_options.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_border.dart';

const _red = Color(0xFFFF0000);
const _style = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 20,
  height: 1,
  color: Color(0xFF222222),
);
MfmBorderOptions _options(Map<String, dynamic> args) =>
    MfmBorderOptions.resolve(args, _red);

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: child),
);
Widget _text(
  String text, {
  bool nowrap = false,
  double scale = 1,
  MfmRenderConfig? config,
}) => _host(
  MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: MfmText(
      text: text,
      nowrap: nowrap,
      config:
          config ??
          const MfmRenderConfig(baseTextStyle: _style, enableAnimation: false),
    ),
  ),
);

Future<Uint8List> _paint(
  WidgetTester tester,
  Map<String, dynamic> args, {
  Size size = const Size(100, 60),
}) async {
  return (await tester.runAsync(() async {
    final options = _options(args);
    final recorder = ui.PictureRecorder();
    MfmBorderDecoration(
        options: options,
        color: options.color,
      ).createBoxPainter()
      ..paint(
        Canvas(recorder),
        Offset.zero,
        ImageConfiguration(size: size),
      )
      ..dispose();
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      return Uint8List.fromList(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
      picture.dispose();
    }
  }))!;
}

List<int> _pixel(Uint8List data, int x, int y, [int width = 100]) =>
    data.sublist((y * width + x) * 4, (y * width + x) * 4 + 4);

void main() {
  test('pattern budget is checked before rounding or integer conversion', () {
    final geometry = MfmBorderGeometry(const Size(100, 60), 1, 0);
    for (final dotted in [true, false]) {
      final factor = dotted ? 2 : 6;
      expect(geometry.patternCount(2047.9 * factor, dotted: dotted), 2048);
      expect(
        geometry.patternCount(2048 * factor.toDouble(), dotted: dotted),
        2048,
      );
      expect(geometry.patternCount(2048.1 * factor, dotted: dotted), isNull);
      expect(geometry.patternCount(0.1, dotted: dotted), 1);
      for (final length in [0.0, -1.0, double.infinity, double.nan, 1e300]) {
        expect(geometry.patternCount(length, dotted: dotted), isNull);
      }
    }
  });

  test(
    'geometry normalizes outer radius first and safely collapses inner bounds',
    () {
      final geometry = MfmBorderGeometry(const Size(100, 40), 8, 1e300);
      expect(geometry.boundary(0)!.tlRadiusX, 20);
      expect(geometry.boundary(8)!.tlRadiusX, 12);
      expect(geometry.innerBounds, const Rect.fromLTRB(8, 8, 92, 32));
      expect(geometry.path(8).contains(const Offset(9, 9)), isFalse);
      for (final size in [
        Size.zero,
        const Size(-1, 20),
        const Size(double.infinity, 20),
        const Size(double.nan, 20),
      ]) {
        final bad = MfmBorderGeometry(size, 3, 10);
        expect(bad.path(0).getBounds(), Rect.zero);
        expect(bad.innerBounds, Rect.zero);
      }
      for (final width in [20.0, 21.0, 1024.0]) {
        final thick = MfmBorderGeometry(const Size(30, 40), width, 30);
        expect(thick.innerBounds, Rect.zero);
        expect(thick.path(width).contains(const Offset(15, 20)), isFalse);
      }
      final decoration = MfmBorderDecoration(
        options: _options({'radius': 10, 'width': 8}),
        color: _red,
      );
      expect(decoration.padding, EdgeInsets.zero);
      final outer = decoration.getClipPath(
        const Rect.fromLTWH(10, 20, 100, 60),
        TextDirection.ltr,
      );
      expect(outer.contains(const Offset(60, 21)), isTrue);
      final clipper = MfmBorderClipper(decoration.options);
      expect(
        clipper.getApproximateClipRect(const Size(100, 60)),
        const Rect.fromLTRB(8, 8, 92, 52),
      );
      expect(
        clipper.getClip(const Size(100, 60)).contains(const Offset(50, 1)),
        isFalse,
      );
    },
  );

  testWidgets(
    'parser inputs reserve border width once; invalid/hidden/zero none',
    (tester) async {
      for (final entry in <String, double>{
        '': 1,
        '.width=12abc': 12,
        '.width=1e1': 10,
        '.width=0': 0,
        '.style=hidden,width=6': 0,
        '.width=-1': 0,
        '.width=Infinity': 0,
        '.color=abcde,width=6': 0,
        '.color=zzzzz,width=6': 6,
        '.color=f000,width=6': 6,
      }.entries) {
        await tester.pumpWidget(_text('\$[border${entry.key} X]'));
        expect(
          tester.getSize(find.byType(MfmBorder)),
          Size(20 + 2 * entry.value, 20 + 2 * entry.value),
          reason: entry.key,
        );
        expect(tester.takeException(), isNull);
      }
      for (final flag in ['noclip', 'noclip=false', 'noclip=0']) {
        await tester.pumpWidget(_text('\$[border.$flag X]'));
        expect(
          tester.widget<MfmBorder>(find.byType(MfmBorder)).options.noclip,
          isTrue,
        );
      }
    },
  );

  testWidgets('inner clip protects the border; noclip paints child over it', (
    tester,
  ) async {
    const boundaryKey = ValueKey('clip-pixels');
    for (final noclip in [false, true, false]) {
      await tester.pumpWidget(
        _host(
          RepaintBoundary(
            key: boundaryKey,
            child: MfmBorder(
              options: _options({'width': 8, 'radius': 12, 'noclip': noclip}),
              color: _red,
              child: Transform.translate(
                offset: const Offset(-6, 0),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: ColoredBox(color: Color(0xFF0000FF)),
                ),
              ),
            ),
          ),
        ),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final pixel = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          return _pixel(bytes!.buffer.asUint8List(), 4, 20, 40);
        } finally {
          image.dispose();
        }
      }))!;
      expect(pixel, noclip ? [0, 0, 255, 255] : [255, 0, 0, 255]);
    }
  });

  testWidgets('direct AST values are resolved without stringifying objects', (
    tester,
  ) async {
    for (final entry in <Object?, double>{
      12: 12,
      true: 1,
      double.nan: 1,
      double.infinity: 0,
      '-0': 0,
      <int>[]: 1,
    }.entries) {
      await tester.pumpWidget(
        _host(
          MfmText(
            parsedNodes: [
              FnNode(
                name: 'border',
                args: {'width': entry.key, 'noclip': false},
                children: const [TextNode('X')],
              ),
            ],
            config: const MfmRenderConfig(baseTextStyle: _style),
          ),
        ),
      );
      final border = tester.widget<MfmBorder>(find.byType(MfmBorder));
      expect(border.options.width, entry.value);
      expect(border.options.noclip, isFalse);
    }
  });

  testWidgets('zero, hidden, invalid and transparent never paint a hairline', (
    tester,
  ) async {
    for (final args in <Map<String, dynamic>>[
      {'width': 0},
      {'width': 8, 'style': 'hidden'},
      {'width': -1},
      {'color': 'abcde'},
      {'width': 8, 'color': 'f000'},
    ]) {
      final pixels = await _paint(tester, args);
      expect(pixels.whereIndexedAlpha(), everyElement(0));
    }
  });

  testWidgets(
    'all styles paint bounded rings; double threshold and thin strokes',
    (tester) async {
      for (final style in MfmBorderStyle.values.where(
        (s) => s != MfmBorderStyle.hidden,
      )) {
        final pixels = await _paint(tester, {
          'style': style.name,
          'width': 9,
          'radius': 18,
        });
        expect(
          pixels.whereIndexedAlpha().any((a) => a > 0),
          isTrue,
          reason: style.name,
        );
        expect(_pixel(pixels, 50, 30)[3], 0);
        expect(_pixel(pixels, 0, 0)[3], 0);
      }
      for (final width in [0.25, 0.5, 1.0, 2.999, 3.0, 3.001]) {
        final pixels = await _paint(tester, {
          'style': 'double',
          'width': width,
        });
        final solid = await _paint(tester, {'width': width});
        if (width < 3) {
          expect(pixels, solid);
        } else {
          expect(_pixel(pixels, 50, 1)[3], 0);
          expect(_pixel(pixels, 50, 0)[3], greaterThan(240));
          expect(_pixel(pixels, 50, 2)[3], greaterThan(240));
        }
      }
    },
  );

  testWidgets(
    'patterns are deterministic, bounded and solid on degenerate centerlines',
    (tester) async {
      for (final style in ['dotted', 'dashed']) {
        final first = await _paint(tester, {
          'style': style,
          'width': 3,
          'radius': 12,
        });
        expect(
          await _paint(tester, {'style': style, 'width': 3, 'radius': 12}),
          first,
        );
        final alphas = [for (var x = 15; x < 85; x++) _pixel(first, x, 1)[3]];
        expect(alphas.any((a) => a == 0), isTrue);
        expect(alphas.any((a) => a > 200), isTrue);
        for (final width in [1e-300, 60.0, 1023.9, 1024.0, 1024.1, 1e300]) {
          expect(
            await _paint(tester, {'style': style, 'width': width}),
            await _paint(tester, {'width': width}),
          );
        }
        // For a square r=0 centerline: L = 400 - 4w. L/(factor*w)=budget.
        final factor = style == 'dotted' ? 2 : 6;
        for (final budget in [2047.0, 2048.0, 2049.0]) {
          final width = 400 / (factor * budget + 4);
          final pixels = await _paint(tester, {
            'style': style,
            'width': width,
          }, size: const Size(100, 100));
          expect(pixels, hasLength(40000));
          if (budget == 2049) {
            expect(
              pixels,
              await _paint(tester, {
                'width': width,
              }, size: const Size(100, 100)),
            );
          }
        }
      }
    },
  );

  testWidgets('3D orientation, alpha and exclusive diagonal/middle seams', (
    tester,
  ) async {
    for (final color in ['8088', '0008', 'fff8']) {
      for (final style in ['inset', 'outset', 'groove', 'ridge']) {
        final pixels = await _paint(tester, {
          'style': style,
          'width': 12,
          'color': color,
        });
        final top = _pixel(pixels, 50, 2);
        final bottom = _pixel(pixels, 50, 57);
        expect(top[3], closeTo(136, 1));
        expect(bottom[3], closeTo(136, 1));
        final darkTop = style == 'inset' || style == 'groove';
        expect(top[0] < bottom[0], darkTop, reason: '$style $color');
        if (style == 'groove' || style == 'ridge') {
          final innerTop = _pixel(pixels, 50, 9);
          expect(innerTop[0] > top[0], darkTop);
        }
        // All interior ring pixels, including joins, have exactly one alpha.
        for (var y = 1; y < 59; y++) {
          for (var x = 1; x < 99; x++) {
            if (x < 12 || x >= 88 || y < 12 || y >= 48) {
              expect(
                _pixel(pixels, x, y)[3],
                closeTo(136, 1),
                reason: '$style ($x,$y)',
              );
            }
          }
        }
      }
    }
  });

  testWidgets('rounded fractional 3D bands retain solid alpha coverage', (
    tester,
  ) async {
    // Keep the assertion away from exterior AA coverage: Canvas.clipPath and
    // drawPath need not quantize their edge coverage identically.
    final interior = MfmBorderGeometry(
      const Size(100, 60),
      9.5,
      18,
    ).ring(1, 8.5);
    for (final style in ['inset', 'outset', 'groove', 'ridge']) {
      final pixels = await _paint(tester, {
        'style': style,
        'width': 9.5,
        'radius': 18,
        'color': '8088',
      });
      for (var i = 3; i < pixels.length; i += 4) {
        expect(pixels[i], lessThanOrEqualTo(137));
        final index = i ~/ 4;
        if (interior.contains(Offset(index % 100 + 0.5, index ~/ 100 + 0.5))) {
          expect(pixels[i], closeTo(136, 1), reason: '$style alpha byte $i');
        }
      }
    }
  });

  testWidgets('updates preserve child state and restore clip hit filtering', (
    tester,
  ) async {
    final key = GlobalKey<_StatefulChildState>();
    var taps = 0;
    Future<void> pump({
      required bool noclip,
      String style = 'solid',
      double width = 10,
      double radius = 0,
      String color = 'f00',
    }) => tester.pumpWidget(
      _host(
        MfmBorder(
          options: _options({
            'noclip': noclip,
            'style': style,
            'width': width,
            'radius': radius,
            'color': color,
          }),
          color: _red,
          child: Transform.translate(
            offset: const Offset(-8, 0),
            child: _StatefulChild(key: key, onTap: () => taps++),
          ),
        ),
      ),
    );
    await pump(noclip: false);
    final state = key.currentState;
    final point =
        tester.getTopLeft(find.byType(MfmBorder)) + const Offset(5, 20);
    await tester.tapAt(point);
    expect(taps, 0);
    await pump(noclip: true, style: 'dashed', radius: 15, color: '00f');
    expect(key.currentState, same(state));
    final clip = tester.widget<ClipPath>(find.byType(ClipPath));
    expect(clip.clipper, isNull);
    expect(clip.clipBehavior, Clip.none);
    await tester.tapAt(point);
    expect(taps, 1);
    await pump(noclip: false, style: 'double', width: 11, radius: 16);
    expect(key.currentState, same(state));
    await tester.tapAt(
      tester.getTopLeft(find.byType(MfmBorder)) + const Offset(5, 20),
    );
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'natural glyph baseline and existing inline scaling/wrapping survive',
    (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        for (final nowrap in [false, true]) {
          await tester.pumpWidget(
            _text(r'A$[border.width=6 X]Z', scale: scale, nowrap: nowrap),
          );
          final paragraphs = tester
              .renderObjectList<RenderParagraph>(find.byType(RichText))
              .toList();
          final outer = paragraphs.first;
          final inner = paragraphs.last;
          final outerBaseline = outer
              .localToGlobal(
                Offset(
                  0,
                  outer.getDryBaseline(
                    outer.constraints,
                    TextBaseline.alphabetic,
                  )!,
                ),
              )
              .dy;
          final innerBaseline = inner
              .localToGlobal(
                Offset(
                  0,
                  inner.getDryBaseline(
                    inner.constraints,
                    TextBaseline.alphabetic,
                  )!,
                ),
              )
              .dy;
          expect(innerBaseline, closeTo(outerBaseline, 0.001));
          final glyph = inner
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .single;
          final adjacent = outer
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .single;
          expect(
            inner.localToGlobal(Offset(0, glyph.bottom)).dy,
            closeTo(outer.localToGlobal(Offset(0, adjacent.bottom)).dy, 0.001),
          );
          expect(glyph.bottom - glyph.top, greaterThan(0));
          expect(tester.takeException(), isNull);
        }
      }
      for (final width in [45.0, 200.0, double.infinity]) {
        await tester.pumpWidget(
          _host(
            UnconstrainedBox(
              child: SizedBox(
                width: width.isFinite ? width : null,
                child: const MfmText(
                  text: '\$[border.width=3 A B\nC D]',
                  config: MfmRenderConfig(baseTextStyle: _style),
                ),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(MfmBorder)).isFinite, isTrue);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'links retain callbacks and semantics; flags do not disable borders',
    (tester) async {
      String? tapped;
      await tester.pumpWidget(
        _text(
          r'$[border.style=dashed,width=4 https://example.test]',
          config: MfmRenderConfig(
            baseTextStyle: _style,
            enableAdvancedMfm: false,
            enableAnimation: false,
            onLinkTap: (url) => tapped = url,
          ),
        ),
      );
      expect(find.semantics.byLabel('example.test'), findsOne);
      final link = find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().startsWith('https://example.test'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(link);
      final glyph = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single;
      final point = paragraph.localToGlobal(glyph.toRect().center);
      await tester.tapAt(point);
      expect(tapped, 'https://example.test');
      expect(
        tester.widget<MfmBorder>(find.byType(MfmBorder)).options.style,
        MfmBorderStyle.dashed,
      );
    },
  );

  testWidgets('noclip toggles transformed URL hits inside the border bounds', (
    tester,
  ) async {
    var taps = 0;
    var expectedTaps = 0;
    for (final noclip in [false, true, false]) {
      await tester.pumpWidget(
        _host(
          MfmBorder(
            options: _options({'width': 10, 'noclip': noclip}),
            color: _red,
            child: Transform.translate(
              offset: const Offset(-8, 0),
              child: MfmText(
                text: 'https://example.test',
                config: MfmRenderConfig(
                  baseTextStyle: _style,
                  onLinkTap: (_) => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      final point =
          tester.getTopLeft(find.byType(MfmBorder)) + const Offset(5, 20);
      await tester.tapAt(point);
      if (noclip) expectedTaps++;
      expect(taps, expectedTaps);
    }
    expect(taps, 1);
  });

  testWidgets(
    'RGBA small/quote opacity does not mutate a shared foreground Paint',
    (tester) async {
      final paint = Paint()..color = const Color(0xCC123456);
      final original = paint.color;
      await tester.pumpWidget(
        _text(
          '> <small>\$[border.color=f008,width=4 X]</small>',
          config: MfmRenderConfig(
            baseTextStyle: TextStyle(fontSize: 20, foreground: paint),
          ),
        ),
      );
      final border = tester.widget<MfmBorder>(find.byType(MfmBorder));
      expect(border.color.a, closeTo(136 / 255 * 0.49, 0.00001));
      expect(paint.color, original);
      expect(
        find.ancestor(
          of: find.byType(MfmBorder),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    },
  );
}

extension on Uint8List {
  Iterable<int> whereIndexedAlpha() sync* {
    for (var i = 3; i < length; i += 4) {
      yield this[i];
    }
  }
}

class _StatefulChild extends StatefulWidget {
  const _StatefulChild({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  State<_StatefulChild> createState() => _StatefulChildState();
}

class _StatefulChildState extends State<_StatefulChild> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    behavior: HitTestBehavior.opaque,
    child: const SizedBox(width: 30, height: 30),
  );
}
