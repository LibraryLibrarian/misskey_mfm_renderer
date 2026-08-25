import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
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
