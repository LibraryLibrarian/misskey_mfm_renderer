import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_animated_wrapper.dart';

void main() {
  group('MfmAnimatedWrapper.parseTime', () {
    test('秒をマイクロ秒精度でパースする', () {
      expect(
        MfmAnimatedWrapper.parseTime('0.0004s'),
        const Duration(microseconds: 400),
      );
      expect(
        MfmAnimatedWrapper.parseTime(0.000001),
        const Duration(microseconds: 1),
      );
    });

    test('ゼロと負数の符号をフォールバックと区別できる', () {
      expect(MfmAnimatedWrapper.parseTime('0s'), Duration.zero);
      expect(
        MfmAnimatedWrapper.parseTime('-1s'),
        const Duration(seconds: -1),
      );
    });

    test('Durationで表現できない極小値はゼロになる', () {
      expect(MfmAnimatedWrapper.parseTime('0.0000004s'), Duration.zero);
    });

    test('未指定・不正値・非有限値はnullになる', () {
      expect(MfmAnimatedWrapper.parseTime(null), isNull);
      expect(MfmAnimatedWrapper.parseTime('invalid'), isNull);
      expect(MfmAnimatedWrapper.parseTime(double.nan), isNull);
      expect(MfmAnimatedWrapper.parseTime(double.infinity), isNull);
    });
  });

  group('ゼロ以下のspeed', () {
    const animatedFunctions = <String>[
      'jelly',
      'tada',
      'jump',
      'bounce',
      'spin',
      'shake',
      'twitch',
      'rainbow',
    ];

    for (final fn in animatedFunctions) {
      for (final speed in <String>['0s', '-1s']) {
        testWidgets('$fn.speed=$speed は例外なく静止表示する', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(text: '\$[$fn.speed=$speed test]'),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(MfmAnimatedWrapper), findsNothing);
          expect(_containsText(tester, 'test'), isTrue);
        });
      }
    }

    testWidgets('tadaは静止時も150%の基本スタイルを維持する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'$[tada.speed=0s test]')),
        ),
      );

      final hasOnePointFiveScale = tester
          .widgetList<Transform>(find.byType(Transform))
          .any((widget) => widget.transform.storage[0] == 1.5);
      expect(hasOnePointFiveScale, isTrue);
    });

    testWidgets('rainbowはspeed=0sでは静的グラデーションを適用しない', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'$[rainbow.speed=0s test]')),
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
      expect(_containsText(tester, 'test'), isTrue);
    });

    testWidgets('sparkleの未対応speed引数には影響しない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'$[sparkle.speed=0s test]')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Stack), findsWidgets);
    });
  });

  group('正の極小speed', () {
    for (final fn in <String>[
      'jelly',
      'tada',
      'jump',
      'bounce',
      'spin',
      'shake',
      'twitch',
      'rainbow',
    ]) {
      testWidgets('$fn.speed=0.0004s は400マイクロ秒で再生する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: '\$[$fn.speed=0.0004s test]'),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final wrapper = tester.widget<MfmAnimatedWrapper>(
          find.byType(MfmAnimatedWrapper),
        );
        expect(wrapper.duration, const Duration(microseconds: 400));

        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('負のdelay', () {
    testWidgets('経過済み時間に対応する位相から開始する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.speed=2s,delay=-0.5s test]',
            ),
          ),
        ),
      );

      final transform = _animationTransform(tester);
      expect(transform.transform.storage[0], closeTo(0, 0.000001));
      expect(transform.transform.storage[1], closeTo(1, 0.000001));
    });

    testWidgets('alternateの逆方向区間も開始位相へ反映する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.alternate,speed=1s,delay=-1.25s test]',
            ),
          ),
        ),
      );

      var transform = _animationTransform(tester);
      expect(transform.transform.storage[1], closeTo(-1, 0.000001));

      await tester.pump(const Duration(milliseconds: 100));
      transform = _animationTransform(tester);
      expect(transform.transform.storage[1], lessThan(0));
    });
  });

  group('MfmAnimatedWrapperの防御', () {
    testWidgets('Duration.zeroではbuilderとcontrollerを開始しない', (
      tester,
    ) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MfmAnimatedWrapper(
            duration: Duration.zero,
            child: const Text('static'),
            builder: (context, child, controller, progress) {
              buildCount++;
              return child;
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(buildCount, 0);
      expect(find.text('static'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('実行中にdurationがゼロへ変わると安全に停止する', (tester) async {
      Widget buildWrapper(Duration duration) {
        return MaterialApp(
          home: MfmAnimatedWrapper(
            duration: duration,
            child: const Text('dynamic'),
            builder: (context, child, controller, progress) => child,
          ),
        );
      }

      await tester.pumpWidget(buildWrapper(const Duration(seconds: 1)));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(buildWrapper(Duration.zero));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('dynamic'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

bool _containsText(WidgetTester tester, String text) {
  return tester.widgetList<RichText>(find.byType(RichText)).any((widget) {
    return widget.text.toPlainText().contains(text);
  });
}

Transform _animationTransform(WidgetTester tester) {
  return tester
      .widgetList<Transform>(find.byType(Transform))
      .firstWhere((widget) => widget.alignment == Alignment.center);
}
