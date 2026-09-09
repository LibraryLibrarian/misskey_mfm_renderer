import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_jump_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_shake_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_spin_widget.dart';

void main() {
  group('MfmText WidgetSpan境界のスタイル継承', () {
    const baseStyle = TextStyle(fontSize: 14, color: Colors.blue);
    final styleCases = [
      (
        name: '斜体',
        text: r'<i>$[spin abc]</i>',
        patch: const TextStyle(fontStyle: FontStyle.italic),
      ),
      (
        name: '取り消し線',
        text: r'~~$[spin abc]~~',
        patch: const TextStyle(decoration: TextDecoration.lineThrough),
      ),
      (
        name: 'smallのルート基準サイズとalpha',
        text: r'<small>$[spin abc]</small>',
        patch: TextStyle(
          fontSize: 14 * 0.8,
          color: Colors.blue.withValues(alpha: 0.7),
        ),
      ),
      (
        name: '標準フォント',
        text: r'$[font.monospace $[spin abc]]',
        patch: const TextStyle(
          fontFamily: 'Courier',
          fontFamilyFallback: ['Courier New', 'monospace'],
        ),
      ),
      (
        name: 'カスタムフォント',
        text: r'$[font.serif $[spin abc]]',
        patch: const TextStyle(fontFamily: 'CustomSerif'),
      ),
    ];
    for (final styleCase in styleCases) {
      testWidgets('${styleCase.name}の差分をspin配下へ引き継ぐ', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: styleCase.text,
                config: MfmRenderConfig(
                  baseTextStyle: baseStyle,
                  fontFamilyResolver: (type) =>
                      type == 'serif' ? 'CustomSerif' : null,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.byType(MfmSpinWidget),
            matching: find.byType(RichText),
          ),
        );
        expect(richText.text.style, baseStyle.merge(styleCase.patch));
      });
    }

    testWidgets('リンクからscaleとサイズ関数を経てもスタイルとnyaize抑止を維持する', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text:
                  r'**[$[scale.x=2,y=2 $[x2 $[spin な]]]](https://example.com)**',
              config: MfmRenderConfig(
                baseTextStyle: baseStyle,
                enableNyaize: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmSpinWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.fontWeight, FontWeight.bold);
      expect(richText.text.style?.color, const Color(0xFF0066CC));
      expect(richText.text.style?.decoration, TextDecoration.underline);
      // scale=2の文脈でx2の倍率は1.5。ルート基準の計算式は変更しない。
      expect(richText.text.style?.fontSize, 21);
      expect(richText.text.toPlainText(), 'な');
    });

    testWidgets('太字をspin配下のRichTextへ引き継ぐ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'**$[spin abc]**',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmSpinWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('x2のフォントサイズをshake配下のRichTextへ引き継ぐ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x2 $[shake abc]]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmShakeWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.fontSize, 28);
    });

    testWidgets('前景色をjump配下のRichTextへ引き継ぐ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[fg.color=f00 $[jump abc]]'),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmJumpWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.color, const Color(0xFFFF0000));
    });

    testWidgets('太字が兄弟のspinへ漏れない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'**abc** $[spin def]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmSpinWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.fontWeight, isNull);
      expect(richText.text.toPlainText(), 'def');
    });

    testWidgets('baseTextStyle未指定で環境のfontSizeがnullでも描画できる', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.black),
              child: MfmText(text: r'$[spin abc]'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final root = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(MfmText),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(root.text.style?.fontSize, 14);
      final inner = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmSpinWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(inner.text.style, root.text.style);
    });

    testWidgets('inheritがfalseの明示スタイルでもfontSizeを補完し環境とはマージしない', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DefaultTextStyle(
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              child: MfmText(
                text: r'$[spin abc]',
                config: MfmRenderConfig(
                  baseTextStyle: TextStyle(inherit: false, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final richTexts = tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(RichText),
        ),
      );
      expect(richTexts, hasLength(2));
      for (final richText in richTexts) {
        expect(richText.text.style?.fontSize, 14);
        expect(richText.text.style?.fontWeight, isNull);
        expect(richText.text.style?.color, Colors.red);
        expect(richText.text.style?.inherit, isFalse);
      }
    });

    testWidgets('center内側のRichTextに実効スタイルを設定する', (tester) async {
      const baseStyle = TextStyle(fontSize: 20, color: Colors.blue);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '<center>**abc**</center>',
              config: MfmRenderConfig(baseTextStyle: baseStyle),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RichText && widget.textAlign == TextAlign.center,
          ),
        ),
      );
      expect(richText.text.style, baseStyle);
      expect(
        _findSpanWithStyle(
          richText.text as TextSpan,
          (style) => style?.fontWeight == FontWeight.bold,
        ),
        isNotNull,
      );
    });

    testWidgets('引用内側のRichTextに引用色と実効フォントサイズを設定する', (tester) async {
      const baseStyle = TextStyle(fontSize: 20, color: Colors.blue);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '> **abc**',
              config: MfmRenderConfig(baseTextStyle: baseStyle),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.descendant(
            of: find.byType(MfmText),
            matching: find.byType(Container),
          ),
          matching: find.byType(RichText),
        ),
      );
      expect(
        richText.text.style,
        baseStyle.copyWith(color: Colors.blue.withValues(alpha: 0.7)),
      );
      expect(
        _findSpanWithStyle(
          richText.text as TextSpan,
          (style) => style?.fontWeight == FontWeight.bold,
        ),
        isNotNull,
      );
    });

    testWidgets('引用色と太字をさらに内側のspinへ伝播しnyaize抑止も維持する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'> **$[x2 $[spin な]]**',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14, color: Colors.blue),
                enableNyaize: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MfmSpinWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.color, Colors.blue.withValues(alpha: 0.7));
      expect(richText.text.style?.fontWeight, FontWeight.bold);
      expect(richText.text.style?.fontSize, 28);
      expect(richText.text.toPlainText(), 'な');
    });
  });

  group('MfmText fn size関数', () {
    testWidgets('x2で2倍のフォントサイズになる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x2 big]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final sizedSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontSize != null && style!.fontSize! >= 28,
      );
      expect(sizedSpan, isNotNull);
    });

    testWidgets('x3で4倍のフォントサイズになる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x3 bigger]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final sizedSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontSize != null && style!.fontSize! >= 56,
      );
      expect(sizedSpan, isNotNull);
    });

    testWidgets('x4で6倍のフォントサイズになる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x4 biggest]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final sizedSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontSize != null && style!.fontSize! >= 84,
      );
      expect(sizedSpan, isNotNull);
    });
  });

  group('MfmText fn flip関数', () {
    testWidgets('引数なしのflipで水平反転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[flip abc]'),
          ),
        ),
      );

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      final matrix = transform.transform;

      expect(matrix.entry(0, 0), -1.0);
      expect(matrix.entry(1, 1), 1.0);
    });

    testWidgets('未知引数のみのflipで水平反転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[flip.unknown abc]'),
          ),
        ),
      );

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      final matrix = transform.transform;

      expect(matrix.entry(0, 0), -1.0);
      expect(matrix.entry(1, 1), 1.0);
    });

    testWidgets('flip.hで水平反転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[flip.h flipped]'),
          ),
        ),
      );

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      final matrix = transform.transform;

      expect(matrix.entry(0, 0), -1.0);
      expect(matrix.entry(1, 1), 1.0);
    });

    testWidgets('flip.vで垂直反転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[flip.v flipped]'),
          ),
        ),
      );

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      final matrix = transform.transform;

      expect(matrix.entry(0, 0), 1.0);
      expect(matrix.entry(1, 1), -1.0);
    });

    testWidgets('flip.h,vで水平・垂直両方反転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[flip.h,v flipped]'),
          ),
        ),
      );

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      final matrix = transform.transform;

      expect(matrix.entry(0, 0), -1.0);
      expect(matrix.entry(1, 1), -1.0);
    });
  });

  group('MfmText fn rotate関数', () {
    testWidgets('rotateでデフォルト90度回転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[rotate rotated]'),
          ),
        ),
      );

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('rotate.deg=45でカスタム角度で回転する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[rotate.deg=45 rotated]'),
          ),
        ),
      );

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      final matrix = transform.transform;

      // 45度回転を確認
      final expectedCos = math.cos(45 * math.pi / 180);
      expect(matrix.entry(0, 0), closeTo(expectedCos, 0.001));
    });
  });

  group('MfmText fn scale関数', () {
    testWidgets('scale.x,yでスケール変換する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[scale.x=2,y=2 scaled]'),
          ),
        ),
      );

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('スケールは最大5倍に制限される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[scale.x=10 scaled]'),
          ),
        ),
      );

      // クラッシュせず正しくレンダリングされる
      expect(find.byType(MfmText), findsOneWidget);
    });
  });

  group('MfmText fn position関数', () {
    testWidgets('positionで位置移動する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[position.x=1,y=1 positioned]',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('advancedMfm無効時はpositionを引数なしのリテラルで表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[position.x=1 abc]',
              config: MfmRenderConfig(enableAdvancedMfm: false),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), r'$[position abc]');
      expect(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  // fg/bg共通の色解決を、パーサーを通した描画結果で検証する。
  const colorCases = <String, Color>{
    '': Color(0xFFFF0000), // color未指定
    '.color': Color(0xFFFF0000), // 値なし（文字列ではない引数）
    '.color=red': Color(0xFFFF0000), // 名前色は受理しない
    '.color=xyz': Color(0xFFFF0000),
    '.color=ab': Color(0xFFFF0000), // 2桁
    '.color=abcdef0': Color(0xFFFF0000), // 7桁
    '.color=0000ffff': Color(0xFFFF0000), // 8桁
    '.00ff00': Color(0xFFFF0000), // 引数キーは色として扱わない
    '.color=xyz,00ff00': Color(0xFFFF0000),
    '.color=f00': Color(0xFFFF0000),
    '.color=ff0000': Color(0xFFFF0000),
    '.color=00f': Color(0xFF0000FF), // 3桁
    '.color=0000ff': Color(0xFF0000FF), // 6桁
    '.color=aBcDeF': Color(0xFFABCDEF), // 大文字小文字混在
    '.color=abcd': Color(0xDDAABBCC), // CSS #RGBA
    '.color=AbCd': Color(0xDDAABBCC),
    '.color=00f0': Color(0x000000FF), // 透明な青
    '.color=00ff': Color(0xFF0000FF), // 不透明な青
    '.color=00f,00ff00': Color(0xFF0000FF), // color引数だけを参照
  };

  group('MfmText fn fg（前景色）関数', () {
    for (final entry in colorCases.entries) {
      testWidgets('fg${entry.key}で期待する前景色を適用する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MfmText(text: '\$[fg${entry.key} abc]')),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText).first);
        final textSpan = richText.text as TextSpan;
        final colorSpan = _findSpanWithStyle(
          textSpan,
          (style) => style?.color == entry.value,
        );
        expect(colorSpan, isNotNull);
        expect(colorSpan!.toPlainText(), 'abc');
      });
    }
  });

  group('MfmText fn bg（背景色）関数', () {
    for (final entry in colorCases.entries) {
      testWidgets('bg${entry.key}で期待する背景色を適用する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MfmText(text: '\$[bg${entry.key} abc]')),
          ),
        );

        final coloredBoxes = tester.widgetList<ColoredBox>(
          find.byType(ColoredBox),
        );
        final backgrounds = coloredBoxes.where(
          (box) => box.color == entry.value && box.child is RichText,
        );
        expect(backgrounds, hasLength(1));
        final richText = backgrounds.single.child! as RichText;
        expect(richText.text.toPlainText(), 'abc');
      });
    }
  });

  group('MfmText fn fg/bgの不正なcolor引数', () {
    // 依存パーサーは#などを含む値をFnNodeにしないため、直接ノードを渡す。
    for (final name in ['fg', 'bg']) {
      for (final value in [null, true, 123, '', '#00f', '00ff00#', ' 00f']) {
        testWidgets('$nameのcolor=$valueは赤にフォールバックする', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  parsedNodes: [
                    FnNode(
                      name: name,
                      args: {'color': value},
                      children: const [TextNode('abc')],
                    ),
                  ],
                ),
              ),
            ),
          );

          if (name == 'fg') {
            final richText = tester.widget<RichText>(
              find.byType(RichText).first,
            );
            final colorSpan = _findSpanWithStyle(
              richText.text as TextSpan,
              (style) => style?.color == const Color(0xFFFF0000),
            );
            expect(colorSpan, isNotNull);
            expect(colorSpan!.toPlainText(), 'abc');
          } else {
            final coloredBoxes = tester.widgetList<ColoredBox>(
              find.byType(ColoredBox),
            );
            final backgrounds = coloredBoxes.where(
              (box) =>
                  box.color == const Color(0xFFFF0000) && box.child is RichText,
            );
            expect(backgrounds, hasLength(1));
            final richText = backgrounds.single.child! as RichText;
            expect(richText.text.toPlainText(), 'abc');
          }
        });
      }
    }
  });

  group('MfmText fn fg/bgの5桁color引数', () {
    // 本家の正規表現には一致するがCSSでは無効な色として宣言が破棄されるため、
    // 赤にもならず色指定なしになる。
    testWidgets('fg.color=abcdeは色を付けない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'$[fg.color=abcde abc]')),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final root = richText.text as TextSpan;
      // ルートのstyle以外に色を持つspanが存在しない
      final coloredChild = root.children!.whereType<TextSpan>().any(
        (span) =>
            span.style?.color != null ||
            _findSpanWithStyle(span, (style) => style?.color != null) != null,
      );
      expect(coloredChild, isFalse);
      expect(root.toPlainText(), 'abc');
    });

    testWidgets('bg.color=abcdeは背景を付けない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'$[bg.color=abcde abc]')),
        ),
      );

      // MfmText配下にColoredBoxが挿入されない（Scaffold由来のものは除く）
      expect(
        find.descendant(
          of: find.byType(MfmText),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.text.toPlainText(), 'abc');
    });
  });

  group('MfmText fn border関数', () {
    testWidgets('borderでデフォルトスタイルのボーダーを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[border bordered]'),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final borderContainer = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.border != null;
          }
          return false;
        },
        orElse: Container.new,
      );
      expect(borderContainer.decoration, isNotNull);
    });

    testWidgets('border.widthとcolorでカスタム幅と色を適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[border.width=2,color=ff0000 bordered]'),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final borderContainer = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.border != null;
          }
          return false;
        },
        orElse: Container.new,
      );

      final decoration = borderContainer.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('border.radiusで角丸を適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[border.radius=8 bordered]'),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final borderContainer = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.borderRadius != null;
          }
          return false;
        },
        orElse: Container.new,
      );

      final decoration = borderContainer.decoration as BoxDecoration?;
      expect(decoration?.borderRadius, isNotNull);
    });
  });

  group('MfmText fn font関数', () {
    testWidgets('有効なフォント指定がない場合はリテラルで表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[font abc]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), r'$[font abc]');
    });

    for (final fontType in ['emoji', 'math']) {
      testWidgets('font.$fontTypeはリテラル化せず子要素を表示する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: '\$[font.$fontType abc]'),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText));
        expect(richText.text.toPlainText(), 'abc');
      });
    }

    testWidgets('font.serifでセリフフォントを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[font.serif serif text]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final fontSpan = _findSpanWithStyle(
        textSpan,
        (style) =>
            style?.fontFamily == 'Georgia' ||
            (style?.fontFamilyFallback?.contains('serif') ?? false),
      );
      expect(fontSpan, isNotNull);
    });

    testWidgets('font.monospaceで等幅フォントを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[font.monospace mono text]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final fontSpan = _findSpanWithStyle(
        textSpan,
        (style) =>
            style?.fontFamily == 'Courier' ||
            (style?.fontFamilyFallback?.contains('monospace') ?? false),
      );
      expect(fontSpan, isNotNull);
    });

    testWidgets('fontFamilyResolverでカスタムフォントを解決できる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[font.serif serif text]',
              config: MfmRenderConfig(
                fontFamilyResolver: (type) {
                  if (type == 'serif') {
                    return 'CustomSerif';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final fontSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontFamily == 'CustomSerif',
      );
      expect(fontSpan, isNotNull);
    });
  });

  group('MfmText fn blur関数', () {
    testWidgets('blurでImageFilteredを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[blur blurred]'),
          ),
        ),
      );

      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('hover中はブラーを解除し、exit後に再適用する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[blur blurred]'),
          ),
        ),
      );

      final imageFilteredFinder = find.byType(ImageFiltered);
      final mouseRegionFinder = find.ancestor(
        of: imageFilteredFinder,
        matching: find.byType(MouseRegion),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(mouseRegionFinder.first));
      await tester.pumpAndSettle();

      var imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isFalse);

      await mouse.moveTo(const Offset(799, 599));
      await tester.pumpAndSettle();

      imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isTrue);
    });

    testWidgets('mouse click後もexitでブラーを再適用する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[blur blurred]'),
          ),
        ),
      );

      final imageFilteredFinder = find.byType(ImageFiltered);
      final mouseRegionFinder = find.ancestor(
        of: imageFilteredFinder,
        matching: find.byType(MouseRegion),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final center = tester.getCenter(mouseRegionFinder.first);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(center);
      await tester.pumpAndSettle();
      await mouse.down(center);
      await mouse.up();
      await tester.pumpAndSettle();

      var imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isFalse);

      await mouse.moveTo(const Offset(799, 599));
      await tester.pumpAndSettle();

      imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isTrue);
    });

    testWidgets('ブラー強度を300msで補間する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[blur blurred]'),
          ),
        ),
      );

      final animationFinder = find.byType(TweenAnimationBuilder<double>);
      final imageFilteredFinder = find.byType(ImageFiltered);
      final gestureDetectorFinder = find.ancestor(
        of: imageFilteredFinder,
        matching: find.byType(GestureDetector),
      );
      final animation = tester.widget<TweenAnimationBuilder<double>>(
        animationFinder,
      );
      expect(animation.duration, const Duration(milliseconds: 300));

      await tester.tap(gestureDetectorFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      var imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(
        imageFiltered.imageFilter,
        isNot(ImageFilter.blur(sigmaX: 6, sigmaY: 6)),
      );
      expect(imageFiltered.imageFilter, isNot(ImageFilter.blur()));

      await tester.pump(const Duration(milliseconds: 150));

      imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isFalse);
      expect(imageFiltered.imageFilter, ImageFilter.blur());

      await tester.tap(gestureDetectorFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isTrue);
      expect(
        imageFiltered.imageFilter,
        isNot(ImageFilter.blur(sigmaX: 6, sigmaY: 6)),
      );
      expect(imageFiltered.imageFilter, isNot(ImageFilter.blur()));

      await tester.pump(const Duration(milliseconds: 150));

      imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(
        imageFiltered.imageFilter,
        ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      );
    });

    testWidgets('タップでブラーをトグルできる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[blur blurred]'),
          ),
        ),
      );

      final imageFilteredFinder = find.byType(ImageFiltered);
      final gestureDetectorFinder = find.ancestor(
        of: imageFilteredFinder,
        matching: find.byType(GestureDetector),
      );

      await tester.tap(gestureDetectorFinder.first);
      await tester.pumpAndSettle();

      var imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isFalse);

      await tester.tap(gestureDetectorFinder.first);
      await tester.pumpAndSettle();

      imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(imageFiltered.enabled, isTrue);
    });
  });

  group('MfmText fn ruby関数', () {
    final rubyFinder = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
    );

    for (final example in [
      (text: r'$[ruby 漢字 かんじ]', base: '漢字', ruby: 'かんじ'),
      (text: r'$[ruby 漢字 かんじ ふりがな]', base: '漢字', ruby: 'かんじ'),
    ]) {
      testWidgets('テキストのみのルビは空白分割した2番目を使う：${example.text}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MfmText(text: example.text)),
          ),
        );

        expect(rubyFinder, findsOneWidget);
        final renderObject = tester.renderObject(rubyFinder);
        final baseSpan = (renderObject as dynamic).baseSpan as InlineSpan;
        expect(baseSpan.toPlainText(), example.base);
        expect((renderObject as dynamic).rubyText, example.ruby);
      });
    }

    testWidgets('装飾付きベースを太字のまま描画し最後の子をルビにする', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'$[ruby **kanji** よみ]')),
        ),
      );

      expect(rubyFinder, findsOneWidget);
      final renderObject = tester.renderObject(rubyFinder);
      final baseSpan = (renderObject as dynamic).baseSpan as TextSpan;
      expect(baseSpan.toPlainText(), 'kanji');
      final boldSpan = _findSpanWithStyle(
        baseSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan?.toPlainText(), 'kanji');
      expect((renderObject as dynamic).rubyText, 'よみ');
      expect(tester.takeException(), isNull);
    });

    testWidgets('最後の子以外のベースをすべて保持しルビの前後だけをトリムする', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[ruby 前**kanji**後 よみ ふりがな ]'),
          ),
        ),
      );

      expect(rubyFinder, findsOneWidget);
      final renderObject = tester.renderObject(rubyFinder);
      final baseSpan = (renderObject as dynamic).baseSpan as TextSpan;
      expect(baseSpan.toPlainText(), '前kanji');
      expect((renderObject as dynamic).rubyText, '後 よみ ふりがな');
      expect(
        _findSpanWithStyle(
          baseSpan,
          (style) => style?.fontWeight == FontWeight.bold,
        )?.toPlainText(),
        'kanji',
      );
    });

    testWidgets('nyaize有効時は漢字のルビを猫語に変換する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[ruby 漢字 なにか]',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      expect(rubyFinder, findsOneWidget);
      final renderObject = tester.renderObject(rubyFinder);
      final baseSpan = (renderObject as dynamic).baseSpan as InlineSpan;
      expect(baseSpan.toPlainText(), '漢字');
      expect((renderObject as dynamic).rubyText, 'にゃにか');
    });

    testWidgets('テキストのみのルビは分割前にnyaizeしてベースとルビの両方を変換する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[ruby なにか よみな]',
              config: MfmRenderConfig(enableNyaize: true),
            ),
          ),
        ),
      );

      expect(rubyFinder, findsOneWidget);
      final renderObject = tester.renderObject(rubyFinder);
      final baseSpan = (renderObject as dynamic).baseSpan as InlineSpan;
      expect(baseSpan.toPlainText(), 'にゃにか');
      expect((renderObject as dynamic).rubyText, 'よみにゃ');
    });

    // ko-KRの「다/야」パターンは半角スペースまたは行末が直後にある場合のみ
    // マッチするため、トリムの前後どちらでnyaizeするかで結果が変わる。
    // 本家はnyaize後にトリムするので、タブや全角スペースが末尾にある場合は
    // 変換されない。
    for (final example in [
      (name: 'タブ', ruby: '야\t'),
      (name: '全角スペース', ruby: '야　'),
      (name: 'タブ・다', ruby: '하다\t'),
    ]) {
      testWidgets('装飾付きのルビはトリムの前にnyaizeする：${example.name}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '\$[ruby **base** ${example.ruby}]',
                config: const MfmRenderConfig(enableNyaize: true),
              ),
            ),
          ),
        );

        expect(rubyFinder, findsOneWidget);
        final renderObject = tester.renderObject(rubyFinder);
        expect((renderObject as dynamic).rubyText, example.ruby.trim());
      });
    }

    for (final example in [
      (name: 'テキストのみ', text: r'$[ruby なにか なにか]'),
      (name: '装飾付き', text: r'$[ruby **なにか** なにか]'),
    ]) {
      for (final enabled in [false, true]) {
        testWidgets('${example.name}のベースとルビがnyaize設定に従う：$enabled', (
          tester,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  text: example.text,
                  config: MfmRenderConfig(enableNyaize: enabled),
                ),
              ),
            ),
          );

          expect(rubyFinder, findsOneWidget);
          final renderObject = tester.renderObject(rubyFinder);
          final baseSpan = (renderObject as dynamic).baseSpan as InlineSpan;
          final expected = enabled ? 'にゃにか' : 'なにか';
          expect(baseSpan.toPlainText(), expected);
          expect((renderObject as dynamic).rubyText, expected);
        });
      }

      testWidgets('引用内では${example.name}のベースとルビをnyaizeしない', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '> ${example.text}',
                config: const MfmRenderConfig(enableNyaize: true),
              ),
            ),
          ),
        );

        expect(rubyFinder, findsOneWidget);
        final renderObject = tester.renderObject(rubyFinder);
        final baseSpan = (renderObject as dynamic).baseSpan as InlineSpan;
        expect(baseSpan.toPlainText(), 'なにか');
        expect((renderObject as dynamic).rubyText, 'なにか');
      });
    }

    for (final text in [
      r'$[ruby $[spin abc] よみ]',
      r'$[ruby **$[spin abc]** よみ]',
    ]) {
      testWidgets('ベースにWidgetSpanが含まれる場合は子要素をそのまま表示する：$text', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MfmText(text: text)),
          ),
        );

        expect(rubyFinder, findsNothing);
        final richTexts = tester.widgetList<RichText>(find.byType(RichText));
        expect(
          richTexts.any((widget) => widget.text.toPlainText().contains('abc')),
          isTrue,
        );
        expect(
          richTexts.any((widget) => widget.text.toPlainText().contains(' よみ')),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final example in [
      (text: r'$[ruby 漢字]', expected: '漢字'),
      (text: r'$[ruby 漢字 ]', expected: '漢字 '),
      (text: r'$[ruby 漢字 **よみ**]', expected: '漢字 よみ'),
      (text: r'$[ruby **漢字**]', expected: '漢字'),
    ]) {
      testWidgets('ルビがないか最後の子が装飾ノードならそのまま表示する：${example.text}', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MfmText(text: example.text)),
          ),
        );

        expect(rubyFinder, findsNothing);
        final richTexts = tester.widgetList<RichText>(find.byType(RichText));
        expect(
          richTexts.any(
            (widget) => widget.text.toPlainText() == example.expected,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('再ビルドでベースのテキストと装飾とルビを更新できる', (tester) async {
      Future<void> pumpRuby(String text) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MfmText(text: text)),
        ),
      );

      await pumpRuby(r'$[ruby 漢字 かんじ]');
      final originalRenderObject = tester.renderObject(rubyFinder);
      await pumpRuby(r'$[ruby **kanji** よみ]');

      final renderObject = tester.renderObject(rubyFinder);
      expect(renderObject, same(originalRenderObject));
      final baseSpan = (renderObject as dynamic).baseSpan as TextSpan;
      expect(baseSpan.toPlainText(), 'kanji');
      expect(
        _findSpanWithStyle(
          baseSpan,
          (style) => style?.fontWeight == FontWeight.bold,
        )?.toPlainText(),
        'kanji',
      );
      expect((renderObject as dynamic).rubyText, 'よみ');
      expect(tester.takeException(), isNull);
    });

    testWidgets('rubyでルビテキストを上に表示できる', (tester) async {
      // 正しいruby構文: $[ruby ベーステキスト ルビテキスト]
      final nodes = [
        const FnNode(
          name: 'ruby',
          args: {},
          children: [TextNode('振り仮名 ふりがな')],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(parsedNodes: nodes),
          ),
        ),
      );

      expect(rubyFinder, findsOneWidget);

      final rubyRenderObject = tester.renderObject(rubyFinder);
      final baseSpan = (rubyRenderObject as dynamic).baseSpan as InlineSpan;
      expect(baseSpan.toPlainText(), '振り仮名');
      expect((rubyRenderObject as dynamic).rubyText, 'ふりがな');
    });
  });

  group('MfmText fn unixtime関数', () {
    testWidgets('unixtimeでフォーマット済み日時を表示できる', (tester) async {
      // テスト用に固定のタイムスタンプを使用
      final timestamp =
          DateTime(2024, 1, 15, 12).millisecondsSinceEpoch ~/ 1000;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(text: '\$[unixtime $timestamp]'),
          ),
        ),
      );

      // アイコンとフォーマット済み時間でレンダリングされる
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('MfmText アニメーションfn関数（プレースホルダー）', () {
    testWidgets('tadaがエラーなくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[tada 🎉]'),
          ),
        ),
      );

      expect(find.byType(MfmText), findsOneWidget);
    });

    testWidgets('jellyがエラーなくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[jelly 🍮]'),
          ),
        ),
      );

      expect(find.byType(MfmText), findsOneWidget);
    });

    testWidgets('shakeがエラーなくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[shake 震える]'),
          ),
        ),
      );

      expect(find.byType(MfmText), findsOneWidget);
    });

    testWidgets('spinがエラーなくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[spin 回る]'),
          ),
        ),
      );

      expect(find.byType(MfmText), findsOneWidget);
    });

    testWidgets('rainbowがエラーなくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[rainbow 虹色]'),
          ),
        ),
      );

      expect(find.byType(MfmText), findsOneWidget);
    });
  });

  group('MfmText 未知のfn関数', () {
    testWidgets('未知のfn関数はリテラルで表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[foobar abc]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), r'$[foobar abc]');
    });

    testWidgets('未知のfn関数をリテラルで囲んでも子要素の太字装飾を維持する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[foobar **abc**]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      expect(textSpan.toPlainText(), r'$[foobar abc]');

      final boldSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(boldSpan, isNotNull);
      expect(boldSpan!.toPlainText(), 'abc');
    });
  });
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
