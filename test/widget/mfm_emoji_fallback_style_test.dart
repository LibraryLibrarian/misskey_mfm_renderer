import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _pixels = Key('pixels');
const _red = Color.fromRGBO(255, 0, 0, 0.5);
const _root = TextStyle(fontFamily: 'Ahem', fontSize: 20, color: _red);

Widget _host(String text, MfmRenderConfig config) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: RepaintBoundary(
      key: _pixels,
      child: MfmText(text: text, config: config),
    ),
  ),
);

Future<List<int>> _letterPixel(
  WidgetTester tester,
  RenderParagraph paragraph,
) async {
  final rect = paragraph
      .getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      )
      .first
      .toRect();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixels),
  );
  final point = boundary.globalToLocal(paragraph.localToGlobal(rect.center));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
      return bytes!.buffer
          .asUint8List(bytes.offsetInBytes + offset, 4)
          .toList();
    } finally {
      image.dispose();
    }
  }))!;
}

RenderParagraph _fallback(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text(':missing:'),
        matching: find.byType(RichText),
      ),
    );

void main() {
  test('context style participates in equality, hash and diagnostics', () {
    const a = MfmEmojiContext(fontSize: 20, scale: 1, textStyle: _root);
    const b = MfmEmojiContext(fontSize: 20, scale: 1, textStyle: _root);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const MfmEmojiContext(fontSize: 20, scale: 1)));
    expect(a.toString(), contains('textStyle: $_root'));
  });

  test('helper accepts legacy contexts without textStyle', () {
    final helper = MfmEmojiConfig.fromResolver(
      resolver: (_) async => null,
      emojiSize: 80,
    );
    final emoji =
        helper.emojiBuilder!(
              'missing',
              const MfmEmojiContext(fontSize: 20, scale: 1),
            )
            as MfmCustomEmoji;
    expect(emoji.size, 80);
    expect(emoji.fallbackTextStyle, const TextStyle(fontSize: 20));
    final remote =
        helper.emojiBuilder!(
              'missing',
              const MfmEmojiContext(
                fontSize: 20,
                scale: 1,
                host: 'remote.test',
              ),
            )
            as Text;
    expect(remote.style, const TextStyle(fontSize: 20));
  });

  for (final testCase in [
    (text: ':missing:', color: _red, size: 20.0, opacity: 1.0),
    (text: '<small>:missing:</small>', color: _red, size: 16.0, opacity: 0.7),
    (
      text: '<small><small>:missing:</small></small>',
      color: _red,
      size: 12.8,
      opacity: 0.49,
    ),
    (
      text: r'$[fg.color=00f <small>:missing:</small>]',
      color: const Color(0xff0000ff),
      size: 16.0,
      opacity: 0.7,
    ),
    (
      text: r'<small>$[fg.color=00f :missing:]</small>',
      color: const Color(0xff0000ff),
      size: 16.0,
      opacity: 0.7,
    ),
    (
      text: '> <small><small>:missing:</small></small>',
      color: _red,
      size: 12.8,
      opacity: 0.343,
    ),
    (
      text: '<small>[:missing:](https://example.test)</small>',
      color: const Color(0xff0000ff),
      size: 16.0,
      opacity: 0.7,
    ),
    (
      text: r'$[rainbow <small>:missing:</small>]',
      color: _red,
      size: 16.0,
      opacity: 0.7,
    ),
  ]) {
    testWidgets('helper style and painted alpha: ${testCase.text}', (
      tester,
    ) async {
      final helper = MfmEmojiConfig.fromResolver(resolver: (_) async => null);
      MfmEmojiContext? received;
      final config = helper.copyWith(
        baseTextStyle: _root,
        enableAnimation: false,
        lightColorScheme: const MfmColorScheme.light(
          fg: _red,
          link: Color(0xff0000ff),
        ),
        // A closure around the helper must not change opacity policy.
        emojiBuilder: (name, context) {
          received = context;
          return helper.emojiBuilder!(name, context);
        },
      );
      await tester.pumpWidget(_host(testCase.text, config));
      await tester.pump();
      final style = tester.widget<Text>(find.text(':missing:')).style!;
      expect(style, received!.textStyle);
      expect(style.color, testCase.color);
      expect(style.fontSize, closeTo(testCase.size, 1e-9));
      final pixel = await _letterPixel(tester, _fallback(tester));
      final isBlue = testCase.color == const Color(0xff0000ff);
      expect(pixel[isBlue ? 2 : 0], closeTo(255, 2));
      expect(pixel[isBlue ? 0 : 2], closeTo(0, 2));
      expect(pixel[3], closeTo((isBlue ? 1 : 0.5) * testCase.opacity * 255, 2));
    });
  }

  testWidgets('font, weight, italic, strike and secondary colors stay raw', (
    tester,
  ) async {
    final foreground = Paint()..color = _red;
    final background = Paint()..color = const Color(0x80660000);
    final style = TextStyle(
      fontSize: 20,
      foreground: foreground,
      background: background,
      decorationColor: const Color(0x80770000),
      shadows: const [Shadow(color: Color(0x80880000))],
    );
    final contexts = <MfmEmojiContext>[];
    await tester.pumpWidget(
      _host(
        r'<small>**<i>~~$[font.monospace :missing: 😀]~~</i>**</small>',
        MfmRenderConfig(
          baseTextStyle: style,
          emojiBuilder: (_, context) {
            contexts.add(context);
            return const SizedBox();
          },
          unicodeEmojiBuilder: (_, context) {
            contexts.add(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(contexts, hasLength(2));
    for (final context in contexts) {
      final raw = context.textStyle!;
      expect(raw.fontSize, 16);
      expect(raw.fontFamily, 'Courier');
      expect(raw.fontWeight, FontWeight.bold);
      expect(raw.fontStyle, FontStyle.italic);
      expect(raw.decoration, TextDecoration.lineThrough);
      expect(raw.foreground, same(foreground));
      expect(raw.background, same(background));
      expect(raw.decorationColor, style.decorationColor);
      expect(raw.shadows, style.shadows);
    }
    expect(foreground.color, _red);
    expect(background.color.toARGB32(), 0x80660000);
  });

  testWidgets('foreground Paint retains original alpha before outer opacity', (
    tester,
  ) async {
    final foreground = Paint()..color = _red;
    final original = foreground.color;
    final config = MfmEmojiConfig.fromResolver(resolver: (_) async => null)
        .copyWith(
          baseTextStyle: TextStyle(
            fontFamily: 'Ahem',
            fontSize: 20,
            foreground: foreground,
          ),
        );
    await tester.pumpWidget(_host('<small>:missing:</small>', config));
    await tester.pump();
    expect(
      tester.widget<Text>(find.text(':missing:')).style!.foreground,
      same(foreground),
    );
    final pixel = await _letterPixel(tester, _fallback(tester));
    expect(pixel[3], closeTo(0.35 * 255, 2));
    expect(foreground.color, original);
  });

  testWidgets('quote and link do not dim secondary fallback colors', (
    tester,
  ) async {
    final background = Paint()..color = const Color(0x80660000);
    final root = _root.copyWith(
      background: background,
      decorationColor: const Color(0x80770000),
      shadows: const [Shadow(color: Color(0x80880000))],
      decoration: TextDecoration.lineThrough,
    );
    MfmEmojiContext? received;
    await tester.pumpWidget(
      _host(
        '> <small>[:missing:](https://example.test)</small>',
        MfmRenderConfig(
          baseTextStyle: root,
          emojiBuilder: (_, context) {
            received = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final style = received!.textStyle!;
    expect(style.background, same(background));
    expect(style.decorationColor, root.decorationColor);
    expect(style.shadows, root.shadows);
    expect(style.decoration, TextDecoration.none);
    expect(style.color, const MfmColorScheme.light().link);
  });

  for (final mode in ['context', 'legacy', 'unicode']) {
    testWidgets('$mode builder keeps outer opacity', (tester) async {
      Widget builder(String _, MfmEmojiContext context) => Text(
        ':missing:',
        style: mode == 'legacy' ? _root : context.textStyle,
      );
      await tester.pumpWidget(
        _host(
          mode == 'unicode' ? '<small>😀</small>' : '<small>:missing:</small>',
          MfmRenderConfig(
            baseTextStyle: _root,
            emojiBuilder: builder,
            unicodeEmojiBuilder: builder,
          ),
        ),
      );
      final pixel = await _letterPixel(tester, _fallback(tester));
      expect(pixel[3], closeTo(0.35 * 255, 2));
    });
  }

  for (final branch in [
    'no builder',
    'missing remote map',
    'remote without URL',
    'resolver error',
  ]) {
    testWidgets('$branch preserves shortcode style', (tester) async {
      var calls = 0;
      final helper = MfmEmojiConfig.fromResolver(
        resolver: (_) {
          calls++;
          return Future<EmojiImage?>.error(StateError('missing'));
        },
      );
      final config = (branch == 'no builder' ? const MfmRenderConfig() : helper)
          .copyWith(
            baseTextStyle: _root,
            author: branch.contains('remote')
                ? const MfmAuthorContext(host: 'remote.test')
                : null,
            emojiUrls: branch == 'missing remote map' ? {} : null,
          );
      await tester.pumpWidget(_host('<small>:missing:</small>', config));
      await tester.pump();
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText).last,
      );
      expect(paragraph.text.toPlainText(), ':missing:');
      final pixel = await _letterPixel(tester, paragraph);
      expect(pixel[3], closeTo(0.35 * 255, 2));
      expect(calls, branch == 'resolver error' ? 1 : 0);
    });
  }
}
