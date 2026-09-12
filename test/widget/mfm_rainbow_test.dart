import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_animated_wrapper.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_widget.dart';

const _identity = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

const _quarterTurn = <double>[
  0,
  0,
  1,
  0,
  0,
  0.356,
  0.855,
  -0.211,
  0,
  0,
  -0.574,
  1.43,
  0.144,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

Widget _host(String text) => MaterialApp(
  home: Scaffold(body: MfmText(text: text)),
);

List<ColorFiltered> _filters(WidgetTester tester) =>
    tester.widgetList<ColorFiltered>(find.byType(ColorFiltered)).toList();

// ColorFilter は係数の getter を持たないため、診断表現から取り出す。
// 行列 helper をテストのために公開 API にしない。
List<double> _matrix(ColorFilter filter) {
  final match = RegExp(
    r'^ColorFilter.matrix\(\[(.*)\]\)$',
  ).firstMatch(filter.toString());
  expect(match, isNotNull);
  final values = match!.group(1)!.split(',').map(double.parse).toList();
  expect(values, hasLength(20));
  return values;
}

void _expectMatrix(List<double> actual, List<double> expected) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], 1e-12), reason: 'matrix[$i]');
  }
}

List<double> _applyMatrix(List<double> matrix, List<double> rgba) =>
    List.generate(4, (row) {
      var result = matrix[row * 5 + 4];
      for (var col = 0; col < 4; col++) {
        result += matrix[row * 5 + col] * rgba[col];
      }
      return result;
    });

Future<List<int>> _pixelAt(
  WidgetTester tester,
  Finder boundaryFinder, {
  int x = 5,
  int y = 5,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      final offset = (y * image.width + x) * 4;
      return bytes!.buffer
          .asUint8List(bytes.offsetInBytes + offset, 4)
          .toList();
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  group('rainbow フィルタ行列', () {
    final cases = <String, (double, List<double>)>{
      '0で恒等': (0, _identity),
      '2πで恒等': (1, _identity),
      'πで既知の係数': (
        0.5,
        <double>[
          -0.574,
          1.43,
          0.144,
          0,
          0,
          0.426,
          0.43,
          0.144,
          0,
          0,
          0.426,
          1.43,
          -0.856,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ],
      ),
      'π/2で既知の係数': (0.25, _quarterTurn),
    };
    for (final entry in cases.entries) {
      testWidgets('hue-rotateは${entry.key}', (tester) async {
        await tester.pumpWidget(_host(r'$[rainbow text]'));
        final wrapper = tester.widget<MfmAnimatedWrapper>(
          find.byType(MfmAnimatedWrapper),
        );
        final controller = AnimationController(vsync: tester);
        addTearDown(controller.dispose);
        // repeat が1を0に戻す前の終端も、実装の builder を通して検証する。
        final saturation =
            wrapper.builder(
                  tester.element(find.byType(MfmAnimatedWrapper)),
                  wrapper.child,
                  controller,
                  AlwaysStoppedAnimation(entry.value.$1),
                )
                as ColorFiltered;
        final contrast = saturation.child! as ColorFiltered;
        final hue = contrast.child! as ColorFiltered;
        _expectMatrix(_matrix(hue.colorFilter), entry.value.$2);
      });
    }

    testWidgets('外からsaturate・contrast・hueの3段でalphaを保持する', (tester) async {
      await tester.pumpWidget(_host(r'$[rainbow text]'));
      final filters = _filters(tester);
      expect(filters, hasLength(3));
      expect(filters[0].child, same(filters[1]));
      expect(filters[1].child, same(filters[2]));
      _expectMatrix(_matrix(filters[0].colorFilter), <double>[
        1.3935,
        -0.3575,
        -0.036,
        0,
        0,
        -0.1065,
        1.1425,
        -0.036,
        0,
        0,
        -0.1065,
        -0.3575,
        1.464,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
      _expectMatrix(_matrix(filters[1].colorFilter), <double>[
        1.5,
        0,
        0,
        0,
        -63.75,
        0,
        1.5,
        0,
        0,
        -63.75,
        0,
        0,
        1.5,
        0,
        -63.75,
        0,
        0,
        0,
        1,
        0,
      ]);
      _expectMatrix(_matrix(filters[2].colorFilter), _identity);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final advanced = _filters(tester);
      expect(advanced[0].colorFilter, same(filters[0].colorFilter));
      expect(advanced[1].colorFilter, same(filters[1].colorFilter));
      for (final filter in advanced) {
        expect(_matrix(filter.colorFilter).sublist(15), <double>[
          0,
          0,
          0,
          1,
          0,
        ]);
      }
    });

    testWidgets('hueとsaturateは無彩色を着色しない', (tester) async {
      await tester.pumpWidget(_host(r'$[rainbow text]'));
      await tester.pump();
      for (final elapsed in [0, 123, 127, 250, 350]) {
        await tester.pump(Duration(milliseconds: elapsed));
        final filters = _filters(tester);
        for (final gray in [0.0, 103.0, 128.0, 255.0]) {
          for (final alpha in [0.0, 179.0, 255.0]) {
            final rgba = [gray, gray, gray, alpha];
            for (final filter in [filters.first, filters.last]) {
              _expectMatrix(
                _applyMatrix(_matrix(filter.colorFilter), rgba),
                rgba,
              );
            }
          }
        }
      }
    });
  });

  group('rainbow 時刻とフォールバック', () {
    for (final seconds in [1, 2]) {
      testWidgets('speed=${seconds}sで等速に一周する', (tester) async {
        await tester.pumpWidget(_host('\$[rainbow.speed=${seconds}s text]'));
        await tester.pump();
        final quarter = Duration(milliseconds: seconds * 250);
        final initial = _filters(tester).last.colorFilter;
        await tester.pump(quarter);
        _expectMatrix(_matrix(_filters(tester).last.colorFilter), _quarterTurn);
        expect(_filters(tester).last.colorFilter, isNot(initial));
        await tester.pump(quarter * 3);
        _expectMatrix(_matrix(_filters(tester).last.colorFilter), _identity);
        await tester.pump(quarter);
        _expectMatrix(_matrix(_filters(tester).last.colorFilter), _quarterTurn);
      });
    }

    testWidgets('既定周期は1秒で負delayの位相が繰り返し後も続く', (tester) async {
      await tester.pumpWidget(_host(r'$[rainbow.delay=-0.25s text]'));
      expect(
        tester
            .widget<MfmAnimatedWrapper>(find.byType(MfmAnimatedWrapper))
            .duration,
        const Duration(seconds: 1),
      );
      _expectMatrix(_matrix(_filters(tester).last.colorFilter), _quarterTurn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      _expectMatrix(_matrix(_filters(tester).last.colorFilter), _quarterTurn);
    });

    testWidgets('正delayの終了まではfilterを掛けず元の子を表示する', (tester) async {
      const child = Text('red', style: TextStyle(color: Colors.red));
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MfmRainbowWidget(
            delay: Duration(milliseconds: 500),
            child: child,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.widget(find.text('red')), same(child));
      await tester.pump(const Duration(milliseconds: 499));
      expect(find.byType(ColorFiltered), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNWidgets(3));
      expect(_filters(tester).last.child, same(child));
      _expectMatrix(_matrix(_filters(tester).last.colorFilter), _identity);
      await tester.pump(const Duration(milliseconds: 250));
      _expectMatrix(_matrix(_filters(tester).last.colorFilter), _quarterTurn);
    });

    testWidgets('enabled切替で静的ShaderMaskとアニメーションを切り替える', (tester) async {
      Widget host({required bool enabled}) => Directionality(
        textDirection: TextDirection.ltr,
        child: MfmRainbowWidget(enabled: enabled, child: const Text('text')),
      );
      await tester.pumpWidget(host(enabled: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpWidget(host(enabled: false));
      expect(find.byType(MfmStaticRainbowWidget), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byType(MfmAnimatedWrapper), findsNothing);
      await tester.pumpWidget(host(enabled: true));
      expect(find.byType(ShaderMask), findsNothing);
      _expectMatrix(_matrix(_filters(tester).last.colorFilter), _identity);
    });
  });

  testWidgets('fgの元色とWidgetSpanのalphabetic baselineを時間進行後も保持する', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MfmText(
            text: r'before $[rainbow $[fg.color=ff0000 red]] after',
            config: MfmRenderConfig(
              baseTextStyle: TextStyle(fontSize: 20, height: 2),
            ),
          ),
        ),
      ),
    );
    final outerFinder = find
        .ancestor(
          of: find.byType(MfmRainbowWidget),
          matching: find.byType(RichText),
        )
        .first;
    final innerFinder = find.descendant(
      of: find.byType(MfmRainbowWidget),
      matching: find.byType(RichText),
    );
    final outer = tester.renderObject<RenderParagraph>(outerFinder);
    final inner = tester.renderObject<RenderParagraph>(innerFinder);
    final span = (outer.text as TextSpan).children!
        .whereType<WidgetSpan>()
        .single;
    expect(span.alignment, PlaceholderAlignment.baseline);
    expect(span.baseline, TextBaseline.alphabetic);
    final size = outer.size;
    await tester.pump();
    for (final elapsed in [0, 250, 250]) {
      await tester.pump(Duration(milliseconds: elapsed));
      final outerBaseline = outer
          .localToGlobal(
            Offset(
              0,
              outer.getDryBaseline(outer.constraints, TextBaseline.alphabetic)!,
            ),
          )
          .dy;
      final innerBaseline = inner
          .localToGlobal(
            Offset(
              0,
              inner.getDryBaseline(inner.constraints, TextBaseline.alphabetic)!,
            ),
          )
          .dy;
      expect(innerBaseline, closeTo(outerBaseline, 1e-6));
      expect(outer.size, size);
      final foreground = (inner.text as TextSpan).children!.first as TextSpan;
      expect(foreground.style!.color, const Color(0xFFFF0000));
      expect(tester.layers.whereType<ColorFilterLayer>(), hasLength(3));
    }
    expect(tester.takeException(), isNull);
  });

  for (final opacity in [1.0, 0.7]) {
    testWidgets('実ラスタで赤の90度回転とOpacity($opacity)を検証する', (tester) async {
      const boundaryKey = ValueKey('rainbow-pixels');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Opacity(
                opacity: opacity,
                child: const MfmRainbowWidget(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: ColoredBox(color: Color(0xFFFF0000)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final rgba = await _pixelAt(tester, find.byKey(boundaryKey));
      // 各段のクランプを失うと緑が約100になるため、合成行列への退行も検出する。
      for (var channel = 0; channel < 4; channel++) {
        expect(rgba[channel], closeTo([0, 83, 0, 255 * opacity][channel], 2));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('静的フォールバックは本家の7色7ストップで描画する', (tester) async {
    const boundaryKey = ValueKey('static-rainbow-pixels');
    const colors = <Color>[
      Color(0xFFFF0000),
      Color(0xFFFFA500),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
    ];
    const stops = <double>[0, 0.17, 0.33, 0.5, 0.67, 0.83, 1];
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: MfmStaticRainbowWidget(
              child: SizedBox(
                width: 1001,
                height: 10,
                child: ColoredBox(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byKey(boundaryKey));
    for (var i = 0; i < stops.length; i++) {
      final x = (stops[i] * (size.width - 1)).round();
      final rgba = await _pixelAt(tester, find.byKey(boundaryKey), x: x);
      final color = colors[i];
      _expectPixel(rgba, [color.r * 255, color.g * 255, color.b * 255, 255]);
    }
  });
}

void _expectPixel(List<int> rgba, List<double> expected) {
  for (var channel = 0; channel < 4; channel++) {
    expect(rgba[channel], closeTo(expected[channel], 2));
  }
}
