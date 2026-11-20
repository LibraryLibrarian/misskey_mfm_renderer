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
        expect(_findTransform(), findsNothing);
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
        expect(_findTransform(), findsNothing);
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

  for (final family in ['emoji', 'math']) {
    testWidgets('仕様未決: font.$familyはフォント指定を追加しない現状を記録する', (tester) async {
      // 仕様未決: 本家はfont-family: emoji / mathを指定する。
      // 対応するFlutter側の期待値が決まるまでは現状の記録としてskipする。
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

      expectNoFont(richText.text);
      richText.text.visitChildren((span) {
        expectNoFont(span);
        return true;
      });
    }, skip: true);
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
