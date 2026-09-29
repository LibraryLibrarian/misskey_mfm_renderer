import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _baseStyle = TextStyle(fontSize: 20, color: Color(0x800000FF));
const _divider = Color(0x80112233);

Widget _host(
  String text, {
  TextStyle style = _baseStyle,
  bool animation = true,
  double textScale = 1,
}) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MfmText(
        text: text,
        config: MfmRenderConfig(
          baseTextStyle: style,
          enableAnimation: animation,
          lightColorScheme: const MfmColorScheme.light(divider: _divider),
        ),
      ),
    ),
  ),
);

Finder _insideMfm(Finder matching) =>
    find.descendant(of: find.byType(MfmText), matching: matching);

void main() {
  final cases = [
    (
      name: 'x2とfg',
      wrap: (String text) => '\$[x2 \$[fg.color=ff0000 $text]]',
      style: _baseStyle.copyWith(fontSize: 40, color: const Color(0xFFFF0000)),
      opacity: 1.0,
    ),
    (
      name: 'smallと半透明の継承色',
      wrap: (String text) => '<small>$text</small>',
      style: _baseStyle.copyWith(
        fontSize: 16,
        color: _baseStyle.color!.withValues(alpha: _baseStyle.color!.a * 0.7),
      ),
      opacity: 0.7,
    ),
    (
      name: 'small内側のfg',
      wrap: (String text) => '<small>\$[fg.color=ff0000 $text]</small>',
      style: _baseStyle.copyWith(
        fontSize: 16,
        color: const Color(0xFFFF0000).withValues(alpha: 0.7),
      ),
      opacity: 0.7,
    ),
    (
      name: 'fg内側のsmall',
      wrap: (String text) => '\$[fg.color=ff0000 <small>$text</small>]',
      style: _baseStyle.copyWith(
        fontSize: 16,
        color: const Color(0xFFFF0000).withValues(alpha: 0.7),
      ),
      opacity: 0.7,
    ),
    (
      name: '太字・斜体・取り消し線・font',
      wrap: (String text) => '**<i>~~\$[font.monospace $text]~~</i>**',
      style: _baseStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.lineThrough,
        fontFamily: 'Courier',
        fontFamilyFallback: ['Courier New', 'monospace'],
      ),
      opacity: 1.0,
    ),
  ];

  for (final sample in cases) {
    testWidgets('rubyが${sample.name}を本文と読みへ一度だけ継承する', (tester) async {
      await tester.pumpWidget(_host(sample.wrap(r'$[ruby AB CD]')));
      final ruby = _insideMfm(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
        ),
      );
      final renderObject = tester.renderObject(ruby);
      expect((renderObject as dynamic).baseStyle, sample.style);
      expect(
        (renderObject as dynamic).rubyStyle,
        sample.style.copyWith(
          fontSize: sample.style.fontSize! * 0.5,
          height: 1,
        ),
      );
      expect(_insideMfm(find.byType(Opacity)), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unixtimeが${sample.name}を文字・アイコン・枠へ一度だけ継承する', (
      tester,
    ) async {
      await tester.pumpWidget(_host(sample.wrap(r'$[unixtime 1700000000]')));
      final row = _insideMfm(find.byType(Row));
      final text = tester.widget<RichText>(
        find
            .descendant(
              of: row,
              matching: find.byWidgetPredicate((widget) => widget is RichText),
            )
            .last,
      );
      final expectedSize = sample.style.fontSize! * 0.9;
      expect(
        text.text.style,
        sample.style.copyWith(fontSize: expectedSize, inherit: false),
      );
      final icon = tester.widget<Icon>(_insideMfm(find.byType(Icon)));
      expect(icon.size, expectedSize);
      expect(icon.color, sample.style.color);
      final container = tester
          .element(row)
          .findAncestorWidgetOfExactType<Container>()!;
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(
        border.top.color.a,
        closeTo(_divider.a * sample.opacity, 1e-6),
      );
      expect(_insideMfm(find.byType(Opacity)), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final usePaint in [false, true]) {
    testWidgets('smallの入れ子は色未指定・foreground=$usePaintでも一度だけ減光する', (
      tester,
    ) async {
      final paint = Paint()..color = const Color(0x800000FF);
      final originalColor = paint.color;
      final style = TextStyle(
        fontSize: 20,
        foreground: usePaint ? paint : null,
      );
      await tester.pumpWidget(
        _host(
          r'<small><small>$[ruby AB CD] $[unixtime 1700000000]</small></small>',
          style: style,
        ),
      );
      final expectedAlpha = (usePaint ? paint.color.a : 1.0) * 0.7 * 0.7;
      final ruby = _insideMfm(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
        ),
      );
      final renderObject = tester.renderObject(ruby);
      final row = _insideMfm(find.byType(Row));
      final text = tester.widget<RichText>(
        find
            .descendant(
              of: row,
              matching: find.byWidgetPredicate((widget) => widget is RichText),
            )
            .last,
      );
      for (final actual in [
        (renderObject as dynamic).baseStyle as TextStyle,
        (renderObject as dynamic).rubyStyle as TextStyle,
        text.text.style!,
      ]) {
        final color = actual.foreground?.color ?? actual.color!;
        expect(color.a, closeTo(expectedAlpha, 1e-6));
        if (usePaint) expect(identical(actual.foreground, paint), isFalse);
      }
      final icon = tester.widget<Icon>(_insideMfm(find.byType(Icon)));
      expect(icon.color!.a, closeTo(expectedAlpha, 1e-6));
      final container = tester
          .element(row)
          .findAncestorWidgetOfExactType<Container>()!;
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color.a, closeTo(_divider.a * 0.7 * 0.7, 1e-6));
      expect(paint.color, originalColor);
      expect(_insideMfm(find.byType(Opacity)), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final useBackgroundPaint in [false, true]) {
    for (final quote in [false, true]) {
      testWidgets('smallとquote=$quoteは背景Paint=$useBackgroundPaint・装飾・影を減光する', (
        tester,
      ) async {
        const color = Color(0x80FF0000);
        final paint = Paint()..color = color;
        final originalColor = paint.color;
        await tester.pumpWidget(
          _host(
            '${quote ? '> ' : ''}<small>\$[ruby AB CD] \$[unixtime 1700000000]</small>',
            style: _baseStyle.copyWith(
              backgroundColor: useBackgroundPaint ? null : color,
              background: useBackgroundPaint ? paint : null,
              decorationColor: color,
              decoration: TextDecoration.lineThrough,
              shadows: [
                const Shadow(color: color, offset: Offset(1, 2), blurRadius: 3),
              ],
            ),
          ),
        );
        final ruby = _insideMfm(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
          ),
        );
        final renderObject = tester.renderObject(ruby);
        final label = tester.widget<Text>(_insideMfm(find.byType(Text)));
        final opacity = quote ? 0.49 : 0.7;
        for (final style in [
          (renderObject as dynamic).baseStyle as TextStyle,
          (renderObject as dynamic).rubyStyle as TextStyle,
          label.style!,
        ]) {
          final background = style.background?.color ?? style.backgroundColor!;
          expect(background.a, closeTo(color.a * opacity, 1e-6));
          expect(style.decorationColor!.a, closeTo(color.a * opacity, 1e-6));
          expect(
            style.shadows!.single.color.a,
            closeTo(color.a * opacity, 1e-6),
          );
          expect(style.shadows!.single.offset, const Offset(1, 2));
          expect(style.shadows!.single.blurRadius, 3);
          if (useBackgroundPaint) {
            expect(identical(style.background, paint), isFalse);
          }
        }
        expect(paint.color, originalColor);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final animation in [false, true]) {
    testWidgets('unixtimeはrainbow animation=$animationでも端末の文字倍率を維持する', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          r'$[rainbow $[x2 <small>$[unixtime 1700000000]</small>]]',
          animation: animation,
          textScale: 1.5,
        ),
      );
      final row = _insideMfm(find.byType(Row));
      final text = tester.widget<RichText>(
        find
            .descendant(
              of: row,
              matching: find.byWidgetPredicate((widget) => widget is RichText),
            )
            .last,
      );
      expect(text.text.style!.fontSize, closeTo(20 * 2 * 0.8 * 0.9, 1e-6));
      expect(text.textScaler.scale(20), 30);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final sample in [
    (text: r'$[x2 $[position.x=1,y=-0.5 A]]', size: 40.0),
    (text: r'<small>$[position.x=1,y=-0.5 A]</small>', size: 16.0),
    (text: r'$[x2 <small>$[position.x=1,y=-0.5 A]</small>]', size: 32.0),
  ]) {
    testWidgets('positionのemは実効サイズ${sample.size}で計算する', (tester) async {
      await tester.pumpWidget(_host(sample.text));
      final transform = tester.widget<Transform>(
        _insideMfm(find.byType(Transform)),
      );
      expect(transform.transform.storage[12], sample.size);
      expect(transform.transform.storage[13], -sample.size * 0.5);
    });
  }
}
