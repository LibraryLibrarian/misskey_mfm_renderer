import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_emoji_baseline.dart';

const _style = TextStyle(fontFamily: 'Ahem', fontSize: 20, color: Colors.red);
const _context = MfmEmojiContext(fontSize: 20, scale: 4, textStyle: _style);
const _target = Key('emoji');

class _BaselineProbe extends SingleChildRenderObjectWidget {
  const _BaselineProbe({required super.child});

  @override
  _RenderBaselineProbe createRenderObject(BuildContext context) =>
      _RenderBaselineProbe();
}

class _RenderBaselineProbe extends RenderProxyBox {
  double? actualBaseline;

  @override
  void performLayout() {
    super.performLayout();
    actualBaseline = child!.getDistanceToBaseline(
      TextBaseline.alphabetic,
      onlyReal: true,
    );
  }
}

class _ControlledImage extends ImageProvider<_ControlledImage> {
  final result = Completer<ImageInfo>();
  int loads = 0;

  @override
  Future<_ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ControlledImage key,
    ImageDecoderCallback decode,
  ) {
    loads++;
    return OneFrameImageStreamCompleter(result.future);
  }

  Future<void> succeed() async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = Colors.green);
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    picture.dispose();
    result.complete(ImageInfo(image: image));
  }

  void fail() => result.completeError(StateError('image failed'));
}

Widget _host(Widget child, {double textScale = 1}) => Directionality(
  textDirection: TextDirection.rtl,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: DefaultTextStyle(
      style: _style,
      child: Center(
        child: Baseline(
          baseline: 100,
          baselineType: TextBaseline.alphabetic,
          child: KeyedSubtree(
            key: _target,
            child: _BaselineProbe(child: child),
          ),
        ),
      ),
    ),
  ),
);

void _imageBaseline(WidgetTester tester, {double fontSize = 20}) {
  final box = tester.renderObject<_RenderBaselineProbe>(find.byKey(_target));
  expect(box.size, Size.square(fontSize * 1.25));
  expect(box.actualBaseline, fontSize);
  expect(
    box.getDryBaseline(box.constraints, TextBaseline.alphabetic),
    fontSize,
  );
  final baseline = tester.getTopLeft(find.byType(Baseline)).dy + 100;
  expect(
    tester.getBottomLeft(find.byKey(_target)).dy - baseline,
    fontSize * .25,
  );
}

void _naturalBaseline(WidgetTester tester, String text) {
  final box = tester.renderObject<_RenderBaselineProbe>(find.byKey(_target));
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  expect(box.size, paragraph.size);
  expect(
    box.actualBaseline,
    paragraph.getDryBaseline(paragraph.constraints, TextBaseline.alphabetic),
  );
  expect(
    box.getDryBaseline(box.constraints, TextBaseline.alphabetic),
    paragraph.getDryBaseline(paragraph.constraints, TextBaseline.alphabetic),
  );
  expect(find.byType(MfmEmojiBaseline), findsNothing);
}

List<SemanticsNode> _semantics(WidgetTester tester) {
  final result = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    result.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester
        .renderObject(find.byType(Directionality).first)
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return result;
}

// Explicit nulls below test the existing inheritance/copyWith contract.
// ignore_for_file: avoid_redundant_argument_values

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  for (final success in [true, false]) {
    testWidgets(
      'pending to ${success ? 'success' : 'error'} baseline and label',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final provider = _ControlledImage();
        final helper = MfmTwemojiBuilder(imageProvider: (_) => provider);
        await tester.pumpWidget(_host(helper.build('❤️', _context)));
        _imageBaseline(tester);
        expect(find.byType(RawImage), findsNothing);
        expect(find.text('❤️'), findsNothing);
        void label() {
          final nodes = _semantics(
            tester,
          ).where((node) => node.label.contains('❤️'));
          expect(nodes, hasLength(1));
          expect(nodes.single.label, '❤️');
          expect(
            nodes.single.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
        }

        label();
        if (success) {
          await tester.runAsync(provider.succeed);
        } else {
          provider.fail();
        }
        await tester.pump();
        await tester.pump();
        if (success) {
          _imageBaseline(tester);
          final raw = tester.widget<RawImage>(find.byType(RawImage));
          expect(raw.image, isNotNull);
          expect(raw.color, isNull);
          expect(raw.fit, BoxFit.contain);
        } else {
          _naturalBaseline(tester, '❤️');
          expect(tester.widget<Text>(find.text('❤️')).style, _style);
        }
        label();
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'null and guarded fallback retain original and all style without scaling',
    (tester) async {
      final paint = Paint()..color = const Color(0x806622aa);
      final background = Paint()..color = const Color(0x80773322);
      final style = _style.copyWith(
        foreground: paint,
        background: background,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        letterSpacing: 2,
        wordSpacing: 3,
        height: 1.4,
        decoration: TextDecoration.underline,
        decorationColor: Colors.orange,
        shadows: const [Shadow(color: Colors.blue, blurRadius: 2)],
      );
      final context = MfmEmojiContext(fontSize: 20, scale: 8, textStyle: style);
      final helper = MfmTwemojiBuilder(imageProvider: (_) => null);
      for (final emoji in ['❤️', '❤︎', '️', '']) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(
            _host(helper.build(emoji, context), textScale: scale),
          );
          final text = tester.widget<Text>(find.text(emoji));
          expect(text.style, same(style));
          expect(text.style!.foreground, same(paint));
          expect(text.style!.background, same(background));
          expect(text.textScaler, TextScaler.noScaling);
          _naturalBaseline(tester, emoji);
        }
      }
      await tester.pumpWidget(
        _host(
          helper.build('😀', const MfmEmojiContext(fontSize: 17, scale: 8)),
        ),
      );
      expect(
        tester.widget<Text>(find.text('😀')).style,
        const TextStyle(fontSize: 17),
      );
    },
  );

  testWidgets(
    'style updates keep stream; source changes discard old late completion',
    (tester) async {
      final old = _ControlledImage();
      final next = _ControlledImage();
      ImageProvider<Object>? provider = old;
      final helper = MfmTwemojiBuilder(imageProvider: (_) => provider);
      await tester.pumpWidget(_host(helper.build('😀', _context)));
      final initial = tester.state(find.byType(Image));
      const changed = MfmEmojiContext(
        fontSize: 30,
        scale: 1,
        textStyle: TextStyle(fontSize: 30),
      );
      await tester.pumpWidget(_host(helper.build('😀', changed)));
      expect(tester.state(find.byType(Image)), same(initial));
      expect(old.loads, 1);
      _imageBaseline(tester, fontSize: 30);
      provider = next;
      await tester.pumpWidget(_host(helper.build('😀', changed)));
      expect(tester.state(find.byType(Image)), isNot(same(initial)));
      await tester.runAsync(old.succeed);
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      next.fail();
      await tester.pump();
      await tester.pump();
      _naturalBaseline(tester, '😀');
      expect(tester.widget<Text>(find.text('😀')).style, changed.textStyle);
      provider = null;
      await tester.pumpWidget(_host(helper.build('❤️', _context)));
      expect(find.byType(Image), findsNothing);
      expect(find.text('😀'), findsNothing);
      _naturalBaseline(tester, '❤️');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'different emoji same provider changes identity; late dispose is harmless',
    (tester) async {
      final provider = _ControlledImage();
      final helper = MfmTwemojiBuilder(imageProvider: (_) => provider);
      await tester.pumpWidget(_host(helper.build('😀', _context)));
      final first = tester.state(find.byType(Image));
      await tester.pumpWidget(_host(helper.build('❤️', _context)));
      expect(tester.state(find.byType(Image)), isNot(same(first)));
      expect(
        tester.widget<Image>(find.byType(Image)).key,
        ValueKey<(String, ImageProvider<Object>)>(('❤️', provider)),
      );
      expect(tester.widget<Image>(find.byType(Image)).gaplessPlayback, isFalse);
      expect(provider.loads, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(provider.succeed);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  for (final failed in [false, true]) {
    testWidgets(
      'settled image style retention and replacement failed=$failed',
      (tester) async {
        final first = _ControlledImage();
        final next = _ControlledImage();
        var provider = first;
        final helper = MfmTwemojiBuilder(imageProvider: (_) => provider);
        await tester.pumpWidget(_host(helper.build('©', _context)));
        if (failed) {
          first.fail();
        } else {
          await tester.runAsync(first.succeed);
        }
        await tester.pump();
        await tester.pump();
        final state = tester.state(find.byType(Image));
        const style = TextStyle(
          fontSize: 30,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
        const context = MfmEmojiContext(
          fontSize: 30,
          scale: 8,
          textStyle: style,
        );
        await tester.pumpWidget(_host(helper.build('©', context)));
        expect(tester.state(find.byType(Image)), same(state));
        expect(first.loads, 1);
        if (failed) {
          expect(tester.widget<Text>(find.text('©')).style, style);
          _naturalBaseline(tester, '©');
        } else {
          _imageBaseline(tester, fontSize: 30);
          expect(
            tester.widget<RawImage>(find.byType(RawImage)).image,
            isNotNull,
          );
        }
        provider = next;
        await tester.pumpWidget(_host(helper.build('©', context)));
        expect(find.byType(RawImage), findsNothing);
        expect(find.text('©'), findsNothing);
        _imageBaseline(tester, fontSize: 30);
        await tester.runAsync(next.succeed);
        await tester.pump();
        await tester.pump();
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('nonuniform scale applies once outside the image', (
    tester,
  ) async {
    final helper = MfmTwemojiBuilder(imageProvider: (_) => _ControlledImage());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MfmText(
            text: r'$[scale.x=3,y=2 😀]',
            config: MfmRenderConfig(
              baseTextStyle: _style,
              unicodeEmojiBuilder: helper.build,
            ),
          ),
        ),
      ),
    );
    final image = tester.renderObject<RenderBox>(find.byType(Image));
    expect(image.size, const Size(25, 25));
    final origin = image.localToGlobal(Offset.zero);
    final end = image.localToGlobal(const Offset(25, 25));
    expect(end - origin, const Offset(75, 50));
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    ('https://example.test', 'https://example.test/1f600.png'),
    ('https://example.test/png', 'https://example.test/png/1f600.png'),
    (
      'http://example.test:8080/a%20b/x%2Fy/',
      'http://example.test:8080/a%20b/x%2Fy/1f600.png',
    ),
  ]) {
    testWidgets('network directory preserves ${entry.$1}', (tester) async {
      final helper = MfmTwemojiBuilder.network(baseUrl: Uri.parse(entry.$1));
      final image = Completer<ImageInfo>();
      var loads = 0;
      PaintingBinding.instance.imageCache.putIfAbsent(
        NetworkImage(entry.$2),
        () {
          loads++;
          return OneFrameImageStreamCompleter(image.future);
        },
      );
      final widget = helper.build('😀', _context);
      expect(loads, 1);
      await tester.pumpWidget(_host(widget));
      expect(
        (tester.widget<Image>(find.byType(Image)).image as NetworkImage).url,
        entry.$2,
      );
      image.completeError(StateError('controlled network failure'));
      await tester.pump();
      await tester.pump();
      _naturalBaseline(tester, '😀');
      expect(tester.takeException(), isNull);
    });
  }

  for (final state in ['pending', 'success', 'error', 'null']) {
    testWidgets('emoji-only link pointer and semantics in $state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final provider = _ControlledImage();
      final helper = MfmTwemojiBuilder(
        imageProvider: (_) => state == 'null' ? null : provider,
      );
      final taps = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'before [❤️](https://outside.test/a) after',
              config: MfmRenderConfig(
                unicodeEmojiBuilder: helper.build,
                onLinkTap: taps.add,
              ),
            ),
          ),
        ),
      );
      if (state == 'success') await tester.runAsync(provider.succeed);
      if (state == 'error') provider.fail();
      await tester.pump();
      await tester.pump();
      if (state == 'success') {
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      } else if (state == 'error' || state == 'null') {
        expect(find.text('❤️'), findsOneWidget);
      } else {
        expect(find.byType(RawImage), findsNothing);
      }
      final labels = _semantics(
        tester,
      ).where((node) => node.label.contains('❤️')).toList();
      expect(labels, hasLength(1));
      expect(labels.single.label, '❤️');
      expect(
        labels.single.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      for (final node in _semantics(tester).where(
        (node) => node.label.contains('before') || node.label.contains('after'),
      )) {
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      }
      // The pending transparent box is intentionally not a hit-test target;
      // tap its actual coordinates through the renderer's outer link bridge.
      await tester.tapAt(
        tester.getCenter(
          state == 'null' || state == 'error'
              ? find.text('❤️')
              : find.byType(Image),
        ),
      );
      expect(taps, ['https://outside.test/a']);
      tester
          .renderObject(find.byType(Directionality).first)
          .owner!
          .semanticsOwner!
          .performAction(
            labels.single.id,
            SemanticsAction.tap,
          );
      expect(taps, ['https://outside.test/a', 'https://outside.test/a']);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  final sizes = [
    ('😀', 14.0),
    (r'$[x2 😀]', 28.0),
    (r'$[x3 😀]', 56.0),
    (r'$[x4 😀]', 84.0),
    (r'$[scale.x=3,y=1 😀]', 14.0),
    (r'$[tada 😀]', 21.0),
    ('<small>😀</small>', 11.2),
  ];
  for (final entry in sizes) {
    for (final advanced in [true, false]) {
      testWidgets('context size ${entry.$1} advanced=$advanced', (
        tester,
      ) async {
        final provider = _ControlledImage();
        final helper = MfmTwemojiBuilder(imageProvider: (_) => provider);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: entry.$1,
                config: MfmRenderConfig(
                  baseTextStyle: const TextStyle(fontSize: 14),
                  enableAnimation: false,
                  enableAdvancedMfm: advanced,
                  unicodeEmojiBuilder: helper.build,
                ),
              ),
            ),
          ),
        );
        final size =
            advanced || entry.$1.contains('small') || entry.$1.contains('tada')
            ? entry.$2
            : 14.0;
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.width, closeTo(size * 1.25, 1e-9));
        expect(image.height, closeTo(size * 1.25, 1e-9));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final state in ['pending', 'success', 'error', 'null']) {
    for (final entry in [
      ('©', 1.0),
      ('<small><small>©</small></small>', .49),
      ('> <small><small>©</small></small>', .343),
    ]) {
      testWidgets('painted alpha $state ${entry.$1}', (tester) async {
        const pixels = Key('pixels');
        final provider = _ControlledImage();
        final helper = MfmTwemojiBuilder(
          imageProvider: (_) => state == 'null' ? null : provider,
        );
        final paint = Paint()..color = const Color(0x80ff0000);
        final background = Paint()..color = Colors.transparent;
        final style = _style.copyWith(
          // Large strokes have fully covered pixels even after nested small.
          // This probe measures composited opacity, not glyph antialiasing.
          fontSize: 100,
          foreground: paint,
          background: background,
        );
        MfmEmojiContext? received;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: pixels,
                child: MfmText(
                  text: entry.$1,
                  config: MfmRenderConfig(
                    baseTextStyle: style,
                    lightColorScheme: const MfmColorScheme.light(
                      fg: Color(0x80ff0000),
                    ),
                    unicodeEmojiBuilder: (emoji, context) {
                      received = context;
                      return helper.build(emoji, context);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        if (state == 'success') await tester.runAsync(provider.succeed);
        if (state == 'error') provider.fail();
        await tester.pump();
        await tester.pump();
        final fallback = state == 'error' || state == 'null';
        Offset point;
        Rect? glyphBounds;
        if (fallback) {
          final text = tester.widget<Text>(find.text('©'));
          expect(text.style, received!.textStyle);
          expect(text.style!.foreground, same(paint));
          expect(text.style!.background, same(background));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text('©'),
              matching: find.byType(RichText),
            ),
          );
          final glyph = paragraph
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .first;
          point = paragraph.localToGlobal(glyph.toRect().center);
          glyphBounds = glyph.toRect().shift(
            paragraph.localToGlobal(Offset.zero),
          );
        } else {
          point = tester.getCenter(find.byType(Image));
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(pixels),
        );
        final local = boundary.globalToLocal(point);
        final rgba = (await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawStraightRgba,
            );
            if (glyphBounds != null) {
              // A glyph's center can be empty (© in browser fallback fonts).
              // Sample its most covered pixel, not adjacent quote decoration.
              final region = glyphBounds.shift(
                -boundary.localToGlobal(Offset.zero),
              );
              final data = bytes!.buffer.asUint8List(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              );
              var strongest = <int>[0, 0, 0, 0];
              for (var y = region.top.floor(); y < region.bottom.ceil(); y++) {
                for (
                  var x = region.left.floor();
                  x < region.right.ceil();
                  x++
                ) {
                  if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
                    continue;
                  }
                  final offset = (y * image.width + x) * 4;
                  if (data[offset + 3] > strongest[3]) {
                    strongest = data.sublist(offset, offset + 4);
                  }
                }
              }
              return strongest;
            }
            final offset =
                (local.dy.floor() * image.width + local.dx.floor()) * 4;
            return bytes!.buffer
                .asUint8List(bytes.offsetInBytes + offset, 4)
                .toList();
          } finally {
            image.dispose();
          }
        }))!;
        final alpha = state == 'pending'
            ? 0
            : (fallback ? 128 : 255) * entry.$2;
        expect(rgba[3], closeTo(alpha, 2));
        if (fallback) expect(rgba.take(3), [255, 0, 0]);
        if (state == 'success') {
          for (var channel = 0; channel < 3; channel++) {
            expect(rgba[channel], closeTo([76, 175, 80][channel], 2));
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final plain in [false, true]) {
    for (final nowrap in [false, true]) {
      testWidgets('narrow RTL fallback plain=$plain nowrap=$nowrap', (
        tester,
      ) async {
        final helper = MfmTwemojiBuilder(imageProvider: (_) => null);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox(
                width: 45,
                child: MfmText(
                  text: '© © © ©',
                  plain: plain,
                  nowrap: nowrap,
                  config: MfmRenderConfig(
                    baseTextStyle: _style,
                    unicodeEmojiBuilder: helper.build,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('©'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('default native, inherited helper, copyWith and custom coexist', (
    tester,
  ) async {
    var calls = 0;
    final helper = MfmTwemojiBuilder(
      imageProvider: (_) {
        calls++;
        return null;
      },
    );
    await tester.pumpWidget(const MaterialApp(home: MfmText(text: '😀')));
    expect(calls, 0);
    expect(find.byType(Image), findsNothing);
    expect(
      find.text('😀'),
      findsNothing,
    ); // Native TextSpan, not fallback Text.
    final config = MfmRenderConfig(
      unicodeEmojiBuilder: helper.build,
      emojiBuilder: (name, context) => Text('custom:$name'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MfmConfig(
          config: config.copyWith(
            enableAnimation: false,
            unicodeEmojiBuilder: null,
          ),
          child: const MfmText(
            text: '😀 :wave:',
            config: MfmRenderConfig(unicodeEmojiBuilder: null),
          ),
        ),
      ),
    );
    expect(calls, 1);
    expect(find.text('😀'), findsOneWidget);
    expect(find.text('custom:wave'), findsOneWidget);
  });

  testWidgets('parser boundary: symbol, detached FE0E and abbreviated ZWJ', (
    tester,
  ) async {
    final inputs = <String>[];
    final names = <String>[];
    final helper = MfmTwemojiBuilder(
      imageProvider: (name) {
        names.add(name);
        return null;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MfmText(
          text: '© ❤︎ 🏳‍🌈 😀‍😀',
          config: MfmRenderConfig(
            unicodeEmojiBuilder: (emoji, context) {
              inputs.add(emoji);
              return helper.build(emoji, context);
            },
          ),
        ),
      ),
    );
    expect(inputs, ['©', '❤', '🏳‍🌈', '😀', '😀']);
    expect(names, [
      'a9.png',
      '2764.png',
      '1f3f3-200d-1f308.png',
      '1f600.png',
      '1f600.png',
    ]);
    // FE0E is outside the builder input; the helper cannot enforce presentation
    // across node boundaries. Abbreviated ZWJ is not repaired to an asset name.
    expect(tester.takeException(), isNull);
  });
}
