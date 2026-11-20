import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_animated_wrapper.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_bounce_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_jelly_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_jump_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_shake_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_sparkle_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_spin_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_tada_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_twitch_widget.dart';

void main() {
  group('MfmText spin アニメーション', () {
    testWidgets('アニメーション有効時にMfmSpinWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin 回転]',
            ),
          ),
        ),
      );

      // MfmSpinWidgetが生成される
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin 回転]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '回転');
      });
      expect(hasText, isTrue);
    });

    testWidgets('spin.xでX軸回転が適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.x 回転X]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('spin.yでY軸回転が適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.y 回転Y]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('spin.leftで逆回転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.left 逆回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('spin.alternateで往復回転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.alternate 往復]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('spin.speed=2sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.speed=2s 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('spin.delay=1sで開始遅延を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.delay=1s 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText jump アニメーション', () {
    testWidgets('アニメーション有効時にMfmJumpWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jump ジャンプ]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jump ジャンプ]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, 'ジャンプ');
      });
      expect(hasText, isTrue);
    });

    testWidgets('jump.speed=1sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jump.speed=1s ジャンプ]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText bounce アニメーション', () {
    testWidgets('アニメーション有効時にMfmBounceWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[bounce バウンド]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[bounce バウンド]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, 'バウンド');
      });
      expect(hasText, isTrue);
    });

    testWidgets('bounce.speed=1sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[bounce.speed=1s バウンド]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('bounce.delay=0.5sで開始遅延を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[bounce.delay=0.5s バウンド]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('twitch / shake のキーフレーム区間イージング', () {
    const ease = Cubic(.25, .1, .25, 1);

    for (final isShake in [false, true]) {
      final name = isShake ? 'shake' : 'twitch';

      testWidgets('$nameは最初の区間の中点にeaseを適用する', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake);
        await tester.pump(const Duration(microseconds: 12500));

        final q = ease.transform(.5);
        _expectTwitchOrShakeTransform(
          tester,
          isShake: isShake,
          x: isShake ? -3 + 3 * q : 7 - 10 * q,
          y: isShake ? -1 : -2 + 3 * q,
          rotateDeg: isShake ? -8 - 2 * q : null,
        );
      });

      testWidgets('$nameは5%境界でキーフレーム値になる', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 25));

        _expectTwitchOrShakeTransform(
          tester,
          isShake: isShake,
          x: isShake ? 0 : -3,
          y: isShake ? -1 : 1,
          rotateDeg: isShake ? -10 : null,
        );
      });

      testWidgets('$nameは後半の区間にもeaseを適用する', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake);
        await tester.pump(const Duration(microseconds: 112500));

        final q = ease.transform(.5);
        _expectTwitchOrShakeTransform(
          tester,
          isShake: isShake,
          x: isShake ? -2 + q : -8 + 4 * q,
          y: isShake ? 1 - 3 * q : 6 - 9 * q,
          rotateDeg: isShake ? 1 - 3 * q : null,
        );
      });

      testWidgets('$nameはspeed変更後も区間の中点にeaseを適用する', (tester) async {
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          duration: const Duration(seconds: 1),
        );
        await tester.pump(const Duration(milliseconds: 25));

        final q = ease.transform(.5);
        _expectTwitchOrShakeTransform(
          tester,
          isShake: isShake,
          x: isShake ? -3 + 3 * q : 7 - 10 * q,
          y: isShake ? -1 : -2 + 3 * q,
          rotateDeg: isShake ? -8 - 2 * q : null,
        );
      });

      testWidgets('$nameは負のdelayの位相にも区間のeaseを適用する', (tester) async {
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: const Duration(microseconds: -12500),
        );

        final q = ease.transform(.5);
        _expectTwitchOrShakeTransform(
          tester,
          isShake: isShake,
          x: isShake ? -3 + 3 * q : 7 - 10 * q,
          y: isShake ? -1 : -2 + 3 * q,
          rotateDeg: isShake ? -8 - 2 * q : null,
        );
      });

      testWidgets('$nameは正のdelay後に区間のeaseで進行する', (tester) async {
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: const Duration(milliseconds: 10),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump(const Duration(microseconds: 12500));

        final q = ease.transform(.5);
        _expectTwitchOrShakeTransform(
          tester,
          isShake: isShake,
          x: isShake ? -3 + 3 * q : 7 - 10 * q,
          y: isShake ? -1 : -2 + 3 * q,
          rotateDeg: isShake ? -8 - 2 * q : null,
        );
      });
    }
  });

  group('twitch / shake の正delay待機', () {
    for (final isShake in [false, true]) {
      final name = isShake ? 'shake' : 'twitch';
      const delay = Duration(milliseconds: 500);

      testWidgets('$nameは0・499msで無変形、500msからeaseで開始する', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        _expectWaiting(tester, isShake: isShake);
        expect(find.text('test'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 499));
        _expectWaiting(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        _expectFirstKeyframe(tester, isShake: isShake);
        await tester.pump(const Duration(microseconds: 12500));
        _expectFirstMidpoint(tester, isShake: isShake);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      for (final changeDuration in [false, true]) {
        testWidgets(
          '$nameは待機中の${changeDuration ? 'duration' : 'delay'}変更で旧Timerを破棄する',
          (tester) async {
            await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
            await tester.pump(const Duration(milliseconds: 200));
            final newDelay = changeDuration
                ? delay
                : const Duration(milliseconds: 600);
            await _pumpTwitchOrShake(
              tester,
              isShake: isShake,
              delay: newDelay,
              duration: Duration(milliseconds: changeDuration ? 1000 : 500),
            );
            await tester.pump(const Duration(milliseconds: 300));
            _expectWaiting(tester, isShake: isShake); // 旧期限500ms
            await tester.pump(newDelay - const Duration(milliseconds: 301));
            _expectWaiting(tester, isShake: isShake);
            await tester.pump(const Duration(milliseconds: 1));
            await tester.pump();
            _expectFirstKeyframe(tester, isShake: isShake);
            await tester.pump(
              Duration(microseconds: changeDuration ? 25000 : 12500),
            );
            _expectFirstMidpoint(tester, isShake: isShake);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }

      for (final newDelay in [
        Duration.zero,
        const Duration(microseconds: -12500),
      ]) {
        testWidgets('$nameは待機からdelay=${newDelay.inMicroseconds}へ変更して即開始する', (
          tester,
        ) async {
          await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
          await tester.pump(const Duration(milliseconds: 100));
          await _pumpTwitchOrShake(tester, isShake: isShake, delay: newDelay);
          if (newDelay == Duration.zero) {
            _expectFirstKeyframe(tester, isShake: isShake);
          } else {
            _expectFirstMidpoint(tester, isShake: isShake);
          }
          // 旧期限を越えても再開始せず、1周期後の位相を保持する。
          await tester.pump(delay);
          if (newDelay == Duration.zero) {
            _expectFirstKeyframe(tester, isShake: isShake);
          } else {
            _expectFirstMidpoint(tester, isShake: isShake);
          }
          await tester.pump(const Duration(microseconds: 12500));
          if (newDelay == Duration.zero) {
            _expectFirstMidpoint(tester, isShake: isShake);
          } else {
            _expectTwitchOrShakeTransform(
              tester,
              isShake: isShake,
              x: isShake ? 0 : -3,
              y: isShake ? -1 : 1,
              rotateDeg: -10,
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }

      testWidgets('$nameは無効化で待機を取り消し再有効化で待ち直す', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        await tester.pump(const Duration(milliseconds: 200));
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          enabled: false,
        );
        expect(_effectTransforms(isShake: isShake), findsNothing);
        expect(find.text('test'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_effectTransforms(isShake: isShake), findsNothing);
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        await tester.pump(const Duration(milliseconds: 499));
        _expectWaiting(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        _expectFirstKeyframe(tester, isShake: isShake);
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          enabled: false,
        );
        expect(_effectTransforms(isShake: isShake), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('$nameはchild・style更新で待機期限と再生位相を保持する', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        await tester.pump(const Duration(milliseconds: 200));
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          child: const Text('updated', style: TextStyle(fontSize: 24)),
        );
        await tester.pump(const Duration(milliseconds: 299));
        _expectWaiting(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        _expectFirstKeyframe(tester, isShake: isShake);
        await tester.pump(const Duration(microseconds: 12500));
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          child: const Text('again', style: TextStyle(fontSize: 30)),
        );
        _expectFirstMidpoint(tester, isShake: isShake);
        expect(find.text('again'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('$nameは待機と再生を跨いでlocal keyのState・Elementを保持する', (
        tester,
      ) async {
        var initialized = 0;
        var disposed = 0;
        final child = _AnimationLifecycleProbe(
          key: const ValueKey('child'),
          onInit: () => initialized++,
          onDispose: () => disposed++,
        );
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          child: child,
        );
        final element = tester.element(find.byKey(const ValueKey('child')));
        final state = tester.state(find.byKey(const ValueKey('child')));
        await tester.pump(delay);
        await tester.pump();
        _expectFirstKeyframe(tester, isShake: isShake);
        expect(
          tester.element(find.byKey(const ValueKey('child'))),
          same(element),
        );
        expect(tester.state(find.byKey(const ValueKey('child'))), same(state));
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: const Duration(seconds: 1),
          child: child,
        );
        _expectWaiting(tester, isShake: isShake);
        expect(
          tester.element(find.byKey(const ValueKey('child'))),
          same(element),
        );
        expect(tester.state(find.byKey(const ValueKey('child'))), same(state));
        await tester.pump(const Duration(milliseconds: 999));
        _expectWaiting(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        _expectFirstKeyframe(tester, isShake: isShake);
        expect(
          tester.element(find.byKey(const ValueKey('child'))),
          same(element),
        );
        expect(tester.state(find.byKey(const ValueKey('child'))), same(state));
        expect(initialized, 1);
        expect(disposed, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(disposed, 1);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });

      for (final innerWaiting in [true, false]) {
        testWidgets(
          '$nameは外側開始時に内側の${innerWaiting ? '2秒delay' : '再生位相'}を保持する',
          (tester) async {
            const outerKey = ValueKey('outer');
            const innerKey = ValueKey('inner');
            final inner = _twitchOrShake(
              isShake: !isShake,
              key: innerKey,
              delay: innerWaiting ? const Duration(seconds: 2) : Duration.zero,
              duration: const Duration(seconds: 4),
              child: const Text('nested'),
            );
            await _pumpTwitchOrShake(
              tester,
              isShake: isShake,
              key: outerKey,
              delay: const Duration(seconds: 1),
              child: inner,
            );
            final innerElement = tester.element(find.byKey(innerKey));
            await tester.pump(const Duration(seconds: 1));
            await tester.pump();
            _expectFirstKeyframe(
              tester,
              isShake: isShake,
              effect: find.byKey(outerKey),
            );
            expect(tester.element(find.byKey(innerKey)), same(innerElement));
            if (innerWaiting) {
              _expectWaiting(
                tester,
                isShake: !isShake,
                effect: find.byKey(innerKey),
              );
              await tester.pump(const Duration(milliseconds: 999));
              _expectWaiting(
                tester,
                isShake: !isShake,
                effect: find.byKey(innerKey),
              );
              await tester.pump(const Duration(milliseconds: 1));
              await tester.pump();
              _expectFirstKeyframe(
                tester,
                isShake: !isShake,
                effect: find.byKey(innerKey),
              );
            } else {
              // 内側は4秒周期の25%。外側の開始で0%に戻らない。
              _expectTwitchOrShakeTransform(
                tester,
                isShake: !isShake,
                effect: find.byKey(innerKey),
                x: isShake ? -4 : -1,
                y: isShake ? -3 : -2,
                rotateDeg: -2,
              );
              await _pumpTwitchOrShake(
                tester,
                isShake: isShake,
                key: outerKey,
                delay: const Duration(seconds: 2),
                child: inner,
              );
              _expectWaiting(
                tester,
                isShake: isShake,
                effect: find.byKey(outerKey),
              );
              _expectTwitchOrShakeTransform(
                tester,
                isShake: !isShake,
                effect: find.byKey(innerKey),
                x: isShake ? -4 : -1,
                y: isShake ? -3 : -2,
                rotateDeg: -2,
              );
            }
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }

      testWidgets('$nameはTickerMode停止をdelay待機と混同しない', (tester) async {
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          tickerEnabled: false,
        );
        await tester.pump(delay);
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          tickerEnabled: false,
          child: const Text('muted'),
        );
        _expectFirstKeyframe(tester, isShake: isShake);
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        await tester.pump(const Duration(microseconds: 12500));
        _expectFirstMidpoint(tester, isShake: isShake);
        await _pumpTwitchOrShake(
          tester,
          isShake: isShake,
          delay: delay,
          tickerEnabled: false,
        );
        _expectFirstMidpoint(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 25));
        _expectFirstMidpoint(tester, isShake: isShake);
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        expect(
          tester
              .widget<Transform>(_effectTransforms(isShake: isShake).first)
              .transform
              .isIdentity(),
          isFalse,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('$nameは待機中disposeでTimerを破棄する', (tester) async {
        await _pumpTwitchOrShake(tester, isShake: isShake, delay: delay);
        _expectWaiting(tester, isShake: isShake);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(tester.binding.transientCallbackCount, 0);
      });

      testWidgets('MfmText $name.delay=0.5sは待機姿勢と開始を伝搬する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: '\$[$name.delay=0.5s test]'),
            ),
          ),
        );
        _expectWaiting(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 499));
        _expectWaiting(tester, isShake: isShake);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        _expectFirstKeyframe(tester, isShake: isShake);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      for (final config in const [
        MfmRenderConfig(enableAnimation: false),
        MfmRenderConfig(enableAdvancedMfm: false),
      ]) {
        testWidgets(
          'MfmText $nameは正delayでもflags=${config.enableAnimation}/${config.enableAdvancedMfm}で静止する',
          (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MfmText(
                    text: '\$[$name.delay=0.5s test]',
                    config: config,
                  ),
                ),
              ),
            );
            expect(find.byType(MfmAnimatedWrapper), findsNothing);
            expect(
              tester
                  .widgetList<RichText>(find.byType(RichText))
                  .any((w) => _spanContainsText(w.text, 'test')),
              isTrue,
            );
            await tester.pump(const Duration(seconds: 1));
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }

      testWidgets('MfmText $nameは正delayでもspeed=0sで静止する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: '\$[$name.delay=0.5s,speed=0s test]'),
            ),
          ),
        );
        expect(find.byType(MfmAnimatedWrapper), findsNothing);
        expect(
          tester
              .widgetList<RichText>(find.byType(RichText))
              .any((w) => _spanContainsText(w.text, 'test')),
          isTrue,
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  group('MfmText shake アニメーション', () {
    testWidgets('アニメーション有効時にMfmShakeWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[shake 震える]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[shake 震える]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '震える');
      });
      expect(hasText, isTrue);
    });

    testWidgets('shake.speed=0.3sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[shake.speed=0.3s 震える]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText twitch アニメーション', () {
    testWidgets('アニメーション有効時にMfmTwitchWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[twitch けいれん]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[twitch けいれん]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, 'けいれん');
      });
      expect(hasText, isTrue);
    });

    testWidgets('twitch.speed=0.3sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[twitch.speed=0.3s けいれん]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText jelly アニメーション', () {
    testWidgets('アニメーション有効時にMfmJellyWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jelly ゼリー]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jelly ゼリー]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, 'ゼリー');
      });
      expect(hasText, isTrue);
    });

    testWidgets('jelly.speed=2sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jelly.speed=2s ゼリー]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText tada アニメーション', () {
    testWidgets('アニメーション有効時にMfmTadaWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[tada 🎉]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('アニメーション無効時もフォントサイズ150%が適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[tada 🎉]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
                enableAnimation: false,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(_textStyles(richText.text).single.fontSize, 21);
      expect(find.byType(MfmTadaWidget), findsNothing);
      expect(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });

    testWidgets('tadaは描画だけでなくレイアウトの高さも150%に拡大する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: Column(
                children: [
                  MfmText(
                    key: ValueKey('plain'),
                    text: 'A',
                    config: MfmRenderConfig(
                      baseTextStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                  MfmText(
                    key: ValueKey('tada'),
                    text: r'$[tada A]B',
                    config: MfmRenderConfig(
                      baseTextStyle: TextStyle(fontSize: 14),
                      enableAnimation: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final plainHeight = tester
          .getSize(
            find.descendant(
              of: find.byKey(const ValueKey('plain')),
              matching: find.byType(RichText),
            ),
          )
          .height;
      // getSizeはTransformの描画倍率ではなくRenderBoxのレイアウトサイズ。
      final tadaHeight = tester
          .getSize(
            find.descendant(
              of: find.byKey(const ValueKey('tada')),
              matching: find.byType(RichText),
            ),
          )
          .height;
      expect(tadaHeight, greaterThan(plainHeight));
      expect(tadaHeight, closeTo(plainHeight * 1.5, 0.1));
    });

    testWidgets('x2内のtadaは親相対で42pxになる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x2 $[tada A]]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
                enableAnimation: false,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(_textStyles(richText.text).single.fontSize, 42);
      expect(find.byType(MfmTadaWidget), findsNothing);
    });

    testWidgets('tadaの子WidgetSpanにも150%の実効フォントサイズが伝わる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[tada $[flip A]]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
                enableAnimation: false,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.descendant(
            of: find.byType(MfmText),
            matching: find.byType(Transform),
          ),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.fontSize, 21);
      expect(find.byType(MfmTadaWidget), findsNothing);
    });

    testWidgets('tadaのTransformは150%を重ねずキーフレームの倍率だけを適用する', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[tada A]',
              // enableAnimationはデフォルトのtrueで検証する。
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

      // 0〜100%を100msずつ進め、収縮・拡大・周期末を検証する。
      const scales = [
        1.0,
        0.91,
        0.91,
        1.09,
        1.09,
        1.09,
        1.09,
        1.09,
        1.09,
        1.09,
        1.0,
      ];
      for (var i = 0; i < scales.length; i++) {
        if (i > 0) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final transform = tester
            .widget<Transform>(
              find.descendant(of: tada, matching: find.byType(Transform)),
            )
            .transform;
        // 回転成分を除くため、X/Y列ベクトルの長さから倍率を取り出す。
        for (final axis in [0, 1]) {
          final scale = transform.getColumn(axis).length;
          expect(scale, inInclusiveRange(0.91 - 0.000001, 1.09 + 0.000001));
          expect(scale, closeTo(scales[i], 0.000001));
        }
      }
    });

    testWidgets('tada.speed=2sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[tada.speed=2s 🎉]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText rainbow アニメーション', () {
    testWidgets('アニメーション有効時にMfmRainbowWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[rainbow 虹色]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ColorFiltered), findsNWidgets(3));
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('アニメーション無効時はフォールバックグラデーションが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[rainbow 虹色]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // 全体のマスクではなく文字だけに静的グラデーションを適用する。
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.byType(MfmRainbowRichText), findsOneWidget);
      // テキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.bySubtype<RichText>());
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '虹色');
      });
      expect(hasText, isTrue);
    });

    testWidgets('rainbow.speed=2sでカスタム速度を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[rainbow.speed=2s 虹色]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ColorFiltered), findsNWidgets(3));
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('rainbow.delay=0.5sで開始遅延を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[rainbow.delay=0.5s 虹色]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNWidgets(3));
      final initialHue = tester
          .widgetList<ColorFiltered>(find.byType(ColorFiltered))
          .last
          .colorFilter;
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester
            .widgetList<ColorFiltered>(find.byType(ColorFiltered))
            .last
            .colorFilter,
        isNot(initialHue),
      );
    });
  });

  group('MfmText sparkle アニメーション', () {
    testWidgets('アニメーション有効時にMfmSparkleWidgetが生成される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[sparkle ✨]',
            ),
          ),
        ),
      );

      await tester.pump();
      // Stackが生成される（スパークルのオーバーレイ用）
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('アニメーション無効時は子要素がそのまま表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[sparkle ✨]',
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // RichTextが生成され、テキストが含まれる
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '✨');
      });
      expect(hasText, isTrue);
    });

    testWidgets('sparkleは引数なしで動作する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[sparkle きらきら]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Stack), findsWidgets);
      // テキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, 'きらきら');
      });
      expect(hasText, isTrue);
    });
  });

  group('MfmText アニメーションの共通ゲート', () {
    const animatedFunctions = <String, Type>{
      'spin': MfmSpinWidget,
      'jump': MfmJumpWidget,
      'bounce': MfmBounceWidget,
      'shake': MfmShakeWidget,
      'twitch': MfmTwitchWidget,
      'jelly': MfmJellyWidget,
      'tada': MfmTadaWidget,
      'rainbow': MfmRainbowWidget,
      'sparkle': MfmSparkleWidget,
    };
    for (final flags in [
      (advanced: false, animation: true),
      (advanced: true, animation: false),
      (advanced: false, animation: false),
    ]) {
      for (final fn in animatedFunctions.keys) {
        testWidgets(
          '$fn advanced=${flags.advanced}, animation=${flags.animation}は静的表示',
          (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MfmText(
                    text: '\$[$fn **body**]',
                    config: MfmRenderConfig(
                      baseTextStyle: const TextStyle(fontSize: 14),
                      enableAdvancedMfm: flags.advanced,
                      enableAnimation: flags.animation,
                    ),
                  ),
                ),
              ),
            );

            for (final type in animatedFunctions.values) {
              expect(find.byType(type), findsNothing);
            }
            expect(find.byType(MfmAnimatedWrapper), findsNothing);
            final richTexts = tester.widgetList<RichText>(
              find.bySubtype<RichText>(),
            );
            final text = richTexts.singleWhere(
              (widget) => widget.text.toPlainText() == 'body',
            );
            final styles = _textStyles(text.text).toList();
            expect(styles, hasLength(1));
            expect(styles.single.fontSize, fn == 'tada' ? 21 : 14);
            expect(styles.single.fontWeight, FontWeight.bold);
            if (fn == 'rainbow') {
              expect(richTexts, hasLength(2));
              expect(find.byType(MfmStaticRainbowWidget), findsOneWidget);
              expect(find.byType(ShaderMask), findsNothing);
              expect(find.byType(MfmRainbowRichText), findsOneWidget);
            } else {
              expect(richTexts, hasLength(1));
              expect(find.byType(ShaderMask), findsNothing);
              text.text.visitChildren((span) {
                expect(span, isNot(isA<WidgetSpan>()));
                return true;
              });
            }
            await tester.pump(const Duration(seconds: 2));
            expect(tester.binding.transientCallbackCount, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }

      testWidgets('rainbowの静的フォールバックはspeedより優先される $flags', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: r'$[rainbow.speed=0s,delay=2s body]',
                config: MfmRenderConfig(
                  enableAdvancedMfm: flags.advanced,
                  enableAnimation: flags.animation,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(MfmRainbowWidget), findsNothing);
        expect(find.byType(MfmAnimatedWrapper), findsNothing);
        expect(find.byType(ShaderMask), findsNothing);
        expect(find.byType(MfmRainbowRichText), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      });
    }

    for (final fn in animatedFunctions.entries) {
      testWidgets('${fn.key}はadvanced切替で静的表示へ移行し再開できる', (tester) async {
        for (final enabled in [true, false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  text: '\$[${fn.key} body]',
                  config: MfmRenderConfig(enableAdvancedMfm: enabled),
                ),
              ),
            ),
          );
          expect(
            find.byType(fn.value),
            enabled ? findsOneWidget : findsNothing,
          );
          if (!enabled) {
            await tester.pump(const Duration(seconds: 2));
            expect(tester.binding.transientCallbackCount, 0);
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  });

  group('MfmText アニメーション共通テスト', () {
    testWidgets('複数のアニメーションを同時に使用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin 回転] $[jump ジャンプ] $[rainbow 虹色]',
            ),
          ),
        ),
      );

      await tester.pump();
      // 各アニメーションのウィジェットが生成される
      expect(find.byType(Transform), findsWidgets);
      expect(find.byType(ColorFiltered), findsNWidgets(3));
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('アニメーションをネストできる', (tester) async {
      // パース済みノードで明示的にネスト構造を作成
      final nodes = [
        const FnNode(
          name: 'spin',
          args: {},
          children: [
            FnNode(
              name: 'rainbow',
              args: {},
              children: [TextNode('ネスト')],
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              parsedNodes: nodes,
            ),
          ),
        ),
      );

      await tester.pump();
      // 両方のアニメーションが適用される
      expect(find.byType(Transform), findsWidgets);
      expect(find.byType(ColorFiltered), findsNWidgets(3));
      expect(find.byType(ShaderMask), findsNothing);
      // テキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, 'ネスト');
      });
      expect(hasText, isTrue);
    });

    testWidgets('アニメーションとスタイルを組み合わせできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin $[fg.color=ff0000 赤い回転]]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
      // テキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '赤い回転');
      });
      expect(hasText, isTrue);
    });

    testWidgets('アニメーションとテキストスタイル（太字）を組み合わせできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[jump **太字ジャンプ**]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);

      // RichTextがレンダリングされていることを確認
      expect(find.byType(RichText), findsWidgets);

      // テキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '太字ジャンプ');
      });
      expect(hasText, isTrue);
    });

    testWidgets('グローバルなenableAnimationフラグを尊重する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MfmText(
                  text: r'$[spin 有効]',
                ),
                MfmText(
                  text: r'$[spin 無効]',
                  config: MfmRenderConfig(enableAnimation: false),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // 有効な方はアニメーションが適用される
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      expect(transforms.length, greaterThan(0));

      // 両方のテキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasEnabledText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '有効');
      });
      final hasDisabledText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '無効');
      });
      expect(hasEnabledText, isTrue);
      expect(hasDisabledText, isTrue);
    });
  });

  group('MfmText 引数パーステスト', () {
    testWidgets('speed引数は文字列形式（"1.5s"）を受け付ける', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.speed=1.5s 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('delay引数は文字列形式（"0.5s"）を受け付ける', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.delay=0.5s 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('複数の引数を組み合わせることができる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.x,left,speed=2s,delay=0.5s 複合回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('不正なspeed値はデフォルト値にフォールバックする', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.speed=invalid 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      // エラーなくレンダリングされる
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('数値形式のspeed引数を受け付ける', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.speed=2 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('小数点形式のspeed引数を受け付ける', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.speed=0.5s 回転]',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText パフォーマンステスト', () {
    testWidgets('多数のアニメーションを含むMFMを処理できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MfmText(
                text: r'''
$[spin 1] $[jump 2] $[bounce 3] $[shake 4] $[twitch 5]
$[jelly 6] $[tada 7] $[rainbow 8] $[sparkle 9]
$[spin 10] $[jump 11] $[bounce 12] $[shake 13]
                ''',
              ),
            ),
          ),
        ),
      );

      // 初期レンダリングが完了する
      await tester.pump();

      // RichTextが生成されていることを確認
      expect(find.byType(RichText), findsWidgets);

      // いくつかのテキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText1 = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '1');
      });
      final hasText8 = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '8');
      });
      final hasText13 = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '13');
      });
      expect(hasText1, isTrue);
      expect(hasText8, isTrue);
      expect(hasText13, isTrue);
    });

    testWidgets('アニメーションの有効/無効を動的に切り替えられる', (tester) async {
      var enableAnimation = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    MfmText(
                      text: r'$[spin 回転]',
                      config: MfmRenderConfig(enableAnimation: enableAnimation),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          enableAnimation = !enableAnimation;
                        });
                      },
                      child: const Text('トグル'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();

      // 初期状態はアニメーション有効
      expect(find.byType(Transform), findsWidgets);

      // ボタンをタップして無効化
      await tester.tap(find.text('トグル'));
      await tester.pumpAndSettle();

      // テキストは引き続き表示される
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasText = richTexts.any((widget) {
        final span = widget.text;
        return _spanContainsText(span, '回転');
      });
      expect(hasText, isTrue);
    });
  });

  group('MfmText delay動作テスト', () {
    testWidgets('delay指定時にアニメーションが遅延して開始される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.delay=0.1s 遅延回転]',
            ),
          ),
        ),
      );

      // 初期レンダリング
      await tester.pump();

      // Transformが生成されていることを確認
      expect(find.byType(Transform), findsWidgets);

      // delayの時間を待つ
      await tester.pump(const Duration(milliseconds: 100));

      // アニメーションが開始されている（クラッシュしない）
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('delay=0sでは即座にアニメーションが開始される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.delay=0s 即座に回転]',
            ),
          ),
        ),
      );

      await tester.pump();

      // 即座にアニメーションが適用される
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('複数のアニメーションで異なるdelayを設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text:
                  r'$[spin.delay=0s A] '
                  r'$[jump.delay=0.1s B] '
                  r'$[bounce.delay=0.2s C]',
            ),
          ),
        ),
      );

      await tester.pump();

      // すべてのアニメーションが生成される
      expect(find.byType(Transform), findsWidgets);

      // 各delayの時間を待つ
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // すべてのアニメーションが動作している（クラッシュしない）
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('MfmText Transform詳細テスト', () {
    testWidgets('spin.xでperspective付きのTransformが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[spin.x 回転X]',
            ),
          ),
        ),
      );

      await tester.pump();

      // Transformが生成される
      expect(find.byType(Transform), findsWidgets);

      // Transform.alignmentが適切に設定されている
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final hasTransform = transforms.any((widget) {
        return widget.alignment == Alignment.center;
      });
      expect(hasTransform, isTrue);
    });

    testWidgets('bounceでtransform-origin: center bottomが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[bounce バウンド]',
            ),
          ),
        ),
      );

      await tester.pump();

      // Transformが生成される
      expect(find.byType(Transform), findsWidgets);

      // Transform.alignmentがbottomCenterに設定されている
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final hasBounceTransform = transforms.any((widget) {
        return widget.alignment == Alignment.bottomCenter;
      });
      expect(hasBounceTransform, isTrue);
    });
  });
}

Iterable<TextStyle> _textStyles(
  InlineSpan span, [
  TextStyle inherited = const TextStyle(),
]) sync* {
  if (span is TextSpan) {
    final style = inherited.merge(span.style);
    if (span.text?.isNotEmpty ?? false) {
      yield style;
    }
    for (final child in span.children ?? <InlineSpan>[]) {
      yield* _textStyles(child, style);
    }
  }
}

/// InlineSpanにテキストが含まれているかを再帰的に検索するヘルパー関数
bool _spanContainsText(InlineSpan span, String text) {
  if (span is TextSpan) {
    if (span.text != null && span.text!.contains(text)) {
      return true;
    }
    if (span.children != null) {
      for (final child in span.children!) {
        if (_spanContainsText(child, text)) {
          return true;
        }
      }
    }
  }
  return false;
}

Widget _twitchOrShake({
  required bool isShake,
  Key? key,
  Duration duration = const Duration(milliseconds: 500),
  Duration delay = Duration.zero,
  bool enabled = true,
  required Widget child,
}) => isShake
    ? MfmShakeWidget(
        key: key,
        duration: duration,
        delay: delay,
        enabled: enabled,
        child: child,
      )
    : MfmTwitchWidget(
        key: key,
        duration: duration,
        delay: delay,
        enabled: enabled,
        child: child,
      );

Future<void> _pumpTwitchOrShake(
  WidgetTester tester, {
  required bool isShake,
  Key? key,
  Duration duration = const Duration(milliseconds: 500),
  Duration delay = Duration.zero,
  bool enabled = true,
  bool tickerEnabled = true,
  Widget child = const Text('test'),
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: TickerMode(
        enabled: tickerEnabled,
        child: Center(
          child: _twitchOrShake(
            isShake: isShake,
            key: key,
            duration: duration,
            delay: delay,
            enabled: enabled,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _effectTransforms({required bool isShake, Finder? effect}) =>
    find.descendant(
      of: effect ?? find.byType(isShake ? MfmShakeWidget : MfmTwitchWidget),
      matching: find.byType(Transform),
    );

void _expectWaiting(
  WidgetTester tester, {
  required bool isShake,
  Finder? effect,
}) {
  final transforms = _effectTransforms(isShake: isShake, effect: effect);
  expect(transforms, findsWidgets);
  // 先頭はeffect自身。入れ子やchild自身のTransformを検査しない。
  expect(
    tester.widget<Transform>(transforms.first).transform.storage,
    orderedEquals(Matrix4.identity().storage),
  );
}

void _expectFirstKeyframe(
  WidgetTester tester, {
  required bool isShake,
  Finder? effect,
}) {
  _expectTwitchOrShakeTransform(
    tester,
    isShake: isShake,
    effect: effect,
    x: isShake ? -3 : 7,
    y: isShake ? -1 : -2,
    rotateDeg: -8,
  );
}

void _expectFirstMidpoint(WidgetTester tester, {required bool isShake}) {
  final q = const Cubic(.25, .1, .25, 1).transform(.5);
  _expectTwitchOrShakeTransform(
    tester,
    isShake: isShake,
    x: isShake ? -3 + 3 * q : 7 - 10 * q,
    y: isShake ? -1 : -2 + 3 * q,
    rotateDeg: -8 - 2 * q,
  );
}

void _expectTwitchOrShakeTransform(
  WidgetTester tester, {
  required bool isShake,
  required double x,
  required double y,
  double? rotateDeg,
  Finder? effect,
}) {
  final matrix = tester
      .widget<Transform>(
        _effectTransforms(isShake: isShake, effect: effect).first,
      )
      .transform;
  expect(matrix.storage[12], closeTo(x, 1e-9));
  expect(matrix.storage[13], closeTo(y, 1e-9));

  if (isShake) {
    final radians = rotateDeg! * math.pi / 180;
    expect(matrix.storage[0], closeTo(math.cos(radians), 1e-9));
    expect(matrix.storage[1], closeTo(math.sin(radians), 1e-9));
    expect(matrix.storage[4], closeTo(-math.sin(radians), 1e-9));
    expect(matrix.storage[5], closeTo(math.cos(radians), 1e-9));
  }
}

class _AnimationLifecycleProbe extends StatefulWidget {
  const _AnimationLifecycleProbe({
    super.key,
    required this.onInit,
    required this.onDispose,
  });

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_AnimationLifecycleProbe> createState() =>
      _AnimationLifecycleProbeState();
}

class _AnimationLifecycleProbeState extends State<_AnimationLifecycleProbe> {
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
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(20, 30),
    child: const Text('stateful child'),
  );
}
