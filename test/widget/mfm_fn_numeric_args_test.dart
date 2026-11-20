import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_border.dart';

void main() {
  // Misskey 2026.11.0 mfm-renderer.ts の safeParseFloat に合わせる。
  group('fnの数値引数はparseFloatと同じ先頭の数値を使う', () {
    const degrees = <String, double>{
      '45deg': 45,
      '1e1': 10,
      '.5': .5,
      '-45': -45,
      'abc': 90,
      '1e': 1, // 指数部が未完成なら、その手前までを読む。
      '0x10': 0, // parseFloatは16進数として解釈しない。
    };
    for (final entry in degrees.entries) {
      testWidgets('rotate.deg=${entry.key}は${entry.value}度回転する', (
        tester,
      ) async {
        await _pumpMfm(tester, '\$[rotate.deg=${entry.key} x]');

        final matrix = _transform(tester).transform;
        final radians = entry.value * math.pi / 180;
        expect(matrix.entry(0, 0), closeTo(math.cos(radians), 1e-9));
        expect(matrix.entry(1, 0), closeTo(math.sin(radians), 1e-9));
      });
    }

    testWidgets('position.x=1emは文字サイズ1個分だけ移動する', (tester) async {
      await _pumpMfm(tester, r'$[position.x=1em x]');

      final matrix = _transform(tester).transform;
      // ベースフォント20pxなので1em = 20px。
      expect(matrix.entry(0, 3), 20);
      expect(matrix.entry(1, 3), 0);
    });

    testWidgets('scale.x=2fooは横方向を2倍にする', (tester) async {
      await _pumpMfm(tester, r'$[scale.x=2foo x]');

      final matrix = _transform(tester).transform;
      expect(matrix.entry(0, 0), 2);
      expect(matrix.entry(1, 1), 1);
    });
  });

  group('fnの数値引数が無限大になる場合', () {
    // 本家のCSSでは rotate(Infinitydeg) や translateX(Infinityem) は無効な値で、
    // transform宣言ごと捨てられる。
    for (final deg in ['Infinity', '-Infinity', '1e400']) {
      testWidgets('rotate.deg=$degは例外を出さず回転しない', (tester) async {
        await _pumpMfm(tester, '\$[rotate.deg=$deg x]');

        expect(tester.takeException(), isNull);
        expect(_transform(tester).transform, Matrix4.identity());
        expect(find.text('x', findRichText: true), findsOneWidget);
      });
    }

    testWidgets('rotate.deg=1e308はラジアンに直すと溢れるが同じ向きに回転する', (tester) async {
      await _pumpMfm(tester, r'$[rotate.deg=1e308 x]');

      final matrix = _transform(tester).transform;
      const radians = 1e308 % 360 * math.pi / 180;
      expect(matrix.entry(0, 0), closeTo(math.cos(radians), 1e-9));
      expect(matrix.entry(1, 0), closeTo(math.sin(radians), 1e-9));
    });

    for (final args in ['x=Infinity', 'x=1,y=Infinity', 'x=1e308']) {
      testWidgets('position.$argsは座標をNaNにせず移動しない', (tester) async {
        await _pumpMfm(tester, '\$[position.$args x]');

        expect(tester.takeException(), isNull);
        expect(_transform(tester).transform, Matrix4.identity());
        final origin = tester
            .renderObject<RenderBox>(find.text('x', findRichText: true))
            .localToGlobal(Offset.zero);
        expect(origin.isFinite, isTrue);
      });
    }
  });

  group('scaleの負の倍率を本家どおりに扱う', () {
    testWidgets('scale.x=-10は負の倍率に下限を設けない', (tester) async {
      await _pumpMfm(tester, r'$[scale.x=-10 x]');

      final matrix = _transform(tester).transform;
      expect(matrix.entry(0, 0), -10);
      expect(matrix.entry(1, 1), 1);
    });

    testWidgets('負のscaleからx3へ符号付きの最大倍率を伝播し原寸絵文字を使わない', (tester) async {
      final contexts = <MfmEmojiContext>[];
      await _pumpMfm(
        tester,
        r'$[scale.x=-3,y=-4 $[x3 :e:]]',
        config: MfmRenderConfig(
          baseTextStyle: const TextStyle(fontSize: 20),
          emojiBuilder: (name, context) {
            expect(name, 'e');
            contexts.add(context);
            return const SizedBox(width: 20, height: 20);
          },
        ),
      );

      expect(contexts, hasLength(1));
      // Math.max(-3, -4) * 3 = -9。useOriginalSizeはscale >= 2.5。
      expect(
        (
          scale: contexts.single.scale,
          original: contexts.single.useOriginalSize,
        ),
        (scale: -9.0, original: false),
      );
    });
  });

  group('scaleの極端な倍率', () {
    testWidgets('scale.x=Infinityは上限の5倍になる', (tester) async {
      await _pumpMfm(tester, r'$[scale.x=Infinity x]');

      final matrix = _transform(tester).transform;
      expect(matrix.entry(0, 0), 5);
      expect(matrix.entry(1, 1), 1);
    });

    testWidgets('巨大な負の倍率は描画だけ-1024に収め、伝播は本家どおりにする', (tester) async {
      final contexts = await _pumpEmojiContexts(
        tester,
        r'$[scale.x=-1e300,y=-1e300 :e:]',
      );

      expect(tester.takeException(), isNull);
      final matrix = _transform(tester).transform;
      expect(matrix.entry(0, 0), -1024);
      expect(matrix.entry(1, 1), -1024);
      expect(contexts.single.scale, -1e300);
    });

    testWidgets('-Infinityは変形せず、もう一方の軸の倍率を伝播する', (tester) async {
      final contexts = await _pumpEmojiContexts(
        tester,
        r'$[scale.x=-Infinity,y=3 :e:]',
      );

      expect(tester.takeException(), isNull);
      expect(_transform(tester).transform, Matrix4.identity());
      // Math.max(-Infinity, 3) = 3
      expect(contexts.single.scale, 3);
      expect(contexts.single.useOriginalSize, isTrue);
    });

    testWidgets('両軸-Infinityは-Infinityを伝播する', (tester) async {
      final contexts = await _pumpEmojiContexts(
        tester,
        r'$[scale.x=-Infinity,y=-Infinity :e:]',
      );

      expect(_transform(tester).transform, Matrix4.identity());
      expect(contexts.single.scale, double.negativeInfinity);
      expect(contexts.single.useOriginalSize, isFalse);
    });

    testWidgets('伝播する倍率がNaNになる場合は0にする', (tester) async {
      final contexts = await _pumpEmojiContexts(
        tester,
        r'$[scale.x=0,y=0 $[scale.x=-Infinity,y=-Infinity :e:]]',
      );

      // 本家では 0 * -Infinity = NaN。useOriginalSizeはどちらでもfalse。
      final context = contexts.single;
      expect(context.scale, 0);
      expect(context.useOriginalSize, isFalse);
      expect(context, context);
    });
  });

  group('無効な数値に切り替えても子のStateを保つ', () {
    const cases = {
      'rotate': ['deg=45', 'deg=Infinity'],
      'position': ['x=2', 'x=Infinity'],
      'scale': ['x=2', 'x=-Infinity'],
    };
    for (final MapEntry(key: name, value: args) in cases.entries) {
      testWidgets('$nameの${args[0]}と${args[1]}を切り替えてもStateを作り直さない', (
        tester,
      ) async {
        var created = 0;
        var disposed = 0;
        final config = MfmRenderConfig(
          baseTextStyle: const TextStyle(fontSize: 20),
          emojiBuilder: (name, context) => _LifecycleProbe(
            onInit: () => created++,
            onDispose: () => disposed++,
          ),
        );
        for (final arg in [args[0], args[1], args[0]]) {
          await _pumpMfm(tester, '\$[$name.$arg :e:]', config: config);
        }

        expect(
          (created: created, disposed: disposed),
          (created: 1, disposed: 0),
        );
      });
    }
  });

  for (final family in ['emoji', 'math']) {
    testWidgets('font.$familyは既定のフォント指定を追加しない', (tester) async {
      // 本家はfont-family: emoji / mathを指定するが、Flutterでは同じ割り当てを
      // 保証できないため、fontFamilyResolverで指定されない限り継承したままにする。
      await _pumpMfm(
        tester,
        '\$[font.$family x]',
        config: const MfmRenderConfig(
          baseTextStyle: TextStyle(inherit: false, fontSize: 20),
        ),
      );

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.toPlainText(), 'x');
      void expectNoFont(InlineSpan span) {
        expect(span.style?.fontFamily, isNull);
        expect(span.style?.fontFamilyFallback, isNull);
      }

      _allSpans(richText.text).forEach(expectNoFont);
    });

    testWidgets('font.$familyはfontFamilyResolverの指定を使う', (tester) async {
      final requested = <String>[];
      await _pumpMfm(
        tester,
        '\$[font.$family x]',
        config: MfmRenderConfig(
          baseTextStyle: const TextStyle(fontSize: 20),
          fontFamilyResolver: (type) {
            requested.add(type);
            return 'Custom$family';
          },
        ),
      );

      expect(requested, [family]);
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(RichText),
        ),
      );
      expect(
        _allSpans(richText.text).map((span) => span.style?.fontFamily),
        contains('Custom$family'),
      );
    });
  }

  testWidgets('仕様未決: border.width=2000は1024に制限する現状を記録する', (tester) async {
    // 仕様未決: 本家のwidthは2000pxで上限なし。現状の上限を記録する。
    tester.view.physicalSize = const Size(6000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpMfm(tester, r'$[border.width=2000 x]');

    final border = tester.widget<MfmBorder>(find.byType(MfmBorder));
    expect(border.options.width, 1024);
  }, skip: true);
}

Future<void> _pumpMfm(
  WidgetTester tester,
  String text, {
  MfmRenderConfig config = const MfmRenderConfig(
    baseTextStyle: TextStyle(fontSize: 20),
  ),
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: MfmText(text: text, config: config),
    ),
  ),
);

Finder _findTransform() =>
    find.descendant(of: find.byType(MfmText), matching: find.byType(Transform));

Transform _transform(WidgetTester tester) =>
    tester.widget<Transform>(_findTransform());

Future<List<MfmEmojiContext>> _pumpEmojiContexts(
  WidgetTester tester,
  String text,
) async {
  final contexts = <MfmEmojiContext>[];
  await _pumpMfm(
    tester,
    text,
    config: MfmRenderConfig(
      baseTextStyle: const TextStyle(fontSize: 20),
      emojiBuilder: (name, context) {
        contexts.add(context);
        return const SizedBox(width: 20, height: 20);
      },
    ),
  );
  expect(contexts, hasLength(1));
  return contexts;
}

/// 文字を持たない入れ子のTextSpanも含めて、すべてのspanを列挙する。
Iterable<InlineSpan> _allSpans(InlineSpan root) sync* {
  yield root;
  final children = <InlineSpan>[];
  root.visitDirectChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _allSpans(child);
  }
}

class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe({required this.onInit, required this.onDispose});

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20);
}
