import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_spin_widget.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_code_block.dart';

void main() {
  group('MfmText 基本機能', () {
    testWidgets('プレーンテキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: 'Hello, World!')),
        ),
      );

      // MfmTextはRichTextを使用するため、TextSpanの内容を確認する
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final foundSpan = _findSpanWithText(textSpan, 'Hello, World!');
      expect(foundSpan, isNotNull);
    });

    testWidgets('空のテキストでもエラーなくレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '')),
        ),
      );

      // 例外がスローされないことを確認
      expect(find.byType(MfmText), findsOneWidget);
    });

    testWidgets('parsedNodesを直接渡してレンダリングできる', (tester) async {
      final nodes = [const TextNode('Direct nodes')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MfmText(parsedNodes: nodes)),
        ),
      );

      // MfmTextはRichTextを使用するため、TextSpanの内容を確認する
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final foundSpan = _findSpanWithText(textSpan, 'Direct nodes');
      expect(foundSpan, isNotNull);
    });

    testWidgets('configのbaseTextStyleが適用される', (tester) async {
      const testStyle = TextStyle(fontSize: 20, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'Styled text',
              config: MfmRenderConfig(baseTextStyle: testStyle),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      expect(textSpan.style?.fontSize, 20);
      expect(textSpan.style?.color, Colors.red);
    });
  });

  group('MfmText smallの親相対サイズと減光', () {
    const baseStyle = TextStyle(fontSize: 14, color: Colors.blue);
    final textCases = [
      (name: '単独', text: '<small>abc</small>', size: 11.2, alpha: 0.7),
      (
        name: 'サイズ関数の内側',
        text: r'$[x2 <small>abc</small>]',
        size: 22.4,
        alpha: 0.7,
      ),
      (
        name: '二重のsmall',
        text: '<small><small>abc</small></small>',
        size: 8.96,
        alpha: 0.49,
      ),
      (
        name: 'サイズ関数を挟む二重のsmall',
        text: r'<small>$[x2 <small>abc</small>]</small>',
        size: 17.92,
        alpha: 0.49,
      ),
    ];
    for (final testCase in textCases) {
      testWidgets('${testCase.name}は継承サイズと色のalphaに倍率を掛ける', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: testCase.text,
                config: const MfmRenderConfig(baseTextStyle: baseStyle),
              ),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText));
        final style = _effectiveStyleForText(richText.text as TextSpan, 'abc');
        expect(style, isNotNull);
        expect(style!.fontSize, closeTo(testCase.size, 0.000001));
        expect(style.color!.a, closeTo(testCase.alpha, 0.000001));
        expect(find.byType(Opacity), findsNothing);
      });
    }

    testWidgets('半透明の継承色のalphaを置換せず乗算する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '<small>abc</small>',
              config: MfmRenderConfig(
                baseTextStyle: baseStyle.copyWith(
                  color: Colors.blue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final style = _effectiveStyleForText(richText.text as TextSpan, 'abc');
      expect(style!.color!.a, closeTo(0.35, 0.000001));
    });

    for (final depth in [0, 1, 2]) {
      testWidgets('前景色指定にもsmallを$depth回分だけ適用する', (tester) async {
        final text =
            '${'<small>' * depth}'
            r'$[fg.color=f00 abc]'
            '${'</small>' * depth}';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: text,
                config: const MfmRenderConfig(baseTextStyle: baseStyle),
              ),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText));
        final style = _effectiveStyleForText(richText.text as TextSpan, 'abc');
        // 本家のopacityはスタッキングコンテキストを作るため、
        // 子のfgでも減光を上書きできない。
        expect(style!.color!.withValues(alpha: 1), const Color(0xFFFF0000));
        expect(
          style.color!.a,
          closeTo(
            depth == 0
                ? 1.0
                : depth == 1
                ? 0.7
                : 0.49,
            0.000001,
          ),
        );
      });
    }

    final linkCases = [
      (name: 'リンク', text: '[link](https://example.com)', label: 'link'),
      (name: 'URL', text: 'https://example.com', label: 'https://example.com'),
      (name: 'メンション', text: '@user', label: '@user'),
      (name: 'ハッシュタグ', text: '#tag', label: '#tag'),
    ];
    for (final testCase in linkCases) {
      for (final depth in [0, 1, 2]) {
        testWidgets('${testCase.name}色にもsmallを$depth回分だけ適用する', (tester) async {
          final text =
              '${'<small>' * depth}${testCase.text}${'</small>' * depth}';
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  text: text,
                  config: const MfmRenderConfig(baseTextStyle: baseStyle),
                ),
              ),
            ),
          );

          final richText = tester.widget<RichText>(find.byType(RichText));
          final style = _effectiveStyleForText(
            richText.text as TextSpan,
            testCase.label,
          );
          expect(style, isNotNull);
          expect(
            style!.color!.withValues(alpha: 1),
            const Color(0xFF0066CC),
          );
          expect(
            style.color!.a,
            closeTo(
              depth == 0
                  ? 1.0
                  : depth == 1
                  ? 0.7
                  : 0.49,
              0.000001,
            ),
          );
        });
      }
    }

    testWidgets('継承色が未指定なら色patchを追加しない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '<small>abc</small>',
              config: MfmRenderConfig(baseTextStyle: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final style = _effectiveStyleForText(richText.text as TextSpan, 'abc');
      expect(style!.fontSize, closeTo(11.2, 0.000001));
      expect(style.color, isNull);
    });

    for (final emoji in [':emoji:', '😀']) {
      for (final depth in [0, 1, 2]) {
        testWidgets('$emojiのビルダー結果にsmallを$depth回分だけ適用する', (tester) async {
          const emojiKey = Key('small-emoji');
          final text = '${'<small>' * depth}$emoji${'</small>' * depth}';
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  text: text,
                  config: MfmRenderConfig(
                    baseTextStyle: baseStyle,
                    emojiBuilder: (_, _) =>
                        const SizedBox(key: emojiKey, width: 24, height: 24),
                    unicodeEmojiBuilder: (_, _) =>
                        const SizedBox(key: emojiKey, width: 24, height: 24),
                  ),
                ),
              ),
            ),
          );

          final emojiFinder = find.byKey(emojiKey);
          expect(emojiFinder, findsOneWidget);
          final opacityFinder = find.ancestor(
            of: emojiFinder,
            matching: find.byType(Opacity),
          );
          if (depth == 0) {
            expect(opacityFinder, findsNothing);
          } else {
            expect(opacityFinder, findsOneWidget);
            final opacity = tester.widget<Opacity>(opacityFinder);
            expect(opacity.opacity, closeTo(depth == 1 ? 0.7 : 0.49, 0.000001));
            expect(opacity.child, same(tester.widget(emojiFinder)));
          }
        });
      }
    }

    for (final testCase in [
      (name: 'インライン数式', source: r'\(x\)'),
      (name: 'ブロック数式', source: r'\[x\]'),
    ]) {
      for (final depth in [0, 1, 2]) {
        testWidgets('${testCase.name}はsmallを$depth回分だけ文字色のalphaで減光する', (
          tester,
        ) async {
          // ブロック数式の構文制約と分離して、両ノードの継承を検証する。
          var nodes = MfmParser().build().parse(testCase.source).value;
          for (var i = 0; i < depth; i++) {
            nodes = [SmallNode(nodes)];
          }
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  parsedNodes: nodes,
                  config: const MfmRenderConfig(baseTextStyle: baseStyle),
                ),
              ),
            ),
          );

          final root =
              tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
          final formula = _findSpanWithStyle(
            root,
            (style) => style?.fontFamily == 'monospace',
          );
          expect(formula?.text, 'x');
          final style = _effectiveStyleForText(root, 'x')!;
          expect(style.fontSize, closeTo([14.0, 11.2, 8.96][depth], 0.000001));
          expect(style.color!.a, closeTo([1.0, 0.7, 0.49][depth], 0.000001));
          expect(_firstWidgetSpan(root), isNull);
          expect(find.byType(Container), findsNothing);
          expect(find.byType(Opacity), findsNothing);
        });
      }
    }

    testWidgets('small内のインライン数式構文は文字色のalphaが0.7になる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'<small>\(x\)</small>',
              config: MfmRenderConfig(baseTextStyle: baseStyle),
            ),
          ),
        ),
      );

      final root =
          tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
      final style = _effectiveStyleForText(root, 'x')!;
      expect(style.fontFamily, 'monospace');
      expect(style.color!.a, closeTo(0.7, 0.000001));
      expect(find.byType(Opacity), findsNothing);
    });

    final widgetCases = [
      (name: 'コードブロック', source: '```\ncode\n```'),
      (name: '検索', source: 'keyword Search'),
      (name: '日時', source: r'$[unixtime 1700000000]'),
      (name: 'ルビ', source: r'$[ruby 漢字 かんじ]'),
    ];
    for (final testCase in widgetCases) {
      for (final depth in [0, 1, 2]) {
        testWidgets('${testCase.name}の独自描画にsmallを$depth回分だけ適用する', (
          tester,
        ) async {
          // ブロック要素も含め、small配下の描画をパーサーの構文制約と分離して検証。
          var nodes = MfmParser().build().parse(testCase.source).value;
          for (var i = 0; i < depth; i++) {
            nodes = [SmallNode(nodes)];
          }
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  parsedNodes: nodes,
                  config: const MfmRenderConfig(baseTextStyle: baseStyle),
                ),
              ),
            ),
          );

          final root = tester.widget<RichText>(find.byType(RichText).first);
          final widgetSpan = _firstWidgetSpan(root.text as TextSpan);
          expect(widgetSpan, isNotNull);
          final child = widgetSpan!.child;
          final opacityFinder = find.ancestor(
            of: find.byWidget(child is Opacity ? child.child! : child),
            matching: find.byType(Opacity),
          );
          if (depth == 0) {
            // コードブロックのコピーボタン内にあるOpacityは対象外。
            expect(child, isNot(isA<Opacity>()));
            expect(opacityFinder, findsNothing);
          } else {
            expect(child, isA<Opacity>());
            expect(opacityFinder, findsOneWidget);
            final opacity = child as Opacity;
            expect(opacity.opacity, closeTo(depth == 1 ? 0.7 : 0.49, 0.000001));
            if (testCase.name != 'コードブロック' && testCase.name != 'ルビ') {
              expect(opacity.child, isA<Container>());
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final backgroundCase in [
      (name: '標準背景', light: null, dark: null),
      (
        name: '半透明のカスタム背景',
        light: const Color(0x80667788),
        dark: const Color(0x80443322),
      ),
    ]) {
      for (final brightness in Brightness.values) {
        for (final depth in [0, 1, 2]) {
          testWidgets('インラインコードの${backgroundCase.name}は${brightness.name}でも'
              'smallを$depth回分だけ文字と背景に個別適用する', (tester) async {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: Scaffold(
                  body: MfmText(
                    text: '${'<small>' * depth}`code`${'</small>' * depth}',
                    config: MfmRenderConfig(
                      baseTextStyle: baseStyle,
                      inlineCodeBgColorLight: backgroundCase.light,
                      inlineCodeBgColorDark: backgroundCase.dark,
                    ),
                  ),
                ),
              ),
            );

            final alpha = [1.0, 0.7, 0.49][depth];
            final style = tester.widget<Text>(find.text('code')).style!;
            expect(
              style.fontSize,
              closeTo([14.0, 11.2, 8.96][depth], 0.000001),
            );
            expect(style.color!.withValues(alpha: 1), const Color(0xFF2196F3));
            expect(style.color!.a, closeTo(alpha, 0.000001));
            final container = tester.widget<Container>(
              find.ancestor(
                of: find.text('code'),
                matching: find.byType(Container),
              ),
            );
            final background = (container.decoration! as BoxDecoration).color!;
            final originalBackground = brightness == Brightness.dark
                ? (backgroundCase.dark ?? const Color(0xFF121212))
                : (backgroundCase.light ?? const Color(0xFFF5F5F5));
            expect(
              background.a,
              closeTo(originalBackground.a * alpha, 0.000001),
            );
            expect(
              background.withValues(alpha: 1),
              originalBackground.withValues(alpha: 1),
            );
            expect(find.byType(Opacity), findsNothing);
          });
        }
      }
    }

    for (final depth in [0, 1]) {
      testWidgets('引用の罫線と文字を別々に減光し絵文字を二重に減光しない(small $depth回)', (
        tester,
      ) async {
        const emojiKey = Key('quoted-emoji');
        var nodes = MfmParser().build().parse('> abc :emoji:').value;
        for (var i = 0; i < depth; i++) {
          nodes = [SmallNode(nodes)];
        }
        // 引用は本家QUOTE_STYLEと同じく要素全体に0.7を掛けるため、
        // smallの累積不透明度と乗算される。
        final expected = depth == 0 ? 0.7 : 0.49;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                parsedNodes: nodes,
                config: MfmRenderConfig(
                  baseTextStyle: baseStyle,
                  emojiBuilder: (_, _) =>
                      const SizedBox(key: emojiKey, width: 24, height: 24),
                ),
              ),
            ),
          ),
        );

        final root = tester.widget<RichText>(find.byType(RichText).first);
        final container =
            _firstWidgetSpan(root.text as TextSpan)!.child as Container;
        final border =
            (container.decoration! as BoxDecoration).border! as Border;
        expect(border.left.color.a, closeTo(expected, 0.000001));
        final innerText = container.child! as RichText;
        expect(
          innerText.text.style!.fontSize,
          closeTo(depth == 0 ? 14 : 11.2, 0.000001),
        );
        expect(innerText.text.style!.color!.a, closeTo(expected, 0.000001));
        expect(
          find.ancestor(
            of: find.byWidget(container),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        final opacityFinder = find.ancestor(
          of: find.byKey(emojiKey),
          matching: find.byType(Opacity),
        );
        expect(opacityFinder, findsOneWidget);
        expect(
          tester.widget<Opacity>(opacityFinder).opacity,
          closeTo(expected, 0.000001),
        );
      });
    }

    testWidgets('変形とアニメーションを越えて減光を維持し兄弟へ漏らさない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text:
                  r'<small>**$[scale.x=2 $[x2 $[spin <small>abc :inner:</small>]]]**</small> :sibling:',
              config: MfmRenderConfig(
                baseTextStyle: baseStyle,
                emojiBuilder: (name, _) =>
                    SizedBox(key: Key(name), width: 24, height: 24),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final richTextFinder = find.descendant(
        of: find.byType(MfmSpinWidget),
        matching: find.byType(RichText),
      );
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      final style = _effectiveStyleForText(richText.text as TextSpan, 'abc ');
      expect(style!.fontSize, closeTo(17.92, 0.000001));
      expect(style.color!.a, closeTo(0.49, 0.000001));
      expect(
        find.ancestor(of: richTextFinder, matching: find.byType(Opacity)),
        findsNothing,
      );
      final innerOpacity = find.ancestor(
        of: find.byKey(const Key('inner')),
        matching: find.byType(Opacity),
      );
      expect(innerOpacity, findsOneWidget);
      expect(
        tester.widget<Opacity>(innerOpacity).opacity,
        closeTo(0.49, 0.000001),
      );
      expect(
        find.ancestor(
          of: find.byKey(const Key('sibling')),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    for (final function in ['bg.color=f00', 'border.color=f00']) {
      testWidgets('$functionの装飾色だけを減光し文字を二重に減光しない', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '<small>\$[$function abc]</small>',
                config: const MfmRenderConfig(baseTextStyle: baseStyle),
              ),
            ),
          ),
        );

        final root = tester.widget<RichText>(find.byType(RichText).first);
        final child = _firstWidgetSpan(root.text as TextSpan)!.child;
        final Color decorationColor;
        final RichText innerText;
        if (child is ColoredBox) {
          decorationColor = child.color;
          innerText = child.child! as RichText;
        } else {
          final container = child as Container;
          final border =
              (container.decoration! as BoxDecoration).border! as Border;
          decorationColor = border.top.color;
          innerText = container.child! as RichText;
        }
        expect(decorationColor.a, closeTo(0.7, 0.000001));
        expect(innerText.text.style!.color!.a, closeTo(0.7, 0.000001));
        expect(find.byType(Opacity), findsNothing);
      });
    }
  });

  group('MfmText インライン要素', () {
    testWidgets('太字テキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '**bold**')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // 太字スタイルを持つ子Spanを検索
      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNotNull);
    });

    testWidgets('斜体テキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '<i>italic</i>')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final italicSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontStyle == FontStyle.italic,
      );
      expect(italicSpan, isNotNull);
    });

    testWidgets('取り消し線テキストをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '~~strike~~')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final strikeSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.decoration == TextDecoration.lineThrough,
      );
      expect(strikeSpan, isNotNull);
    });

    testWidgets('小さいテキストを縮小サイズでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '<small>small</small>',
              config: MfmRenderConfig(baseTextStyle: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final smallSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontSize != null && style!.fontSize! < 14,
      );
      expect(smallSpan, isNotNull);
    });

    for (final testCase in [
      (name: '単独', source: '`code`', size: 14.0, padding: 1.4, radius: 4.2),
      (
        name: 'サイズ関数の内側',
        source: r'$[x2 `code`]',
        size: 28.0,
        padding: 2.8,
        radius: 8.4,
      ),
    ]) {
      testWidgets('${testCase.name}のインラインコードは継承サイズとem相対の装飾を使う', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: testCase.source,
                config: const MfmRenderConfig(
                  baseTextStyle: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('code'));
        expect(text.style!.fontSize, testCase.size);
        expect(text.style!.color, Colors.blue);
        expect(text.style!.fontFamily, 'Consolas');
        expect(text.style!.fontFamilyFallback, [
          'Monaco',
          'Andale Mono',
          'Ubuntu Mono',
          'monospace',
        ]);
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('code'),
            matching: find.byType(Container),
          ),
        );
        final padding = container.padding! as EdgeInsets;
        for (final inset in [
          padding.left,
          padding.top,
          padding.right,
          padding.bottom,
        ]) {
          expect(inset, closeTo(testCase.padding, 0.000001));
        }
        final decoration = container.decoration! as BoxDecoration;
        final radius = decoration.borderRadius! as BorderRadius;
        for (final corner in [
          radius.topLeft,
          radius.topRight,
          radius.bottomLeft,
          radius.bottomRight,
        ]) {
          expect(corner.x, closeTo(testCase.radius, 0.000001));
          expect(corner.y, closeTo(testCase.radius, 0.000001));
        }
        expect(decoration.color, const Color(0xFFF5F5F5));
        final root = tester.widget<RichText>(find.byType(RichText).first);
        final span = _firstWidgetSpan(root.text as TextSpan)!;
        expect(span.alignment, PlaceholderAlignment.baseline);
        expect(span.baseline, TextBaseline.alphabetic);
      });
    }

    testWidgets('インラインコードは親の太字と前景色を継承する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'**`code`** **$[fg.color=f00 `colored`]**',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      final codeStyle = tester.widget<Text>(find.text('code')).style!;
      expect(codeStyle.fontWeight, FontWeight.bold);
      expect(codeStyle.fontSize, 14);
      final coloredStyle = tester.widget<Text>(find.text('colored')).style!;
      expect(coloredStyle.fontWeight, FontWeight.bold);
      expect(coloredStyle.color, const Color(0xFFFF0000));
    });

    testWidgets('URLをリンク色でレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: 'https://example.com')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final linkSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.color == const Color(0xFF0066CC),
      );
      expect(linkSpan, isNotNull);
    });

    testWidgets('メンションをリンク色でレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '@user')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final mentionSpan = _findSpanWithText(textSpan, '@user');
      expect(mentionSpan, isNotNull);
    });

    testWidgets('ハッシュタグを#付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '#misskey')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final hashtagSpan = _findSpanWithText(textSpan, '#misskey');
      expect(hashtagSpan, isNotNull);
    });

    testWidgets('カスタム絵文字をビルダーでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: ':custom:',
              config: MfmRenderConfig(
                emojiBuilder: (name, _) => Container(
                  key: Key('emoji-$name'),
                  width: 24,
                  height: 24,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('emoji-custom')), findsOneWidget);
    });

    testWidgets('emojiBuilderに絵文字名が渡される', (tester) async {
      var builderCalled = false;
      String? receivedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'Hello :custom: World',
              config: MfmRenderConfig(
                emojiBuilder: (name, _) {
                  builderCalled = true;
                  receivedName = name;
                  return Container(
                    key: Key('emoji-$name'),
                    width: 24,
                    height: 24,
                    color: Colors.green,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(builderCalled, isTrue);
      expect(receivedName, equals('custom'));
      expect(find.byKey(const Key('emoji-custom')), findsOneWidget);
    });

    testWidgets('ビルダーがない場合、カスタム絵文字をテキストとしてレンダリングする', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: ':custom:')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final emojiSpan = _findSpanWithText(textSpan, ':custom:');
      expect(emojiSpan, isNotNull);
    });

    testWidgets('Unicode絵文字をレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '😀')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final emojiSpan = _findSpanWithText(textSpan, '😀');
      expect(emojiSpan, isNotNull);
    });

    testWidgets('Unicode絵文字をビルダーでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '😀',
              config: MfmRenderConfig(
                unicodeEmojiBuilder: (emoji, _) => Container(
                  key: Key('unicode-$emoji'),
                  width: 24,
                  height: 24,
                  color: Colors.yellow,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('unicode-😀')), findsOneWidget);
    });

    testWidgets('plainブロック内ではMFMがパースされない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '<plain>**not bold**</plain>')),
        ),
      );

      // plainブロック内では**は太字としてパースされない
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNull);
    });
  });

  group('MfmText ブロック要素', () {
    testWidgets('引用ブロックを左ボーダー付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '> quote')),
        ),
      );

      // 引用ブロックはボーダー装飾付きのContainerを使用
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('中央寄せブロックをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '<center>centered</center>')),
        ),
      );

      // 中央寄せブロックは幅いっぱいのSizedBoxを使用
      final sizedBox = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final fullWidthBox = sizedBox.any((box) => box.width == double.infinity);
      expect(fullWidthBox, isTrue);
    });

    testWidgets('コードブロックをコード内容付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '```\ncode block\n```')),
        ),
      );

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.code, 'code block');
    });

    testWidgets('コードブロックが言語指定付きでシンタックスハイライトされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '```dart\nvoid main() {}\n```')),
        ),
      );

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.code, 'void main() {}');
      expect(codeBlock.language, 'dart');
    });

    testWidgets('言語指定なしのコードブロックがプレーンテキストで表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '```\nplain text code\n```')),
        ),
      );

      expect(find.byType(MfmCodeBlock), findsOneWidget);
      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.code, 'plain text code');
      expect(codeBlock.language, isNull);
    });

    testWidgets('カスタムコードテーマが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '```dart\nvar x = 1;\n```',
              config: MfmRenderConfig(codeTheme: draculaTheme),
            ),
          ),
        ),
      );

      final codeBlock = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
      expect(codeBlock.theme, draculaTheme);
    });

    testWidgets('コピーボタンの表示/非表示が制御できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '```dart\ncode\n```',
              config: MfmRenderConfig(showCodeBlockCopyButton: false),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MfmCodeBlock),
          matching: find.byIcon(Icons.content_copy),
        ),
        findsNothing,
      );
    });

    for (final testCase in [
      (name: 'ブロック数式', source: r'\[x^2\]'),
      (name: 'インライン数式', source: r'\(x^2\)'),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('${testCase.name}は${brightness.name}でも装飾のない等幅TextSpanになる', (
          tester,
        ) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: MfmText(
                  text: testCase.source,
                  config: const MfmRenderConfig(
                    baseTextStyle: TextStyle(fontSize: 14, color: Colors.blue),
                    inlineCodeBgColorLight: Colors.red,
                    inlineCodeBgColorDark: Colors.green,
                  ),
                ),
              ),
            ),
          );

          final richText = tester.widget<RichText>(find.byType(RichText));
          final root = richText.text as TextSpan;
          final formula = _findSpanWithStyle(
            root,
            (style) => style?.fontFamily == 'monospace',
          );
          expect(formula?.text, 'x^2');
          expect(formula!.style!.fontSize, isNull);
          expect(formula.style!.color, isNull);
          final style = _effectiveStyleForText(root, 'x^2')!;
          expect(style.fontSize, 14);
          expect(style.color, Colors.blue);
          expect(style.backgroundColor, isNull);
          expect(_firstWidgetSpan(root), isNull);
          expect(richText.textAlign, TextAlign.start);
          expect(find.byType(Container), findsNothing);
          expect(find.byType(Opacity), findsNothing);
          expect(
            find.descendant(
              of: find.byType(MfmText),
              matching: find.byType(SizedBox),
            ),
            findsNothing,
          );
        });
      }
    }

    testWidgets('サイズ関数内の数式は親の28pxを継承する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x2 \(x^2\)]',
              config: MfmRenderConfig(baseTextStyle: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      );

      final root =
          tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
      final formula = _findSpanWithStyle(
        root,
        (style) => style?.fontFamily == 'monospace',
      );
      expect(formula?.text, 'x^2');
      expect(formula!.style!.fontSize, isNull);
      expect(_effectiveStyleForText(root, formula.text!)!.fontSize, 28);
      expect(_firstWidgetSpan(root), isNull);
    });

    for (final testCase in [
      (name: '改行あり', separator: '\n'),
      (name: '改行なし', separator: ''),
    ]) {
      testWidgets('数式ブロックは${testCase.name}のTextNodeを保持し改行を追加しない', (
        tester,
      ) async {
        final nodes = [
          TextNode('before${testCase.separator}'),
          ...MfmParser().build().parse(r'\[x^2\]').value,
          TextNode('${testCase.separator}after'),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                parsedNodes: nodes,
                config: const MfmRenderConfig(
                  baseTextStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        );

        final root =
            tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
        expect(_findSpanWithText(root, 'x^2')!.style!.fontFamily, 'monospace');
        expect(
          root.toPlainText(),
          'before${testCase.separator}x^2${testCase.separator}after',
        );
        expect(_firstWidgetSpan(root), isNull);
        expect(find.byType(Container), findsNothing);
      });
    }

    testWidgets('検索ブロックをボタン付きでレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: 'test query 検索')),
        ),
      );

      expect(find.text('test query'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });
  });

  group('MfmText コールバック', () {
    testWidgets('URLタップ時にonLinkTapが呼ばれる', (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'https://example.com',
              config: MfmRenderConfig(onLinkTap: (url) => tappedUrl = url),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // URLスパンを検索
      final linkSpan = _findSpanWithText(textSpan, 'https://example.com');
      expect(linkSpan, isNotNull);

      // recognizerを呼び出してタップをシミュレート
      final recognizer = linkSpan?.recognizer;
      if (recognizer is TapGestureRecognizer) {
        recognizer.onTap?.call();
      }

      expect(tappedUrl, 'https://example.com');
    });

    testWidgets('メンションタップ時にonMentionTapが呼ばれる', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@user@example.com',
              config: MfmRenderConfig(
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final mentionSpan = _findSpanWithText(textSpan, '@user@example.com');
      expect(mentionSpan, isNotNull);

      final mentionRecognizer = mentionSpan?.recognizer;
      if (mentionRecognizer is TapGestureRecognizer) {
        mentionRecognizer.onTap?.call();
      }

      expect(tappedMention, '@user@example.com');
    });

    testWidgets('リモート投稿者のホストで省略メンションを解決する', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                author: const MfmAuthorContext(host: 'remote.example'),
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@remote.example');
    });

    testWidgets('ローカル投稿者ではlocalHostで省略メンションを解決する', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                author: const MfmAuthorContext(),
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@local.example');
    });

    testWidgets('投稿者情報がなくてもlocalHostで省略メンションを解決する', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@local.example');
    });

    testWidgets('明示されたメンションホストを投稿者ホストより優先する', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice@explicit.example',
              config: MfmRenderConfig(
                author: const MfmAuthorContext(host: 'remote.example'),
                localHost: 'local.example',
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice@explicit.example');
      expect(tappedMention, '@alice@explicit.example');
    });

    testWidgets('Inherited configの投稿者ホストを明示コールバックと結合する', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MfmConfig(
          config: const MfmRenderConfig(
            author: MfmAuthorContext(host: 'remote.example'),
            localHost: 'local.example',
          ),
          child: MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '@alice',
                config: MfmRenderConfig(
                  onMentionTap: (acct) => tappedMention = acct,
                ),
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice@remote.example');
    });

    testWidgets('解決コンテキストがなければ省略メンションをそのまま渡す', (tester) async {
      String? tappedMention;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '@alice',
              config: MfmRenderConfig(
                onMentionTap: (acct) => tappedMention = acct,
              ),
            ),
          ),
        ),
      );

      _invokeSpanTap(tester, '@alice');
      expect(tappedMention, '@alice');
    });

    testWidgets('onHashtagTap未設定時はハッシュタグのrecognizerがnullになる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '#flutter'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final hashtagSpan = _findSpanWithText(textSpan, '#flutter');
      expect(hashtagSpan, isNotNull);
      expect(hashtagSpan!.recognizer, isNull);
    });

    testWidgets('onHashtagTap設定時はrecognizerがありタップで#なしのタグ名を渡す', (tester) async {
      String? tappedTag;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '#flutter',
              config: MfmRenderConfig(onHashtagTap: (tag) => tappedTag = tag),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final hashtagSpan = _findSpanWithText(textSpan, '#flutter');
      expect(hashtagSpan, isNotNull);

      expect(hashtagSpan!.recognizer, isA<TapGestureRecognizer>());
      expect(tappedTag, isNull);

      await tester.tap(find.byType(RichText));

      expect(tappedTag, 'flutter');
    });

    testWidgets('英語ロケールで検索ボタンにSearchを表示する', (tester) async {
      String? tappedQuery;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: MfmText(
              text: 'flutter Search',
              config: MfmRenderConfig(
                onSearchTap: (query) => tappedQuery = query,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(tappedQuery, 'flutter');
    });

    testWidgets('日本語ロケールで検索ボタンに検索を表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: const MfmText(text: 'flutter Search'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('検索'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('検索ボタンの明示ラベルがロケールより優先される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: const MfmText(
                  text: 'flutter Search',
                  config: MfmRenderConfig(searchButtonLabel: 'Find'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Find'), findsOneWidget);
      expect(find.text('検索'), findsNothing);
    });

    testWidgets('同じMfmTextがロケール更新を検索ラベルに反映する', (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      const mfmText = MfmText(text: 'flutter Search');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<Locale>(
              valueListenable: locale,
              child: mfmText,
              builder: (context, currentLocale, child) =>
                  Localizations.override(
                    context: context,
                    locale: currentLocale,
                    child: child,
                  ),
            ),
          ),
        ),
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('検索'), findsNothing);

      locale.value = const Locale('ja');
      await tester.pump();

      expect(find.text('検索'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('ローカライズ取得不可時はSearchを表示する', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: TextStyle(),
              child: MfmText(text: 'flutter Search'),
            ),
          ),
        ),
      );

      expect(find.text('Search'), findsOneWidget);
    });
  });

  group('MfmText ネスト要素', () {
    testWidgets('太字と斜体のネストをレンダリングできる', (tester) async {
      // パーサーがサポートする明示的なネスト構文を使用
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: '**<i>bold and italic</i>**')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // 太字スタイルを持つべき
      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNotNull);

      // 斜体スタイルを持つべき
      final italicSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontStyle == FontStyle.italic,
      );
      expect(italicSpan, isNotNull);
    });

    testWidgets('子要素を持つリンクをレンダリングできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: '[link text](https://example.com)'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      final linkSpan = _findSpanWithStyle(
        textSpan,
        (style) =>
            style?.decoration == TextDecoration.underline &&
            style?.color == const Color(0xFF0066CC),
      );
      expect(linkSpan, isNotNull);
    });
  });

  group('MfmText シンプルパーサー', () {
    testWidgets('simpleモードでは基本要素のみパースされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '**bold** :emoji: https://example.com',
              simple: true,
            ),
          ),
        ),
      );

      // simpleモードでは太字がパースされない
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      // simpleモードでは太字スタイルが適用されない
      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNull);
    });
  });
}

/// TextSpanの祖先から差分をマージして、対象テキストの実効スタイルを得る。
TextStyle? _effectiveStyleForText(
  TextSpan span,
  String text, [
  TextStyle inherited = const TextStyle(),
]) {
  final style = inherited.merge(span.style);
  if (span.text == text) return style;
  for (final child in span.children ?? <InlineSpan>[]) {
    if (child is TextSpan) {
      final found = _effectiveStyleForText(child, text, style);
      if (found != null) return found;
    }
  }
  return null;
}

WidgetSpan? _firstWidgetSpan(TextSpan span) {
  for (final child in span.children ?? <InlineSpan>[]) {
    if (child is WidgetSpan) return child;
    if (child is TextSpan) {
      final found = _firstWidgetSpan(child);
      if (found != null) return found;
    }
  }
  return null;
}

/// 特定のスタイルを持つTextSpanを検索するヘルパー関数
TextSpan? _findSpanWithStyle(
  TextSpan parent,
  bool Function(TextStyle?) predicate,
) {
  if (predicate(parent.style)) {
    return parent;
  }

  if (parent.children != null) {
    for (final child in parent.children!) {
      if (child is TextSpan) {
        final found = _findSpanWithStyle(child, predicate);
        if (found != null) {
          return found;
        }
      }
    }
  }

  return null;
}

/// 特定のテキストを持つTextSpanを検索するヘルパー関数
TextSpan? _findSpanWithText(TextSpan parent, String text) {
  if (parent.text == text) {
    return parent;
  }

  if (parent.children != null) {
    for (final child in parent.children!) {
      if (child is TextSpan) {
        final found = _findSpanWithText(child, text);
        if (found != null) {
          return found;
        }
      }
    }
  }

  return null;
}

void _invokeSpanTap(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(find.byType(RichText));
  final textSpan = richText.text as TextSpan;
  final targetSpan = _findSpanWithText(textSpan, text);
  expect(targetSpan, isNotNull);
  final recognizer = targetSpan?.recognizer;
  expect(recognizer, isA<TapGestureRecognizer>());
  (recognizer! as TapGestureRecognizer).onTap?.call();
}
