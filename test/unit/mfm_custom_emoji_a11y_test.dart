import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _name = 'meaningful';
const _shortcode = ':$_name:';
const _size = 24.0;

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: DefaultTextStyle(
      style: const TextStyle(fontFamily: 'Ahem', fontSize: 20),
      child: Center(child: child),
    ),
  ),
);

// Seed the exact resized provider used by the widget, without HTTP or disk IO.
Future<Completer<ImageInfo>> _cachedImage(String url) async {
  final provider = ResizeImage.resizeIfNeeded(
    null,
    _size.toInt(),
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

Future<ui.Image> _decodeImage(WidgetTester tester) async =>
    (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 48, 24),
        Paint()..color = Colors.red,
      );
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(48, 24);
      } finally {
        picture.dispose();
      }
    }))!;

Future<void> _unmountAndClearImages(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  // Cache handles are released in post-frame callbacks. Clearing the cache
  // does not schedule a frame, so explicitly request one after unmounting.
  tester.binding.scheduleFrame();
  await tester.pump();
}

void _expectOneShortcodeLabel(WidgetTester tester) {
  final root = tester
      .renderObject(find.byType(MfmCustomEmoji))
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  var count = 0;
  void visit(SemanticsNode node) {
    count += RegExp(RegExp.escape(_shortcode)).allMatches(node.label).length;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  expect(
    count,
    1,
    reason:
        'The shortcode must be announced exactly once.\n'
        '${root.toStringDeep()}',
  );
}

void main() {
  setUp(() {
    MfmCustomEmoji.debugClearCaches();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  for (final invalidateBeforeDecode in [false, true]) {
    final phase = invalidateBeforeDecode
        ? 'cache generation changes'
        : 'normal decode';
    testWidgets(
      'aspect ratio observer releases ImageInfo after $phase',
      (tester) async {
        final url = 'https://fixture.test/observer-$invalidateBeforeDecode.png';
        final pending = await _cachedImage(url);
        await tester.pumpWidget(
          _host(MfmCustomEmoji(name: _name, url: Uri.parse(url))),
        );
        await tester.pump();
        expect(find.byType(CachedNetworkImage), findsOneWidget);
        expect(
          tester
              .widget<MfmCustomEmoji>(find.byType(MfmCustomEmoji))
              .aspectRatio,
          isNull,
        );
        if (invalidateBeforeDecode) {
          // The observer is already registered with the previous generation.
          MfmCustomEmoji.debugClearCaches();
        }

        final decoded = await _decodeImage(tester);
        // Ownership of this handle passes to the stream, as in a real decode.
        pending.complete(ImageInfo(image: decoded));
        await tester.pumpAndSettle();
        expect(find.byType(RawImage), findsOneWidget);
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
        expect(tester.takeException(), isNull);

        await _unmountAndClearImages(tester);
        final handles = decoded.debugGetOpenHandleStackTraces()!;
        final traces = handles
            .map((trace) => trace.toString().split('\n').take(6).join('\n'))
            .join('\n');
        expect(
          handles.length,
          0,
          reason:
              'All decoded image handles must be released after unmount '
              'and imageCache.clear/clearLiveImages. Remaining handles:\n'
              '$traces',
        );
      },
    );
  }

  testWidgets('supplied aspect ratio releases all decoded image handles', (
    tester,
  ) async {
    const url = 'https://fixture.test/known-aspect-ratio.png';
    final pending = await _cachedImage(url);
    await tester.pumpWidget(
      _host(MfmCustomEmoji(name: _name, url: Uri.parse(url), aspectRatio: 2)),
    );
    await tester.pump();
    final decoded = await _decodeImage(tester);
    pending.complete(ImageInfo(image: decoded));
    await tester.pumpAndSettle();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(tester.takeException(), isNull);
    await _unmountAndClearImages(tester);
    expect(decoded.debugGetOpenHandleStackTraces(), isEmpty);
  });

  for (final throughConfig in [false, true]) {
    final path = throughConfig ? 'MfmText fromResolver' : 'MfmCustomEmoji';
    for (final phase in [
      'resolver placeholder',
      'image placeholder',
      'decoded image',
      'default fallback',
    ]) {
      testWidgets('$path announces shortcode once during $phase', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        Completer<ImageInfo>? pendingImage;
        final pendingResolver = Completer<EmojiImage?>();
        try {
          final url =
              'https://fixture.test/a11y-$throughConfig-'
              '${phase.replaceAll(' ', '-')}.png';
          pendingImage =
              phase == 'image placeholder' || phase == 'decoded image'
              ? await _cachedImage(url)
              : null;
          Future<EmojiImage?> resolver(String name) async {
            expect(name, _name);
            if (phase == 'resolver placeholder') return pendingResolver.future;
            if (phase == 'default fallback') return null;
            return EmojiImage(
              url: Uri.parse(url),
              animated: false,
              isSensitive: false,
            );
          }

          final child = throughConfig
              ? MfmText(
                  text: _shortcode,
                  config: MfmEmojiConfig.fromResolver(
                    resolver: resolver,
                    emojiSize: _size,
                  ),
                )
              // A standalone placeholder with an unknown ratio has zero width,
              // and Flutter does not expose empty semantics rects. Inside
              // MfmText the paragraph still carries the label.
              : MfmCustomEmoji(
                  name: _name,
                  resolver: resolver,
                  aspectRatio: 2,
                );
          await tester.pumpWidget(_host(child));
          await tester.pump();
          expect(find.byType(MfmCustomEmoji), findsOneWidget);

          if (phase == 'decoded image') {
            final decoded = await _decodeImage(tester);
            pendingImage!.complete(ImageInfo(image: decoded));
            await tester.pumpAndSettle();
            expect(find.byType(RawImage), findsOneWidget);
            expect(
              tester.widget<RawImage>(find.byType(RawImage)).image,
              isNotNull,
            );
          } else if (phase == 'image placeholder') {
            expect(find.byType(CachedNetworkImage), findsOneWidget);
            expect(find.byType(RawImage), findsNothing);
            expect(pendingImage!.isCompleted, isFalse);
          } else if (phase == 'resolver placeholder') {
            expect(find.byType(CachedNetworkImage), findsNothing);
            expect(pendingResolver.isCompleted, isFalse);
          } else {
            expect(find.text(_shortcode), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          _expectOneShortcodeLabel(tester);
        } finally {
          semantics.dispose();
          // Finish pending fixture requests so observer listeners can detach.
          if (!pendingResolver.isCompleted) pendingResolver.complete();
          if (pendingImage != null && !pendingImage.isCompleted) {
            pendingImage.completeError(StateError('Placeholder test finished'));
            await tester.pump();
          }
          await _unmountAndClearImages(tester);
        }
      });
    }
  }

  for (final phase in ['placeholder', 'decoded image', 'default fallback']) {
    testWidgets('semanticLabel replaces the shortcode during $phase', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final pendingResolver = Completer<EmojiImage?>();
      const url = 'https://fixture.test/a11y-custom-label.png';
      final pendingImage = phase == 'decoded image'
          ? await _cachedImage(url)
          : null;
      try {
        await tester.pumpWidget(
          _host(
            MfmCustomEmoji(
              name: _name,
              aspectRatio: 2,
              semanticLabel: 'Party parrot',
              resolver: (_) async => switch (phase) {
                'placeholder' => pendingResolver.future,
                'default fallback' => null,
                _ => EmojiImage(
                  url: Uri.parse(url),
                  animated: false,
                  isSensitive: false,
                ),
              },
            ),
          ),
        );
        await tester.pump();
        if (pendingImage != null) {
          pendingImage.complete(ImageInfo(image: await _decodeImage(tester)));
          await tester.pumpAndSettle();
          expect(find.byType(RawImage), findsOneWidget);
        }
        expect(find.bySemanticsLabel('Party parrot'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(_shortcode)), findsNothing);
      } finally {
        semantics.dispose();
        if (!pendingResolver.isCompleted) pendingResolver.complete();
        await _unmountAndClearImages(tester);
      }
    });
  }

  for (final builder in ['loading', 'fallback', 'error']) {
    testWidgets('$builder builder keeps its own semantics and actions', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final pendingResolver = Completer<EmojiImage?>();
      var taps = 0;
      Widget button(BuildContext _, [Object? _, Object? _]) => Semantics(
        button: true,
        label: 'Retry',
        onTap: () => taps++,
        child: const SizedBox(width: 24, height: 24),
      );
      try {
        await tester.pumpWidget(
          _host(
            MfmCustomEmoji(
              name: _name,
              resolver: (_) => switch (builder) {
                'loading' => pendingResolver.future,
                'fallback' => Future.value(),
                _ => Future.error(StateError('resolver failed')),
              },
              loadingBuilder: builder == 'loading' ? button : null,
              fallbackBuilder: builder == 'fallback' ? button : null,
              errorBuilder: builder == 'error' ? button : null,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final retry = find.bySemanticsLabel('Retry');
        expect(retry, findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(_shortcode)), findsNothing);
        tester.semantics.tap(find.semantics.byLabel('Retry'));
        expect(taps, 1);
      } finally {
        semantics.dispose();
        if (!pendingResolver.isCompleted) pendingResolver.complete();
        await _unmountAndClearImages(tester);
      }
    });
  }
}
