import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_animated_wrapper.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_tada_widget.dart';

void main() {
  group('MfmAnimatedWrapper.parseTime', () {
    test('秒をマイクロ秒精度でパースする', () {
      expect(
        MfmAnimatedWrapper.parseTime('0.0004s'),
        const Duration(microseconds: 400),
      );
      expect(
        MfmAnimatedWrapper.parseTime('0.000001s'),
        const Duration(microseconds: 1),
      );
    });

    test('ゼロと負数の符号をフォールバックと区別できる', () {
      expect(MfmAnimatedWrapper.parseTime('0s'), Duration.zero);
      expect(MfmAnimatedWrapper.parseTime('-1s'), const Duration(seconds: -1));
    });

    test('Durationで表現できない極小値はゼロになる', () {
      expect(MfmAnimatedWrapper.parseTime('0.0000004s'), Duration.zero);
    });

    for (final entry in const <String, Duration>{
      '2s': Duration(seconds: 2),
      '.5s': Duration(milliseconds: 500),
      '1.s': Duration(seconds: 1),
    }.entries) {
      test('${entry.key}は秒数として受理する', () {
        expect(MfmAnimatedWrapper.parseTime(entry.key), entry.value);
      });
    }

    for (final entry in <String, Object?>{
      '未指定': null,
      '単位なしの文字列': '2',
      '整数': 2,
      '小数': 0.000001,
      'true': true,
      'false': false,
      'Duration': const Duration(seconds: 2),
      '前後の空白': ' 2s ',
      '先頭の空白': ' 2s',
      '末尾の空白': '2s ',
      '不正な文字列': 'abc',
      '空文字列': '',
      '複数の小数点': '1.2.3s',
      '数字なし': '.s',
      '正符号': '+2s',
      '指数表記': '2e1s',
      'ミリ秒単位': '2ms',
      '大文字の単位': '2S',
      'NaN': double.nan,
      '無限大': double.infinity,
    }.entries) {
      test('${entry.key}はnullになる', () {
        expect(MfmAnimatedWrapper.parseTime(entry.value), isNull);
      });
    }
  });

  group('speedとdelayの書式', () {
    const defaultDurations = <String, Duration>{
      'spin': Duration(milliseconds: 1500),
      'jump': Duration(milliseconds: 750),
      'bounce': Duration(milliseconds: 750),
      'rainbow': Duration(seconds: 1),
      'shake': Duration(milliseconds: 500),
      'twitch': Duration(milliseconds: 500),
      'tada': Duration(seconds: 1),
      'jelly': Duration(seconds: 1),
    };

    for (final entry in defaultDurations.entries) {
      for (final args in <String>[
        'speed=2,delay=2',
        'speed,delay',
        'speed=abc,delay=abc',
        'speed=1.2.3s,delay=1.2.3s',
      ]) {
        testWidgets('${entry.key}の$argsは既定値にフォールバックする', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(text: '\$[${entry.key}.$args test]'),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final wrapper = tester.widget<MfmAnimatedWrapper>(
            find.byType(MfmAnimatedWrapper),
          );
          expect(wrapper.duration, entry.value);
          expect(wrapper.delay, Duration.zero);
        });
      }

      testWidgets('${entry.key}のs付きspeedとdelayは指定秒数を使う', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: '\$[${entry.key}.speed=2s,delay=2s test]'),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final wrapper = tester.widget<MfmAnimatedWrapper>(
          find.byType(MfmAnimatedWrapper),
        );
        expect(wrapper.duration, const Duration(seconds: 2));
        expect(wrapper.delay, const Duration(seconds: 2));

        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    }
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
              home: Scaffold(body: MfmText(text: '\$[$fn.speed=$speed test]')),
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
          home: Scaffold(
            body: MfmText(
              text: r'$[tada.speed=0s test]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      final tada = find.byType(MfmTadaWidget);
      final richText = tester.widget<RichText>(
        find.descendant(of: tada, matching: find.byType(RichText)),
      );
      expect(richText.text.style?.fontSize, 21);
      expect(
        find.descendant(of: tada, matching: find.byType(Transform)),
        findsNothing,
      );
    });

    testWidgets('rainbowはspeed=0sでは静的グラデーションを適用しない', (tester) async {
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
            home: Scaffold(body: MfmText(text: '\$[$fn.speed=0.0004s test]')),
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
            body: MfmText(text: r'$[spin.speed=2s,delay=-0.5s test]'),
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
    testWidgets('Duration.zeroではbuilderとcontrollerを開始しない', (tester) async {
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
