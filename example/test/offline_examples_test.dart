import 'dart:io';

import 'package:example/core/emoji/offline_example_fixtures.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class _NoNetwork extends HttpOverrides {
  int clients = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clients++;
    throw StateError('Offline examples must not create an HTTP client');
  }
}

MfmExample _example(String name) => MfmExamples.categories
    .expand((c) => c.examples)
    .singleWhere((e) => e.name == name);

Future<void> _pump(WidgetTester tester, String name) async {
  final example = _example(name);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MfmConfig(
          config: const MfmRenderConfig(
            baseTextStyle: TextStyle(
              fontFamily: 'Ahem',
              fontSize: 20,
              height: 1,
            ),
            author: MfmAuthorContext(host: 'remote.test'),
            emojiUrls: {'not_exist_emoji': 'https://fixture.invalid/emoji.png'},
          ),
          child: MfmText(text: example.mfm, config: example.config!),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _NoNetwork network;
  late HttpOverrides? previous;
  setUp(() {
    MfmCustomEmoji.debugClearCaches();
    previous = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    HttpOverrides.global = previous;
    expect(network.clients, 0);
  });

  testWidgets('missing emoji uses real 1em fallback with natural baseline', (
    tester,
  ) async {
    await _pump(tester, 'Custom Emoji (フォールバックの継承)');
    final emojis = find.byType(MfmCustomEmoji);
    expect(emojis, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final fallback = find.descendant(
        of: emojis.at(i),
        matching: find.text(':not_exist_emoji:'),
      );
      final text = tester.widget<Text>(fallback);
      expect(text.style!.fontSize, i == 0 ? 20 : 16);
      expect(
        text.style!.fontWeight,
        i == 0 ? isNot(FontWeight.bold) : FontWeight.bold,
      );
      final box = tester.renderObject<RenderBox>(emojis.at(i));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: fallback, matching: find.byType(RichText)),
      );
      expect(box.size, paragraph.size);
      expect(box.size.height, i == 0 ? 20 : 16);
      expect(
        box.getDryBaseline(box.constraints, TextBaseline.alphabetic),
        paragraph.getDryBaseline(
          paragraph.constraints,
          TextBaseline.alphabetic,
        ),
      );
      expect(tester.widget<MfmCustomEmoji>(emojis.at(i)).url, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('asset avatar decodes and missing avatar retains 1.5em slot', (
    tester,
  ) async {
    await _pump(tester, 'Mention Avatar (offline)');
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    final clips = find.byType(ClipOval);
    expect(clips, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      expect(tester.getSize(clips.at(i)), const Size(30, 30));
    }
    final context = tester.element(find.byType(MfmText));
    await tester.runAsync(() => precacheImage(image.image, context));
    await tester.pump();
    final decoded = tester.widget<RawImage>(find.byType(RawImage)).image;
    expect(decoded, isNotNull);
    expect(decoded!.width, 72);
    expect(decoded.height, 72);
    expect(
      find.descendant(of: clips.at(1), matching: find.byType(ColoredBox)),
      findsOneWidget,
    );
    for (var i = 0; i < 2; i++) {
      expect(tester.getSize(clips.at(i)), const Size(30, 30));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('capsule role colors and text presentation remain distinct', (
    tester,
  ) async {
    await _pump(tester, 'Mention Capsule');
    expect(find.byType(ClipOval), findsNWidgets(2));
    final colors = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((box) => box.color);
    const scheme = MfmColorScheme.light();
    expect(colors, contains(scheme.mentionMe.withValues(alpha: .2)));
    expect(colors, contains(scheme.mention.withValues(alpha: .2)));
    await _pump(tester, 'Mention Text');
    expect(find.byType(ClipOval), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  test(
    'all overrides are documented and core snippets match runtime values',
    () {
      for (final example in MfmExamples.categories.expand((c) => c.examples)) {
        if (!example.hasOverrides) continue;
        expect(example.setupSummary, isNotEmpty, reason: example.name);
        expect(example.setupCode, isNotEmpty, reason: example.name);
        final config = example.config;
        if (config?.localHost != null) {
          expect(
            example.setupCode,
            contains("localHost: '${config!.localHost}'"),
          );
        }
        final options = config?.unixtimeOptions;
        if (options != null) {
          if (options.locale != null) {
            expect(
              example.setupCode,
              contains("Locale('${options.locale!.languageCode}')"),
            );
          }
          if (options.mode != MfmUnixtimeMode.detail) {
            expect(
              example.setupCode,
              contains('MfmUnixtimeMode.${options.mode.name}'),
            );
          }
          if (!options.autoUpdate) {
            expect(example.setupCode, contains('autoUpdate: false'));
            expect(options.formatter, mfmLegacyUnixtimeFormatter);
          }
        }
        if (example.plain != null) {
          expect(example.setupCode, contains('plain: ${example.plain}'));
        }
        if (example.nowrap != null) {
          expect(example.setupCode, contains('nowrap: ${example.nowrap}'));
        }
      }
      final avatar = _example('Mention Avatar (offline)');
      expect(
        avatar.config!.mentionOptions!.avatarProvider,
        offlineMentionAvatar,
      );
      expect(avatar.config!.mentionOptions!.localOrigin, isNull);
      expect(
        avatar.setupCode,
        contains('avatarProvider: offlineMentionAvatar'),
      );
      expect(avatar.description, contains('CC-BY 4.0'));
      expect(avatar.config!.mentionOptions!.viewerAcct, '@alice');
      expect(avatar.setupCode, contains("viewerAcct: '@alice'"));
      final fallback = _example('Custom Emoji (フォールバックの継承)');
      expect(fallback.config!.emojiBuilder, offlineMissingEmoji);
      expect(fallback.config!.author!.host, isNull);
      expect(fallback.setupCode, contains('emojiBuilder: offlineMissingEmoji'));
    },
  );
}
