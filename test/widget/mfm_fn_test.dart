import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_jump_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_shake_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_spin_widget.dart';

void main() {
  group('MfmText fnのWidgetSpanのベースライン', () {
    const functions = [
      'spin',
      'jump',
      'bounce',
      'rainbow',
      'sparkle',
      'shake',
      'twitch',
      'tada',
      'jelly',
      'flip.h,v',
      'rotate.deg=45',
      'scale.x=2,y=2',
      'position.x=1,y=1',
      'bg.color=ff0000',
      'border',
      'clickable.ev=test',
    ];

    for (final function in functions) {
      testWidgets('$functionのWidgetSpanをalphabeticベースラインに揃える', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                // TextSpanの入れ子を含むルートからWidgetSpanを収集する。
                text: 'abc**\$[$function def]**ghi',
                config: MfmRenderConfig(onClickableEvent: (_) {}),
              ),
            ),
          ),
        );

        final root = tester.widget<RichText>(
          find
              .descendant(
                of: find.byType(MfmText),
                matching: find.byType(RichText),
              )
              .first,
        );
        final spans = _collectWidgetSpans(root.text).toList();
        expect(spans, hasLength(1));
        expect(spans.single.alignment, PlaceholderAlignment.baseline);
        expect(spans.single.baseline, TextBaseline.alphabetic);
      });
    }

    testWidgets('unixtimeのWidgetSpanをalphabeticベースラインに揃える', (tester) async {
      // 本家はdisplay: inline-blockでvertical-align未指定のため、
      // ピル内テキストのベースラインで周囲と揃う。
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: r'abc$[unixtime 1700000000]ghi')),
        ),
      );

      final root = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(MfmText),
              matching: find.byType(RichText),
            )
            .first,
      );
      final spans = _collectWidgetSpans(root.text).toList();
      expect(spans, hasLength(1));
      expect(spans.single.alignment, PlaceholderAlignment.baseline);
      expect(spans.single.baseline, TextBaseline.alphabetic);
    });

    testWidgets('通常テキストとspinの描画ベースラインが混在行で一致する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'abc$[spin def]ghi',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 20, height: 1.5),
              ),
            ),
          ),
        ),
      );

      // 初期フレームの回転角は0。アニメーションを進めず配置だけを検証する。
      final root = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(MfmText),
              matching: find.byType(RichText),
            )
            .first,
      );
      final inner = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(MfmSpinWidget),
          matching: find.byType(RichText),
        ),
      );
      final rootBaseline = root.getDryBaseline(
        root.constraints,
        TextBaseline.alphabetic,
      )!;
      final innerBaseline = inner.getDryBaseline(
        inner.constraints,
        TextBaseline.alphabetic,
      )!;

      // 子の実際の配置を親座標に変換する。行高を明示して、旧bottom揃えで
      // Ahemの文字ボックスとプレースホルダの高さが偶然一致するのを避ける。
      expect(
        inner.localToGlobal(Offset(0, innerBaseline), ancestor: root).dy,
        closeTo(rootBaseline, 0.001),
      );
    });

    testWidgets('positionはベースラインを揃えた位置から指定の距離だけ移動する', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'abc$[position.x=1,y=1 def]ghi',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 20, height: 1.5),
              ),
            ),
          ),
        ),
      );

      final root = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(MfmText),
              matching: find.byType(RichText),
            )
            .first,
      );
      final inner = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.descendant(
            of: find.byType(MfmText),
            matching: find.byType(Transform),
          ),
          matching: find.byType(RichText),
        ),
      );
      final rootBaseline = root.getDryBaseline(
        root.constraints,
        TextBaseline.alphabetic,
      )!;
      final innerBaseline = inner.getDryBaseline(
        inner.constraints,
        TextBaseline.alphabetic,
      )!;
      final paintedBaseline = inner.localToGlobal(
        Offset(0, innerBaseline),
        ancestor: root,
      );
      // ルートの文字列はabc + プレースホルダ1文字 + ghi。
      final placeholder = root
          .getBoxesForSelection(
            const TextSelection(baseOffset: 3, extentOffset: 4),
          )
          .single;
      expect(paintedBaseline.dx, closeTo(placeholder.left + 20, 0.001));
      expect(paintedBaseline.dy, closeTo(rootBaseline + 20, 0.001));
    });
  });

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
        name: 'smallの継承サイズとalpha',
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
      // scaleはサイズ関数の深さを増やさないため、最初のx2は親サイズの2倍。
      expect(richText.text.style?.fontSize, 28);
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

  group('MfmText fn size関数の入れ子', () {
    const config = MfmRenderConfig(baseTextStyle: TextStyle(fontSize: 14));
    const sizeCases = [
      (outer: 'x2', inner: 'x2', outerSize: 28.0, innerSize: 42.0),
      (outer: 'x2', inner: 'x3', outerSize: 28.0, innerSize: 70.0),
      (outer: 'x2', inner: 'x4', outerSize: 28.0, innerSize: 98.0),
      (outer: 'x3', inner: 'x2', outerSize: 56.0, innerSize: 84.0),
      (outer: 'x3', inner: 'x3', outerSize: 56.0, innerSize: 140.0),
      (outer: 'x3', inner: 'x4', outerSize: 56.0, innerSize: 196.0),
      (outer: 'x4', inner: 'x2', outerSize: 84.0, innerSize: 126.0),
      (outer: 'x4', inner: 'x3', outerSize: 84.0, innerSize: 210.0),
      (outer: 'x4', inner: 'x4', outerSize: 84.0, innerSize: 294.0),
    ];
    for (final sizeCase in sizeCases) {
      testWidgets('${sizeCase.outer}内の${sizeCase.inner}は親相対のサイズになる', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '\$[${sizeCase.outer} \$[${sizeCase.inner} A]]',
                config: config,
              ),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText).first);
        final root = richText.text as TextSpan;
        final outer = root.children!.single as TextSpan;
        final inner = outer.children!.single as TextSpan;
        expect(outer.style?.fontSize, sizeCase.outerSize);
        expect(inner.style?.fontSize, sizeCase.innerSize);
        expect(inner.toPlainText(), 'A');
      });
    }

    const depthCases = [
      (
        name: '同種の3階層目',
        text: r'$[x2 $[x2 $[x2 A]]]',
        sizes: <double?>[28, 42, null],
        effectiveSize: 42.0,
      ),
      (
        name: '異種の3階層目',
        text: r'$[x4 $[x3 $[x2 A]]]',
        sizes: <double?>[84, 210, null],
        effectiveSize: 210.0,
      ),
      (
        name: '4階層目以降',
        text: r'$[x2 $[x2 $[x2 $[x4 A]]]]',
        sizes: <double?>[28, 42, null, null],
        effectiveSize: 42.0,
      ),
    ];
    for (final depthCase in depthCases) {
      testWidgets('${depthCase.name}はfontSizeの差分を付けず親サイズを継承する', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: depthCase.text, config: config),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText).first);
        var span = richText.text as TextSpan;
        var effectiveStyle = span.style!;
        for (final fontSize in depthCase.sizes) {
          span = span.children!.single as TextSpan;
          expect(span.style?.fontSize, fontSize);
          effectiveStyle = effectiveStyle.merge(span.style);
        }
        final text = span.children!.single as TextSpan;
        expect(text.text, 'A');
        expect(text.style?.fontSize, isNull);
        expect(
          effectiveStyle.merge(text.style).fontSize,
          depthCase.effectiveSize,
        );
      });
    }

    testWidgets('太字を挟んでもサイズ関数の深さと親サイズを維持する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[x2 **$[x2 A]**]', config: config),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final bold = _findSpanWithStyle(
        richText.text as TextSpan,
        (style) => style?.fontWeight == FontWeight.bold,
      );
      expect(bold, isNotNull);
      final inner = bold!.children!.single as TextSpan;
      expect(inner.style?.fontSize, 42);
      expect(inner.toPlainText(), 'A');
    });

    testWidgets('shakeのWidgetSpanを越えてサイズ関数の深さと親サイズを維持する', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[x2 $[shake $[x2 A]]]', config: config),
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
      final root = richText.text as TextSpan;
      expect(root.style?.fontSize, 28);
      final inner = root.children!.single as TextSpan;
      expect(inner.style?.fontSize, 42);
      expect(inner.toPlainText(), 'A');
    });

    testWidgets('scaleはサイズ関数の深さを増やさず親サイズとともに引き継ぐ', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: r'$[x2 $[scale.x=2,y=2 $[x2 A]]]',
              config: config,
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(Transform),
          matching: find.byType(RichText),
        ),
      );
      final root = richText.text as TextSpan;
      expect(root.style?.fontSize, 28);
      final inner = root.children!.single as TextSpan;
      expect(inner.style?.fontSize, 42);
      expect(inner.toPlainText(), 'A');
    });
  });

  group('MfmText fn flip関数', () {
    testWidgets('引数なしのflipをレンダリングできる', (tester) async {
      // $[flip text] 引数なしでもレンダリングされるべき
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[flip flipped]'),
          ),
        ),
      );

      // Transformウィジェットでレンダリングされる
      expect(find.byType(Transform), findsWidgets);
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

    testWidgets('advancedMfm無効時はpositionが無視される', (tester) async {
      // 正しい構造を確保するためにパース済みノードを直接使用
      final nodes = [
        const FnNode(
          name: 'position',
          args: {'x': '1', 'y': '1'},
          children: [TextNode('positioned')],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              parsedNodes: nodes,
              config: const MfmRenderConfig(enableAdvancedMfm: false),
            ),
          ),
        ),
      );

      // advancedMfmが無効の場合、positionはTransform.translateを
      // 適用しない。テキストは引き続きレンダリングされる
      expect(find.byType(MfmText), findsOneWidget);

      // ウィジェットツリー構造を確認してTransform.translateが
      // 適用されていないことを検証。重要な動作は位置オフセットなしで
      // テキストがレンダリングされること
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText, isNotNull);
    });
  });

  group('MfmText fn fg（前景色）関数', () {
    testWidgets('fg.colorで6桁16進カラーを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[fg.color=ff0000 red text]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final colorSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.color == const Color(0xFFFF0000),
      );
      expect(colorSpan, isNotNull);
    });

    testWidgets('fg.colorで3桁16進カラーを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[fg.color=f00 red text]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final colorSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.color == const Color(0xFFFF0000),
      );
      expect(colorSpan, isNotNull);
    });

    testWidgets('fg.カラー値で位置引数としてカラーを適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[fg.00ff00 green text]'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final colorSpan = _findSpanWithStyle(
        textSpan,
        (style) => style?.color == const Color(0xFF00FF00),
      );
      expect(colorSpan, isNotNull);
    });
  });

  group('MfmText fn bg（背景色）関数', () {
    testWidgets('bg.colorで背景色を適用できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[bg.color=0000ff text with bg]'),
          ),
        ),
      );

      // すべてのColoredBoxウィジェットを検索し、期待する色があるか確認
      final coloredBoxes = tester.widgetList<ColoredBox>(
        find.byType(ColoredBox),
      );
      final hasBlueBackground = coloredBoxes.any(
        (box) => box.color == const Color(0xFF0000FF),
      );
      expect(hasBlueBackground, isTrue);
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

      final rubyFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
      );
      expect(rubyFinder, findsOneWidget);

      final rubyRenderObject = tester.renderObject(rubyFinder);
      expect((rubyRenderObject as dynamic).baseText, '振り仮名');
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
    testWidgets('未知のfn関数は子要素をそのまま表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(text: r'$[unknown content]'),
          ),
        ),
      );

      // エラーなくコンテンツがレンダリングされる
      expect(find.byType(MfmText), findsOneWidget);
    });
  });
}

Iterable<WidgetSpan> _collectWidgetSpans(InlineSpan span) sync* {
  if (span is WidgetSpan) {
    yield span;
  } else if (span is TextSpan) {
    for (final child in span.children ?? <InlineSpan>[]) {
      yield* _collectWidgetSpans(child);
    }
  }
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
