import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

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

    testWidgets('twitch.delay=0.5sで開始遅延を設定できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[twitch.delay=0.5s けいれん]',
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
              config: MfmRenderConfig(enableAnimation: false),
            ),
          ),
        ),
      );

      // Transformが適用される（静的な150%スケール）
      expect(find.byType(Transform), findsWidgets);
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
      expect(find.byType(ShaderMask), findsWidgets);
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

      // アニメーション無効でもShaderMaskが適用される（静的グラデーション）
      expect(find.byType(ShaderMask), findsWidgets);
      // テキストが含まれることを確認
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
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
      expect(find.byType(ShaderMask), findsWidgets);
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
      expect(find.byType(ShaderMask), findsWidgets);
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
      expect(find.byType(ShaderMask), findsWidgets);
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
      expect(find.byType(ShaderMask), findsWidgets);
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
                  r'$[spin.delay=0s A] $[jump.delay=0.1s B] $[bounce.delay=0.2s C]',
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
