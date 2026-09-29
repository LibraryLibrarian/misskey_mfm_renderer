import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _style = TextStyle(fontFamily: 'Ahem', fontSize: 20, color: Colors.red);
const _custom = Key('custom');

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: DefaultTextStyle(
      style: _style,
      child: Center(
        child: Baseline(
          baseline: 100,
          baselineType: TextBaseline.alphabetic,
          child: child,
        ),
      ),
    ),
  ),
);

Future<Completer<ImageInfo>> _cachedImage(String url, int height) async {
  final provider = ResizeImage.resizeIfNeeded(
    null,
    height,
    CachedNetworkImageProvider(url),
  );
  final key = await provider.obtainKey(ImageConfiguration.empty);
  final result = Completer<ImageInfo>();
  PaintingBinding.instance.imageCache.putIfAbsent(
    key,
    () => OneFrameImageStreamCompleter(result.future),
  );
  return result;
}

void _expectNaturalBaseline(WidgetTester tester, String text) {
  final emoji = tester.renderObject<RenderBox>(find.byType(MfmCustomEmoji));
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  expect(emoji.size, paragraph.size);
  expect(
    emoji.getDryBaseline(emoji.constraints, TextBaseline.alphabetic),
    paragraph.getDryBaseline(paragraph.constraints, TextBaseline.alphabetic),
  );
}

void _expectImageBaseline(WidgetTester tester, Size size, double offset) {
  final box = tester.renderObject<RenderBox>(find.byType(MfmCustomEmoji));
  expect(box.size, size);
  expect(
    box.getDryBaseline(box.constraints, TextBaseline.alphabetic),
    size.height - offset,
  );
  final baseline = tester.getTopLeft(find.byType(Baseline)).dy + 100;
  expect(
    tester.getBottomLeft(find.byType(MfmCustomEmoji)).dy - baseline,
    offset,
  );
}

void main() {
  setUp(() {
    MfmCustomEmoji.debugClearCaches();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  for (final error in [false, true]) {
    testWidgets(
      'standalone ${error ? 'resolver error' : 'missing'} '
      'uses ambient natural 1em',
      (tester) async {
        await tester.pumpWidget(
          _host(
            MfmCustomEmoji(
              name: 'missing',
              size: 80,
              baselineOffset: 35,
              maxWidth: 5,
              resolver: (_) async {
                if (error) throw StateError('failed');
                return null;
              },
            ),
          ),
        );
        await tester.pump();
        expect(tester.widget<Text>(find.text(':missing:')).style, _style);
        _expectNaturalBaseline(tester, ':missing:');
      },
    );
  }

  for (final direct in [false, true]) {
    testWidgets(
      'image error (direct=$direct) escapes constraints; style keeps resolver',
      (tester) async {
        const url = 'https://fixture.test/decode-error.png';
        final image = await _cachedImage(url, 80);
        var calls = 0;
        Future<EmojiImage?> resolver(String _) async {
          calls++;
          return EmojiImage(
            url: Uri.parse(url),
            animated: false,
            isSensitive: false,
          );
        }

        Widget build(TextStyle style, {bool customError = false}) => _host(
          MfmCustomEmoji(
            name: 'missing',
            resolver: resolver,
            url: direct ? Uri.parse(url) : null,
            size: 80,
            maxWidth: 5,
            baselineOffset: 35,
            fallbackTextStyle: style,
            errorBuilder: customError
                ? (_, _, _) => const SizedBox(width: 30, height: 40)
                : null,
          ),
        );
        await tester.pumpWidget(build(_style));
        await tester.pump();
        image.completeError(StateError('invalid image bytes'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(CachedNetworkImage), findsOneWidget);
        expect(find.text(':missing:'), findsOneWidget);
        _expectNaturalBaseline(tester, ':missing:');
        expect(tester.getSize(find.text(':missing:')).height, 20);
        expect(tester.getSize(find.text(':missing:')).width, greaterThan(5));
        final nextStyle = _style.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        );
        await tester.pumpWidget(build(nextStyle));
        await tester.pump();
        expect(calls, direct ? 0 : 1);
        expect(tester.widget<Text>(find.text(':missing:')).style, nextStyle);
        _expectNaturalBaseline(tester, ':missing:');
        expect(tester.getSize(find.text(':missing:')).height, 30);
        await tester.pumpWidget(build(nextStyle, customError: true));
        _expectImageBaseline(tester, const Size(5, 40), 35);
        await tester.pumpWidget(build(nextStyle));
        _expectNaturalBaseline(tester, ':missing:');
        expect(tester.getSize(find.text(':missing:')).height, 30);
        expect(calls, direct ? 0 : 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final branch in [
    'missing',
    'resolver error',
    'resolver fallback',
    'image error',
    'image fallback',
    'loading',
    'image loading',
  ]) {
    testWidgets('custom $branch applies image baseline once', (tester) async {
      const url = 'https://fixture.test/custom.png';
      final network = branch.startsWith('image')
          ? await _cachedImage(url, 40)
          : null;
      final pending = Completer<EmojiImage?>();
      final isLoading = branch.endsWith('loading');
      const custom = SizedBox(key: _custom, width: 30, height: 40);
      await tester.pumpWidget(
        _host(
          MfmCustomEmoji(
            name: 'custom',
            size: 40,
            baselineOffset: 9,
            maxWidth: 50,
            url: network == null ? null : Uri.parse(url),
            resolver: network != null
                ? null
                : (_) async {
                    if (isLoading) return pending.future;
                    if (branch.startsWith('resolver')) {
                      throw StateError('failed');
                    }
                    return null;
                  },
            fallbackBuilder: (_, _) => custom,
            errorBuilder: branch.endsWith('error') ? (_, _, _) => custom : null,
            loadingBuilder: isLoading ? (_) => custom : null,
          ),
        ),
      );
      await tester.pump();
      if (network != null && !isLoading) {
        network.completeError(StateError('image failed'));
        await tester.pump();
        await tester.pump();
      }
      expect(find.byKey(_custom), findsOneWidget);
      _expectImageBaseline(tester, const Size(30, 40), 9);
      final customBox = tester.renderObject<RenderBox>(find.byKey(_custom));
      expect(customBox.size, const Size(30, 40));
      expect(tester.takeException(), isNull);
    });
  }

  for (final placeholderHeight in [12.0, 80.0]) {
    testWidgets(
      'whole transition baseline with $placeholderHeight-pixel placeholder',
      (tester) async {
        const url = 'https://fixture.test/transition.png';
        final image = await _cachedImage(url, 40);
        var calls = 0;
        Future<EmojiImage?> resolver(String _) async {
          calls++;
          return EmojiImage(
            url: Uri.parse(url),
            animated: false,
            isSensitive: false,
          );
        }

        await tester.pumpWidget(
          _host(
            MfmCustomEmoji(
              name: 'transition',
              resolver: resolver,
              size: 40,
              baselineOffset: 9,
              loadingBuilder: (_) => SizedBox(
                key: _custom,
                width: 12,
                height: placeholderHeight,
              ),
            ),
          ),
        );
        _expectImageBaseline(tester, Size(12, placeholderHeight), 9);
        await tester.pump();
        _expectImageBaseline(tester, Size(12, placeholderHeight), 9);
        final decoded = (await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawRect(
            const Rect.fromLTWH(0, 0, 40, 40),
            Paint()..color = Colors.red,
          );
          final picture = recorder.endRecording();
          try {
            return await picture.toImage(40, 40);
          } finally {
            picture.dispose();
          }
        }))!;
        image.complete(ImageInfo(image: decoded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(_custom), findsOneWidget);
        _expectImageBaseline(
          tester,
          Size(40, placeholderHeight > 40 ? placeholderHeight : 40),
          9,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(_custom), findsNothing);
        _expectImageBaseline(tester, const Size(40, 40), 9);
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final maxWidth in [null, 60.0]) {
    testWidgets(
      'decoded image and loading preserve geometry (maxWidth=$maxWidth)',
      (tester) async {
        const url = 'https://fixture.test/wide.png';
        final image = await _cachedImage(url, 40);
        await tester.pumpWidget(
          _host(
            MfmCustomEmoji(
              name: 'wide',
              url: Uri.parse(url),
              size: 40,
              maxWidth: maxWidth,
              aspectRatio: 2,
              baselineOffset: 9,
            ),
          ),
        );
        await tester.pump();
        _expectImageBaseline(tester, Size(maxWidth ?? 80, 40), 9);
        final decoded = (await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawRect(
            const Rect.fromLTWH(0, 0, 80, 40),
            Paint()..color = Colors.red,
          );
          final picture = recorder.endRecording();
          try {
            return await picture.toImage(80, 40);
          } finally {
            picture.dispose();
          }
        }))!;
        image.complete(ImageInfo(image: decoded));
        await tester.pumpAndSettle();
        _expectImageBaseline(tester, Size(maxWidth ?? 80, 40), 9);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
