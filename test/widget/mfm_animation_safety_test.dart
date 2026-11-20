import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_animated_wrapper.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_sparkle_widget.dart';

void main() {
  group('P1 巨大なspeedとdelayの安全性', () {
    final hugeSeconds = '${'9' * 307}s';
    for (final entry in <String, String>{
      '乗算がInfinityになる正数': hugeSeconds,
      '乗算がInfinityになる負数': '-$hugeSeconds',
      '変換時にInfinityになる正数': '${'9' * 310}s',
      '変換時にInfinityになる負数': '-${'9' * 310}s',
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
    for (final digits in [307, 310]) {
      for (final reverse in [false, true]) {
        testWidgets('$digits桁の負のdelayでもreverse=$reverseの位相は有限になる', (
          tester,
        ) async {
          _cleanUp(tester);
          double? value;
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: MfmAnimatedWrapper(
                duration: const Duration(milliseconds: 750),
                delay: MfmAnimatedWrapper.parseTime('-${'9' * digits}s')!,
                reverse: reverse,
                builder: (context, child, controller, progress) {
                  value = progress.value;
                  return child;
                },
                child: const Text('x'),
              ),
            ),
          );
          expect(value, isNotNull);
          expect(value!.isFinite, isTrue);
          expect(value, inInclusiveRange(0, 1));
          await tester.pump(const Duration(milliseconds: 137));
          expect(tester.takeException(), isNull);
          expect(value!.isFinite, isTrue);
          expect(value, inInclusiveRange(0, 1));
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

  group('followPlatformReducedMotion', () {
    bool isAnimating(WidgetTester tester) =>
        _descendants(find.byType(MfmAnimatedWrapper)).evaluate().isNotEmpty;

    Widget host(
      Widget child, {
      required bool reducedMotion,
      MfmRenderConfig? inherited,
    }) {
      var content = child;
      if (inherited != null) {
        content = MfmConfig(config: inherited, child: content);
      }
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: Scaffold(body: content),
        ),
      );
    }

    testWidgets('既定値はnullで、OS設定に追従する', (tester) async {
      _cleanUp(tester);
      expect(const MfmRenderConfig().followPlatformReducedMotion, isNull);
      const text = MfmText(text: r'$[spin x]');

      await tester.pumpWidget(host(reducedMotion: true, text));
      expect(isAnimating(tester), isFalse);
    });

    testWidgets('同じMfmTextのままMediaQueryの変更だけで静止と再開を切り替える', (tester) async {
      _cleanUp(tester);
      // 同一インスタンスを渡し、MediaQueryへの依存登録だけで再buildされることを確認する。
      const text = MfmText(text: r'$[spin x]');

      await tester.pumpWidget(host(reducedMotion: false, text));
      expect(isAnimating(tester), isTrue);

      await tester.pumpWidget(host(reducedMotion: true, text));
      expect(isAnimating(tester), isFalse);

      await tester.pumpWidget(host(reducedMotion: false, text));
      expect(isAnimating(tester), isTrue);
      final before = _transforms(tester);
      await tester.pump(const Duration(milliseconds: 137));
      expect(_transforms(tester), isNot(before));
    });

    testWidgets('falseはOS設定を無視してアニメーションを続ける', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(
        host(
          reducedMotion: true,
          const MfmText(
            text: r'$[spin x]',
            config: MfmRenderConfig(followPlatformReducedMotion: false),
          ),
        ),
      );
      expect(isAnimating(tester), isTrue);
      final before = _transforms(tester);
      await tester.pump(const Duration(milliseconds: 137));
      expect(_transforms(tester), isNot(before));
    });

    testWidgets('OS設定はenableAnimation=falseを再有効化しない', (tester) async {
      _cleanUp(tester);
      for (final follow in [null, true, false]) {
        await tester.pumpWidget(
          host(
            reducedMotion: false,
            MfmText(
              text: r'$[spin x]',
              config: MfmRenderConfig(
                enableAnimation: false,
                followPlatformReducedMotion: follow,
              ),
            ),
          ),
        );
        expect(isAnimating(tester), isFalse, reason: 'follow=$follow');
      }
    });

    testWidgets('MediaQueryがなくても既定値で例外を出さずアニメーションする', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MfmText(text: r'$[spin x]'),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(isAnimating(tester), isTrue);
    });

    for (final entry in <String, (bool?, bool?, bool)>{
      '親true・子false': (true, false, true),
      '親false・子true': (false, true, false),
      '親false・子null': (false, null, true),
      '親true・子null': (true, null, false),
    }.entries) {
      testWidgets('継承: ${entry.key}', (tester) async {
        _cleanUp(tester);
        final (parent, child, animates) = entry.value;
        await tester.pumpWidget(
          host(
            reducedMotion: true,
            MfmText(
              text: r'$[spin x]',
              config: MfmRenderConfig(followPlatformReducedMotion: child),
            ),
            inherited: MfmRenderConfig(followPlatformReducedMotion: parent),
          ),
        );
        expect(isAnimating(tester), animates);
      });
    }

    test('copyWithは値を維持し、明示した値で上書きする', () {
      const config = MfmRenderConfig(followPlatformReducedMotion: false);
      expect(
        config.copyWith(enableNyaize: true).followPlatformReducedMotion,
        isFalse,
      );
      expect(
        config
            .copyWith(followPlatformReducedMotion: true)
            .followPlatformReducedMotion,
        isTrue,
      );
      // useAnimationは設定値だけで決まり、OS設定を含まない。
      expect(config.useAnimation, isTrue);
    });

    test('MfmEmojiConfigHandleのcopyWithでも値を転送する', () async {
      final dir = await Directory.systemTemp.createTemp('mfm_reduced_motion');
      addTearDown(() => dir.delete(recursive: true));
      final handle = await MfmEmojiConfig.createDefault(
        client: MisskeyClient(
          config: MisskeyClientConfig(
            baseUrl: Uri.parse('https://example.com'),
          ),
        ),
        storagePath: dir.path,
        autoSync: false,
        emojiStoreFactory:
            ({required Uri serverUrl, required String directory}) =>
                _EmptyEmojiStore(),
      );
      addTearDown(handle.dispose);

      expect(handle.followPlatformReducedMotion, isNull);
      final copied = handle.copyWith(followPlatformReducedMotion: false);
      final preserved = copied.copyWith(enableAnimation: false);
      for (final value in [copied, preserved]) {
        expect(value, isA<MfmEmojiConfigHandle>());
        expect(value.followPlatformReducedMotion, isFalse);
      }
      // 永続ストアの作成にファイルシステムを使うため、Webでは実行しない。
    }, skip: kIsWeb);
  });

  group('sparkleのTicker時計', () {
    Widget host({bool enabled = true, bool tickerEnabled = true}) =>
        Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: tickerEnabled,
            child: Center(
              child: MfmSparkleWidget(
                enabled: enabled,
                child: const SizedBox(width: 100, height: 30),
              ),
            ),
          ),
        );

    CustomPainter painter(WidgetTester tester) => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(MfmSparkleWidget),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    List<({Duration startTime, Duration duration, double progress})> frames(
      WidgetTester tester,
    ) => MfmSparkleWidget.debugParticleFrames(painter(tester));

    testWidgets('最初の粒子は500〜999ms待ち、描画進行は全寿命を分母にする', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 499));
      expect(frames(tester), isEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      final first = frames(tester).single;
      expect(first.startTime, const Duration(milliseconds: 999));
      expect(first.progress, 0);

      await tester.pump(const Duration(milliseconds: 100));
      final progressed = frames(tester).single;
      expect(
        progressed.progress,
        closeTo(100000 / first.duration.inMicroseconds, 1e-10),
      );
    });

    testWidgets('粒子はstart + duration - 100msのフレームで削除する', (tester) async {
      _cleanUp(tester);
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final first = frames(tester).single;
      final lifetime = first.duration - const Duration(milliseconds: 100);
      await tester.pump(lifetime - const Duration(microseconds: 1));
      expect(
        frames(
          tester,
        ).where((particle) => particle.startTime == first.startTime),
        hasLength(1),
      );
      await tester.pump(const Duration(microseconds: 1));
      expect(
        frames(
          tester,
        ).where((particle) => particle.startTime == first.startTime),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });

    for (final pause in [const Duration(seconds: 3), const Duration(days: 1)]) {
      testWidgets('粒子がある状態で$pause muteしても変更せず、復帰時に最大1個生成する', (
        tester,
      ) async {
        _cleanUp(tester);
        await tester.pumpWidget(host());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(frames(tester), hasLength(1));
        await tester.pumpWidget(host(tickerEnabled: false));
        final frozenPainter = painter(tester);
        final frozenParticles = frames(tester);
        await tester.pump(pause);
        expect(painter(tester), same(frozenPainter));
        expect(frames(tester), frozenParticles);

        await tester.pumpWidget(host());
        await tester.pump();
        final resumed = frames(tester).single;
        expect(
          resumed.startTime,
          greaterThan(frozenParticles.single.startTime),
        );
        expect(resumed.progress, 0);
        // 次の生成は復帰tickから新たに500〜999ms待つ。
        await tester.pump(const Duration(milliseconds: 499));
        expect(frames(tester), hasLength(1));
        await tester.pump(const Duration(milliseconds: 500));
        final next = frames(tester).where(
          (particle) => particle.startTime > resumed.startTime,
        );
        expect(next, hasLength(1));
        expect(frames(tester).length, lessThanOrEqualTo(2));
        expect(tester.takeException(), isNull);
      });
    }

    for (final initiallyMuted in [false, true]) {
      testWidgets('enabledの再始動は粒子と生成時計をリセットする (mute: $initiallyMuted)', (
        tester,
      ) async {
        _cleanUp(tester);
        await tester.pumpWidget(host());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(frames(tester), hasLength(1));
        await tester.pumpWidget(host(enabled: false));
        expect(find.byType(CustomPaint), findsNothing);
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpWidget(host(tickerEnabled: !initiallyMuted));
        if (initiallyMuted) {
          await tester.pump(const Duration(seconds: 10));
          expect(frames(tester), isEmpty);
          await tester.pumpWidget(host());
        }
        await tester.pump();
        expect(frames(tester), isEmpty);
        await tester.pump(const Duration(milliseconds: 499));
        expect(frames(tester), isEmpty);
        await tester.pump(const Duration(milliseconds: 500));
        final first = frames(tester).single;
        expect(first.startTime, const Duration(milliseconds: 999));
        expect(first.progress, 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('dispose後はTickerもTimerも残らない', (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(frames(tester), hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 10));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
      // testWidgetsのpending Timer検査も通すため、削除待ちTimerは許容しない。
    });

    for (final lifecycle in [
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      testWidgets('$lifecycleでフレーム供給が止まる間は粒子を更新しない', (tester) async {
        _cleanUp(tester);
        addTearDown(() {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        });
        await tester.pumpWidget(host());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        tester.binding.handleAppLifecycleStateChanged(lifecycle);
        // 停止前に予約された1フレームだけを同じ時刻で消化する。
        await tester.pump();
        final before = painter(tester);
        final particles = frames(tester);
        await tester.pump(const Duration(seconds: 3));
        expect(painter(tester), same(before));
        expect(frames(tester), particles);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(frames(tester), hasLength(1));
        expect(
          frames(tester).single.startTime,
          greaterThan(particles.single.startTime),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('inactiveはフレーム供給が続くため描画も進む', (tester) async {
      _cleanUp(tester);
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final before = painter(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter(tester), isNot(same(before)));
      expect(frames(tester).single.progress, greaterThan(0));
      expect(tester.takeException(), isNull);
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

class _EmptyEmojiStore implements EmojiStore {
  @override
  Future<EmojiSnapshot> load() async =>
      const EmojiSnapshot(records: [], syncedAt: null);

  @override
  Future<void> save(
    List<EmojiRecord> all, {
    required DateTime syncedAt,
  }) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<int> count() async => 0;

  @override
  Future<int?> sizeInBytes() async => null;

  @override
  Future<void> dispose() async {}
}
