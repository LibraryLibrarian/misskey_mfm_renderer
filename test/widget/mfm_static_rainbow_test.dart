import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_widget.dart';

const ValueKey<String> _boundaryKey = ValueKey('pixels');
const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _style = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 20,
  height: 1,
  color: Color(0xFF222222),
);

Widget _host(
  String text, {
  bool advanced = true,
  bool animation = false,
  double? width,
  TextDirection direction = TextDirection.ltr,
  TextStyle style = _style,
  Widget Function(String, MfmEmojiContext)? emojiBuilder,
  Widget Function(String, MfmEmojiContext)? unicodeEmojiBuilder,
  void Function(String)? onLinkTap,
}) => Directionality(
  textDirection: direction,
  child: Center(
    child: RepaintBoundary(
      key: _boundaryKey,
      child: SizedBox(
        width: width,
        child: MfmText(
          text: text,
          config: MfmRenderConfig(
            baseTextStyle: style,
            enableAdvancedMfm: advanced,
            enableAnimation: animation,
            emojiBuilder: emojiBuilder,
            unicodeEmojiBuilder: unicodeEmojiBuilder,
            onLinkTap: onLinkTap,
          ),
        ),
      ),
    ),
  ),
);

RenderParagraph _paragraph(WidgetTester tester, String text) {
  return tester.renderObject<RenderParagraph>(
    find
        .byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText() == text,
        )
        .last,
  );
}

Offset _letterCenter(RenderParagraph paragraph, int index) {
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      )
      .single;
  return paragraph.localToGlobal(box.toRect().center);
}

Future<List<int>> _pixel(WidgetTester tester, Offset global) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final local = boundary.globalToLocal(global);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      final offset = (local.dy.floor() * image.width + local.dx.floor()) * 4;
      return bytes!.buffer
          .asUint8List(bytes.offsetInBytes + offset, 4)
          .toList();
    } finally {
      image.dispose();
    }
  }))!;
}

void _expectColor(List<int> actual, Color expected, {double tolerance = 2}) {
  final channels = [expected.r, expected.g, expected.b, expected.a];
  for (var i = 0; i < 4; i++) {
    expect(
      actual[i],
      closeTo(channels[i] * 255, tolerance),
      reason: 'channel $i',
    );
  }
}

Future<ui.Image> _emojiImage(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..drawRect(const Rect.fromLTWH(0, 0, 20, 20), Paint()..color = _red)
      ..drawRect(const Rect.fromLTWH(20, 0, 20, 20), Paint()..color = _blue);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(40, 20);
    } finally {
      picture.dispose();
    }
  }))!;
}

Widget _directHost(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: RepaintBoundary(
      key: _boundaryKey,
      child: SizedBox(width: 80, child: child),
    ),
  ),
);

void main() {
  testWidgets('基準文字色のalphaをsmallの内外で保持する', (tester) async {
    for (final text in [
      r'$[rainbow A]',
      r'<small>$[rainbow A]</small>',
      r'$[rainbow <small>A</small>]',
      r'$[rainbow **A**]',
    ]) {
      await tester.pumpWidget(
        _host(
          text,
          style: _style.copyWith(color: const Color(0x80222222)),
        ),
      );
      final pixel = await _pixel(
        tester,
        _letterCenter(_paragraph(tester, 'A'), 0),
      );
      expect(pixel[3], closeTo(128 * (text.contains('small') ? 0.7 : 1), 2));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('インラインコードの文字拡大設定をON/OFFで維持する', (tester) async {
    Size? expected;
    for (final animation in [true, false, true]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _host(r'$[rainbow `AAA`]', animation: animation),
        ),
      );
      final paragraph = _paragraph(tester, 'AAA');
      expect(paragraph.textScaler, const TextScaler.linear(2));
      expected ??= paragraph.size;
      expect(paragraph.size, expected);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('直接渡したTextの継承設定とsemanticsを保持する', (tester) async {
    await tester.pumpWidget(
      _directHost(
        const DefaultTextStyle(
          style: _style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          child: MfmStaticRainbowWidget(
            child: Text(
              'AAAAAA',
              semanticsLabel: 'expanded description',
              semanticsIdentifier: 'rainbow-description',
              // ignore: deprecated_member_use
              textScaleFactor: 1.5,
            ),
          ),
        ),
      ),
    );
    final paragraph = _paragraph(tester, 'AAAAAA');
    expect(paragraph.maxLines, 1);
    expect(paragraph.softWrap, isFalse);
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.textAlign, TextAlign.right);
    expect(paragraph.textScaler, const TextScaler.linear(1.5));
    expect(find.semantics.byLabel('expanded description'), findsOne);
    final node = find.semantics
        .byLabel('expanded description')
        .evaluate()
        .single;
    expect(node.getSemanticsData().identifier, 'rainbow-description');
    expect(tester.takeException(), isNull);
  });

  for (final softWrap in [false, true]) {
    testWidgets('直接渡したTextのfadeを保持する softWrap=$softWrap', (tester) async {
      int? expectedAlpha;
      for (final rainbow in [false, true]) {
        final text = Text(
          'AAAAAAAAAAAA',
          style: _style,
          softWrap: softWrap,
          maxLines: 1,
          overflow: TextOverflow.fade,
        );
        await tester.pumpWidget(
          _directHost(
            rainbow ? MfmStaticRainbowWidget(child: text) : text,
          ),
        );
        final paragraph = _paragraph(tester, 'AAAAAAAAAAAA');
        final pixel = await _pixel(
          tester,
          paragraph.localToGlobal(
            softWrap ? const Offset(10, 18) : const Offset(75, 10),
          ),
        );
        expectedAlpha ??= pixel[3];
        expect(pixel[3], inExclusiveRange(0, 255));
        expect(pixel[3], closeTo(expectedAlpha, 1));
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final flags in [
    (advanced: true, animation: false),
    (advanced: false, animation: true),
    (advanced: false, animation: false),
  ]) {
    testWidgets('静的rainbowはfgの明示色を保持する $flags', (tester) async {
      await tester.pumpWidget(
        _host(
          r'$[rainbow AA $[fg.color=ff0000 BB] CC]',
          advanced: flags.advanced,
          animation: flags.animation,
        ),
      );
      final paragraph = _paragraph(tester, 'AA BB CC');
      _expectColor(await _pixel(tester, _letterCenter(paragraph, 3)), _red);
      final first = await _pixel(tester, _letterCenter(paragraph, 0));
      final last = await _pixel(tester, _letterCenter(paragraph, 7));
      expect(first, isNot(last));
      expect(first[3], 255);
      expect(last[3], 255);
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('カスタム絵文字とunicode絵文字の実画像のRGBを保持する', (tester) async {
    final image = await _emojiImage(tester);
    addTearDown(image.dispose);
    Widget emoji(String name, MfmEmojiContext context) => RawImage(
      key: ValueKey(name),
      image: image,
      width: 40,
      height: 20,
    );
    await tester.pumpWidget(
      _host(
        r'$[rainbow A :test: 🙂 B]',
        emojiBuilder: emoji,
        unicodeEmojiBuilder: emoji,
      ),
    );
    for (final name in ['test', '🙂']) {
      final rect = tester.getRect(find.byKey(ValueKey(name)));
      _expectColor(
        await _pixel(tester, rect.topLeft + const Offset(5, 10)),
        _red,
      );
      _expectColor(
        await _pixel(tester, rect.topLeft + const Offset(30, 10)),
        _blue,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('背景と罫線を保持しWidgetSpan内でも文字のグラデーションを継承する', (tester) async {
    await tester.pumpWidget(
      _host(
        r'$[rainbow XX $[bg.color=00ff00 A A] '
        r'$[border.color=0000ff,width=3 B] ZZ]',
      ),
    );
    final background = _paragraph(tester, 'A A');
    _expectColor(
      await _pixel(tester, _letterCenter(background, 1)),
      const Color(0xFF00FF00),
    );
    final letter = await _pixel(tester, _letterCenter(background, 0));
    expect(letter, isNot([0, 255, 0, 255]));
    expect(letter, isNot([34, 34, 34, 255]));
    final borderText = _paragraph(tester, 'B');
    _expectColor(
      await _pixel(
        tester,
        borderText.localToGlobal(Offset(borderText.size.width / 2, -2)),
      ),
      const Color(0xFF0000FF),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fgの色はbgや太字を挟んでも維持し外側のfgはrainbowが上書きする', (tester) async {
    await tester.pumpWidget(
      _host(
        r'$[fg.color=0000ff $[rainbow AA '
        r'$[fg.color=ff0000 $[bg.color=00ff00 **BB**]] CC]]',
      ),
    );
    final red = _paragraph(tester, 'BB');
    _expectColor(await _pixel(tester, _letterCenter(red, 0)), _red);
    final outer = tester.renderObject<RenderParagraph>(
      find.byType(MfmRainbowRichText).first,
    );
    final color = await _pixel(tester, _letterCenter(outer, 0));
    expect(color, isNot([0, 0, 255, 255]));
    expect(color[3], 255);
  });

  testWidgets('Markdownリンクの明示色とsemanticsを保持する', (tester) async {
    await tester.pumpWidget(
      _host(
        r'$[rainbow A [LINK](https://example.com) B]',
        onLinkTap: (_) {},
      ),
    );
    final paragraph = _paragraph(tester, 'A LINK B');
    _expectColor(
      await _pixel(tester, _letterCenter(paragraph, 3)),
      const MfmColorScheme.light().link,
    );
    expect(find.semantics.byLabel(RegExp('LINK')), findsOne);
    expect(tester.takeException(), isNull);
  });

  for (final rainbow in [false, true]) {
    testWidgets('URLリンクの明示色・タップ動作とsemanticsを保持する rainbow=$rainbow', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          rainbow
              ? r'$[rainbow A https://example.com B]'
              : 'A https://example.com B',
          onLinkTap: taps.add,
        ),
      );
      final paragraph = _paragraph(tester, 'A https://example.com/￼ B');
      final center = _letterCenter(paragraph, 10);
      _expectColor(
        await _pixel(tester, center),
        const MfmColorScheme.light().link,
      );
      await tester.tapAt(center);
      expect(taps, ['https://example.com']);
      expect(find.semantics.byLabel('example.com'), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('smallの透明度を文字・明示色・絵文字で二重適用しない', (tester) async {
    const emojiKey = ValueKey('small-emoji');
    await tester.pumpWidget(
      _host(
        r'<small>$[rainbow A $[fg.color=ff0000 B] :test:]</small>',
        emojiBuilder: (_, context) => const SizedBox(
          key: emojiKey,
          width: 20,
          height: 20,
          child: ColoredBox(color: _red),
        ),
      ),
    );
    final paragraph = _paragraph(tester, 'A B ￼');
    final plain = await _pixel(tester, _letterCenter(paragraph, 0));
    expect(plain[3], closeTo(255 * 0.7, 2));
    _expectColor(
      await _pixel(tester, _letterCenter(paragraph, 2)),
      _red.withValues(alpha: 0.7),
    );
    _expectColor(
      await _pixel(tester, tester.getCenter(find.byKey(emojiKey))),
      _red.withValues(alpha: 0.7),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rainbow内のsmallと半透明fgのalphaを保持する', (tester) async {
    await tester.pumpWidget(
      _host(r'$[rainbow A <small>B $[fg.color=f008 C]</small> D]'),
    );
    final paragraph = _paragraph(tester, 'A B C D');
    expect(
      (await _pixel(tester, _letterCenter(paragraph, 2)))[3],
      closeTo(255 * 0.7, 2),
    );
    _expectColor(
      await _pixel(tester, _letterCenter(paragraph, 4)),
      _red.withValues(alpha: (136 / 255) * 0.7),
    );
  });

  testWidgets('インラインコードの背景は保持し文字だけグラデーションにする', (tester) async {
    await tester.pumpWidget(_host(r'$[rainbow XX `A A` YY]'));
    final paragraph = _paragraph(tester, 'A A');
    _expectColor(
      await _pixel(tester, _letterCenter(paragraph, 1)),
      const MfmColorScheme.light().bg,
    );
    final foreground = await _pixel(tester, _letterCenter(paragraph, 0));
    expect(foreground, isNot([34, 34, 34, 255]));
    expect(foreground[3], 255);
  });

  testWidgets('WidgetSpanの前後でグラデーションが再開しない', (tester) async {
    await tester.pumpWidget(_host(r'$[rainbow AAA$[bg.color=ffffff BBB]CCC]'));
    final background = _paragraph(tester, 'BBB');
    final nested = await _pixel(tester, _letterCenter(background, 1));
    await tester.pumpWidget(_host(r'$[rainbow AAABBBCCC]'));
    final plain = _paragraph(tester, 'AAABBBCCC');
    final expected = await _pixel(tester, _letterCenter(plain, 4));
    for (var channel = 0; channel < 4; channel++) {
      expect(nested[channel], closeTo(expected[channel], 2));
    }
  });

  testWidgets('入れ子のrainbowは独立したグラデーション範囲を持つ', (tester) async {
    await tester.pumpWidget(_host(r'$[rainbow AAA$[rainbow BBB]CCC]'));
    final nested = _paragraph(tester, 'BBB');
    final nestedColor = await _pixel(tester, _letterCenter(nested, 0));
    await tester.pumpWidget(_host(r'$[rainbow BBB]'));
    final standalone = _paragraph(tester, 'BBB');
    expect(await _pixel(tester, _letterCenter(standalone, 0)), nestedColor);
  });

  testWidgets('幅・本文・文字サイズの更新後も描画範囲とbaselineが正しい', (tester) async {
    for (final value in [
      (width: 400.0, text: 'A A A A A A', size: 20.0),
      (width: 100.0, text: 'A A A A A A', size: 20.0),
      (width: 300.0, text: 'BBBB', size: 30.0),
    ]) {
      await tester.pumpWidget(
        _host(
          '\$[rainbow ${value.text}]',
          width: value.width,
          style: _style.copyWith(fontSize: value.size),
        ),
      );
      await tester.pumpAndSettle();
      final paragraph = _paragraph(tester, value.text);
      final pixel = await _pixel(tester, _letterCenter(paragraph, 0));
      expect(pixel[0], 255);
      expect(pixel[2], 0);
      expect(pixel[3], 255);
      final outer = tester.renderObject<RenderParagraph>(
        find.byType(RichText).first,
      );
      expect(
        paragraph
            .localToGlobal(
              Offset(
                0,
                paragraph.getDryBaseline(
                  paragraph.constraints,
                  TextBaseline.alphabetic,
                )!,
              ),
            )
            .dy,
        closeTo(
          outer
              .localToGlobal(
                Offset(
                  0,
                  outer.getDryBaseline(
                    outer.constraints,
                    TextBaseline.alphabetic,
                  )!,
                ),
              )
              .dy,
          1e-6,
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('rubyの本文とルビを着色し内側のfgの色は保持する', (tester) async {
    for (final explicit in [false, true]) {
      await tester.pumpWidget(
        _host(
          explicit
              ? r'$[rainbow AA $[ruby $[fg.color=ff0000 BB] CC] DD]'
              : r'$[rainbow AA $[ruby BB CC] DD]',
        ),
      );
      final ruby = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_RubyTextWidget',
      );
      final rect = tester.getRect(ruby);
      final base = await _pixel(tester, rect.topLeft + const Offset(10, 20));
      final annotation = await _pixel(
        tester,
        rect.topLeft + const Offset(15, 5),
      );
      if (explicit) {
        _expectColor(base, _red);
      } else {
        expect(base, isNot([34, 34, 34, 255]));
      }
      expect(base[3], 255);
      expect(annotation, isNot([34, 34, 34, 255]));
      expect(annotation[3], 255);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('RTLでもグラデーションは物理的に左から右へ描く', (tester) async {
    await tester.pumpWidget(
      _host(r'$[rainbow ABCD]', direction: TextDirection.rtl),
    );
    final paragraph = _paragraph(tester, 'ABCD');
    final left = await _pixel(
      tester,
      paragraph.localToGlobal(const Offset(5, 10)),
    );
    final right = await _pixel(
      tester,
      paragraph.localToGlobal(const Offset(75, 10)),
    );
    expect(left[0], 255);
    expect(left[2], 0);
    expect(right[2], 255);
    expect(right[1], 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ON/OFF切替後も静的fgと絵文字の色が元に戻る', (tester) async {
    const emojiKey = ValueKey('toggle-emoji');
    for (final animation in [false, true, false]) {
      await tester.pumpWidget(
        _host(
          r'$[rainbow A $[fg.color=ff0000 B] :test:]',
          animation: animation,
          emojiBuilder: (_, context) => const SizedBox(
            key: emojiKey,
            width: 20,
            height: 20,
            child: ColoredBox(color: _blue),
          ),
        ),
      );
      if (animation) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(ColorFiltered), findsNWidgets(3));
      } else {
        final paragraph = _paragraph(tester, 'A B ￼');
        _expectColor(await _pixel(tester, _letterCenter(paragraph, 2)), _red);
        _expectColor(
          await _pixel(tester, tester.getCenter(find.byKey(emojiKey))),
          _blue,
        );
        expect(find.byType(ColorFiltered), findsNothing);
      }
      expect(tester.takeException(), isNull);
    }
  });
}
