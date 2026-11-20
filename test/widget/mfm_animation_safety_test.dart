import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_animated_wrapper.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';

void main() {
  group('P1 巨大なspeedとdelayの安全性', () {
    final hugeSeconds = '${'9' * 307}s';
    for (final entry in <String, String>{
      '乗算がInfinityになる正数': hugeSeconds,
      '乗算がInfinityになる負数': '-$hugeSeconds',
      'Durationの範囲を超える正数': '1000000000000000s',
      'Durationの範囲を超える負数': '-1000000000000000s',
    }.entries) {
      for (final argument in ['speed', 'delay']) {
        testWidgets('${entry.key}の$argumentでも例外を出さない', (tester) async {
          _cleanUp(tester);
          await tester.pumpWidget(_host('\$[spin.$argument=${entry.value} x]'));
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(milliseconds: 137));
          expect(tester.takeException(), isNull);
          expect(_fontSizes(tester), isNotEmpty);
        });
      }
    }
  });

  group('P2 progressのライフサイクル', () {
    testWidgets('speed変更で置き換えたCurvedAnimationをすべて破棄する', (tester) async {
      _cleanUp(tester);
      Animation<double>? current;
      AnimationController? currentController;

      Widget wrapper(int seconds) => Directionality(
        textDirection: TextDirection.ltr,
        child: MfmAnimatedWrapper(
          duration: Duration(seconds: seconds),
          child: const Text('x'),
          builder: (context, child, controller, progress) {
            current = progress;
            currentController = controller;
            return child;
          },
        ),
      );

      await tester.pumpWidget(wrapper(1));
      final controller = currentController;
      final retired = <CurvedAnimation>[];
      for (final seconds in [2, 3, 4]) {
        // builderの公開引数で観測し、Stateのprivateフィールドには依存しない。
        final previous = current! as CurvedAnimation;
        retired.add(previous);
        await tester.pumpWidget(wrapper(seconds));
        expect(currentController, same(controller));
        expect(current, isNot(same(previous)));
      }

      expect(
        retired.map((animation) => animation.isDisposed),
        everyElement(isTrue),
        reason: '旧progressが保持するcontrollerのstatus listenerを解放する',
      );
    });

    testWidgets('負のdelayへの切替とunmountでもCurvedAnimationを破棄する', (tester) async {
      _cleanUp(tester);
      Animation<double>? current;

      Widget wrapper(Duration delay) => Directionality(
        textDirection: TextDirection.ltr,
        child: MfmAnimatedWrapper(
          duration: const Duration(seconds: 1),
          delay: delay,
          child: const Text('x'),
          builder: (context, child, controller, progress) {
            current = progress;
            return child;
          },
        ),
      );

      await tester.pumpWidget(wrapper(Duration.zero));
      final first = current! as CurvedAnimation;

      // 負のdelayは独自の反復progressへ切り替わり、旧CurvedAnimationは不要になる。
      await tester.pumpWidget(wrapper(const Duration(milliseconds: -250)));
      expect(current, isNot(isA<CurvedAnimation>()));
      expect(first.isDisposed, isTrue);

      await tester.pumpWidget(wrapper(Duration.zero));
      final last = current! as CurvedAnimation;
      expect(last.isDisposed, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(last.isDisposed, isTrue);
    });
  });

  group('P2 MediaQuery.disableAnimations', () {
    testWidgets('spinは時間を進めても行列が変化しない', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(_host(r'$[spin x]', reducedMotion: true));
      final before = _transforms(tester);
      await tester.pump(const Duration(milliseconds: 137));
      expect(_transforms(tester), before);
    });

    for (final function in ['spin', 'rainbow', 'tada', 'sparkle']) {
      for (final switchWhileRunning in [false, true]) {
        testWidgets(
          '$functionは${switchWhileRunning ? '再生中のfalse→true切替' : '初回true'}で'
          'enableAnimation=falseと同じ表示になる',
          (tester) async {
            _cleanUp(tester);
            final mfm = '\$[$function x]';
            await tester.pumpWidget(_host(mfm, enableAnimation: false));
            final staticAppearance = _appearance(tester);
            if (function == 'rainbow') {
              expect(staticAppearance['rainbowViewports'], 1);
            }
            if (function == 'tada') {
              expect(_fontSizes(tester), [21.0]);
            }

            if (switchWhileRunning) {
              await tester.pumpWidget(_host(mfm));
              // sparkleも粒子を生成できる時間だけ実行してから切り替える。
              await tester.pump(const Duration(seconds: 1));
            }
            await tester.pumpWidget(_host(mfm, reducedMotion: true));
            await tester.pump(const Duration(milliseconds: 137));
            final reducedAppearance = _appearance(tester);
            await tester.pump(const Duration(milliseconds: 241));
            expect(
              _appearance(tester),
              reducedAppearance,
              reason: 'reduced motion中は描画が変化しない',
            );
            expect(
              reducedAppearance,
              staticAppearance,
              reason: 'rainbowの静的表示・tadaの150%・sparkle非表示も維持する',
            );
          },
        );
      }
    }

    testWidgets('TickerMode=falseのsparkleはTimerで再buildしない', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(_host(r'$[sparkle x]', tickerEnabled: false));
      final paints = _descendants(find.byType(CustomPaint));
      // 停止時に粒子レイヤー自体を省く実装も許容する。
      final before = tester
          .widgetList<CustomPaint>(paints)
          .map((paint) => paint.painter)
          .toList();
      await tester.pump(const Duration(milliseconds: 499));
      expect(
        tester.widgetList<CustomPaint>(paints).map((paint) => paint.painter),
        orderedEquals(before),
        reason: '生成Timerの最短500msまではtickerによる再buildもない',
      );
      // 生成間隔は500〜999ms。tickerが停止していてもTimerが動くと
      // setStateで新しいCustomPainterに置き換わることを公開Widgetで検出する。
      await tester.pump(const Duration(milliseconds: 501));
      expect(
        tester.widgetList<CustomPaint>(paints).map((paint) => paint.painter),
        orderedEquals(before),
        reason: 'TickerMode停止中は粒子生成TimerのsetStateも停止する',
      );
    });
  });

  group('P2 spinのCSS透視行列', () {
    for (final axis in ['x', 'y']) {
      testWidgets('spin.$axisの0度でm34は-1/128になる', (tester) async {
        _cleanUp(tester);
        await tester.pumpWidget(_host('\$[spin.$axis x]'));
        final transform = tester
            .widget<Transform>(_descendants(find.byType(Transform)))
            .transform;
        expect(transform.entry(3, 2), closeTo(-1 / 128, 1e-12));
      });

      testWidgets('spin.$axisの45度はCSS perspective(128px) rotateと一致する', (
        tester,
      ) async {
        _cleanUp(tester);
        await tester.pumpWidget(_host('\$[spin.$axis,speed=8s,delay=-1s x]'));
        final transform = tester
            .widget<Transform>(_descendants(find.byType(Transform)))
            .transform;
        final c = math.cos(math.pi / 4);
        final s = math.sin(math.pi / 4);
        // CSSとMatrix4は列優先。同じ回転符号でP * Rを手計算する。
        // w'=1-z/128なので正のz（手前）が拡大される。
        // https://www.w3.org/TR/css-transforms-2/#mathematical-description
        final expected = axis == 'x'
            ? <double>[
                1,
                0,
                0,
                0,
                0,
                c,
                s,
                -s / 128,
                0,
                -s,
                c,
                -c / 128,
                0,
                0,
                0,
                1,
              ]
            : <double>[
                c,
                0,
                -s,
                s / 128,
                0,
                1,
                0,
                0,
                s,
                0,
                c,
                -c / 128,
                0,
                0,
                0,
                1,
              ];
        for (var i = 0; i < expected.length; i++) {
          expect(
            transform.storage[i],
            closeTo(expected[i], 1e-10),
            reason: '列優先行列の要素$i',
          );
        }
      });
    }
  });

  group('P3 CSS timeとして無効なspeed', () {
    for (final function in [
      'tada',
      'jelly',
      'twitch',
      'shake',
      'spin',
      'jump',
      'bounce',
      'rainbow',
    ]) {
      for (final speed in ['1..s', '1.s', '.s', '1.2.3s', '-.s']) {
        testWidgets('$function.speed=$speedはアニメーションなしの表示になる', (tester) async {
          _cleanUp(tester);
          // speed=0sはuseAnim=trueのまま静止する公開経路。
          // rainbowは静的グラデーションでなく素の文字、tadaは150%になる。
          await tester.pumpWidget(_host('\$[$function.speed=0s x]'));
          final staticAppearance = _appearance(tester);
          if (function == 'tada') {
            expect(_fontSizes(tester), [21.0]);
          }
          if (function == 'rainbow') {
            expect(staticAppearance['rainbowViewports'], 0);
            expect(staticAppearance['filters'], isEmpty);
          }

          await tester.pumpWidget(_host('\$[$function.speed=$speed x]'));
          await tester.pump(const Duration(milliseconds: 137));
          expect(tester.takeException(), isNull);
          expect(_appearance(tester), staticAppearance);
          await tester.pump(const Duration(milliseconds: 241));
          expect(_appearance(tester), staticAppearance);
        });
      }
    }

    for (final function in [
      'tada',
      'jelly',
      'twitch',
      'shake',
      'spin',
      'jump',
      'bounce',
      'rainbow',
    ]) {
      testWidgets('外側の$functionのspeedがCSS無効でも内側のspinは動く', (tester) async {
        _cleanUp(tester);
        await tester.pumpWidget(
          _host('\$[$function.speed=1.2.3s \$[spin.speed=1s x]]'),
        );
        final wrapper = tester.widget<MfmAnimatedWrapper>(
          find.byType(MfmAnimatedWrapper),
        );
        expect(wrapper.duration, const Duration(seconds: 1));
        final before = _transforms(tester);
        await tester.pump(const Duration(milliseconds: 137));
        expect(tester.takeException(), isNull);
        expect(_transforms(tester), isNot(equals(before)));
      });
    }

    testWidgets('アニメーション無効のrainbowはCSS無効speedでも静的グラデーションになる', (
      tester,
    ) async {
      _cleanUp(tester);
      await tester.pumpWidget(_host(r'$[rainbow x]', enableAnimation: false));
      final staticAppearance = _appearance(tester);
      expect(staticAppearance['rainbowViewports'], greaterThan(0));

      await tester.pumpWidget(
        _host(r'$[rainbow.speed=1.2.3s x]', enableAnimation: false),
      );
      expect(tester.takeException(), isNull);
      expect(_appearance(tester), staticAppearance);
    });

    testWidgets('有効な.5sは500msのspeedで動く', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(_host(r'$[spin.speed=.5s x]'));
      final before = _transforms(tester);
      await tester.pump(const Duration(milliseconds: 125));
      expect(tester.takeException(), isNull);
      expect(_transforms(tester), isNot(equals(before)));
      final transform = tester
          .widget<Transform>(_descendants(find.byType(Transform)))
          .transform;
      expect(transform.entry(0, 0), closeTo(0, 1e-10));
      expect(transform.entry(1, 0), closeTo(1, 1e-10));
    });
  });
}

Widget _host(
  String mfm, {
  bool enableAnimation = true,
  bool reducedMotion = false,
  bool tickerEnabled = true,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: TickerMode(
      enabled: tickerEnabled,
      child: Scaffold(
        body: MfmText(
          text: mfm,
          config: MfmRenderConfig(
            enableAnimation: enableAnimation,
            baseTextStyle: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    ),
  ),
);

Finder _descendants(Finder matching) =>
    find.descendant(of: find.byType(MfmText), matching: matching);

List<List<double>> _transforms(WidgetTester tester) => tester
    .widgetList<Transform>(_descendants(find.byType(Transform)))
    .where((widget) => !widget.transform.isIdentity())
    .map((widget) => widget.transform.storage.toList())
    .toList();

Map<String, Object> _appearance(WidgetTester tester) => {
  'transforms': _transforms(tester),
  'filters': tester
      .widgetList<ColorFiltered>(_descendants(find.byType(ColorFiltered)))
      .map((widget) => widget.colorFilter)
      .toList(),
  'rainbowViewports': _descendants(
    find.byType(MfmRainbowViewport),
  ).evaluate().length,
  'particleLayers': _descendants(find.byType(CustomPaint)).evaluate().length,
  'fontSizes': _fontSizes(tester),
};

List<double?> _fontSizes(WidgetTester tester) {
  final sizes = <double?>[];
  void visit(InlineSpan span, TextStyle? inherited) {
    final style = inherited?.merge(span.style) ?? span.style;
    if (span is TextSpan) {
      if (span.text?.contains('x') ?? false) sizes.add(style?.fontSize);
      for (final child in span.children ?? <InlineSpan>[]) {
        visit(child, style);
      }
    }
  }

  for (final text in tester.widgetList<RichText>(
    _descendants(find.byWidgetPredicate((widget) => widget is RichText)),
  )) {
    visit(text.text, null);
  }
  return sizes;
}

void _cleanUp(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    // sparkleの既存粒子の削除Timerも満了させ、失敗の原因から分離する。
    await tester.pump(const Duration(seconds: 3));
  });
}
