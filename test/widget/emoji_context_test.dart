import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('MfmEmojiContext', () {
    test('value equality, hashCode and toString include both fields', () {
      const context = MfmEmojiContext(fontSize: 14, scale: 1);
      expect(context, const MfmEmojiContext(fontSize: 14, scale: 1));
      expect(
        context.hashCode,
        const MfmEmojiContext(fontSize: 14, scale: 1).hashCode,
      );
      expect(context, isNot(const MfmEmojiContext(fontSize: 28, scale: 1)));
      expect(context, isNot(const MfmEmojiContext(fontSize: 14, scale: 2)));
      expect(context, isNot('context'));
      expect(context.toString(), 'MfmEmojiContext(fontSize: 14.0, scale: 1.0)');
    });

    test('original size threshold depends only on scale', () {
      expect(
        const MfmEmojiContext(fontSize: 84, scale: 2.499).useOriginalSize,
        isFalse,
      );
      expect(
        const MfmEmojiContext(fontSize: 14, scale: 2.5).useOriginalSize,
        isTrue,
      );
    });

    test('copyWith preserves and replaces context-aware builders', () {
      Widget original(String name, MfmEmojiContext context) =>
          Text('$name:${context.fontSize}');
      Widget replacement(String name, MfmEmojiContext context) =>
          Text('$name:${context.scale}');
      final config = MfmRenderConfig(
        emojiBuilder: original,
        unicodeEmojiBuilder: original,
      );
      final preserved = config.copyWith(enableAnimation: false);
      expect(preserved.emojiBuilder, same(original));
      expect(preserved.unicodeEmojiBuilder, same(original));
      final replaced = preserved.copyWith(
        emojiBuilder: replacement,
        unicodeEmojiBuilder: replacement,
      );
      expect(replaced.emojiBuilder, same(replacement));
      expect(replaced.unicodeEmojiBuilder, same(replacement));
    });
  });

  for (final emoji in [':emoji:', '😀']) {
    group('$emoji rendering context', () {
      final cases = [
        (text: 'EMOJI', fontSize: 14.0, scale: 1.0),
        (text: r'$[x2 EMOJI]', fontSize: 28.0, scale: 2.0),
        (text: r'$[x3 EMOJI]', fontSize: 56.0, scale: 4.0),
        (text: r'$[x4 EMOJI]', fontSize: 84.0, scale: 6.0),
        // scale changes the paint transform, not the effective font size.
        (text: r'$[scale.x=3,y=3 EMOJI]', fontSize: 14.0, scale: 3.0),
        // 非等倍でも本家と同じくmax(x, y)を掛ける。
        (text: r'$[scale.x=3,y=1 EMOJI]', fontSize: 14.0, scale: 3.0),
        (text: r'$[scale.y=3 EMOJI]', fontSize: 14.0, scale: 3.0),
        (text: r'$[scale.x=3,y=3 $[x2 EMOJI]]', fontSize: 28.0, scale: 6.0),
        (text: r'$[tada EMOJI]', fontSize: 21.0, scale: 1.0),
        (text: r'$[x2 $[tada EMOJI]]', fontSize: 42.0, scale: 2.0),
        (text: '<small>EMOJI</small>', fontSize: 11.2, scale: 1.0),
      ];
      for (final testCase in cases) {
        testWidgets(testCase.text, (tester) async {
          final contexts = <MfmEmojiContext>[];
          Widget buildEmoji(String name, MfmEmojiContext context) {
            expect(name, emoji == ':emoji:' ? 'emoji' : emoji);
            contexts.add(context);
            return const SizedBox(width: 20, height: 20);
          }

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmText(
                  text: testCase.text.replaceAll('EMOJI', emoji),
                  config: MfmRenderConfig(
                    baseTextStyle: const TextStyle(fontSize: 14),
                    emojiBuilder: buildEmoji,
                    unicodeEmojiBuilder: buildEmoji,
                  ),
                ),
              ),
            ),
          );

          expect(contexts, hasLength(1));
          expect(contexts.single.fontSize, closeTo(testCase.fontSize, 1e-9));
          expect(contexts.single.scale, testCase.scale);
          expect(contexts.single.useOriginalSize, testCase.scale >= 2.5);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('aligns the widget span to the alphabetic baseline', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: emoji,
                config: MfmRenderConfig(
                  emojiBuilder: (_, _) => const SizedBox.square(dimension: 28),
                  unicodeEmojiBuilder: (_, _) =>
                      const SizedBox.square(dimension: 17.5),
                ),
              ),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText));
        final span = (richText.text as TextSpan).children!.single as WidgetSpan;
        expect(span.alignment, PlaceholderAlignment.baseline);
        expect(span.baseline, TextBaseline.alphabetic);
      });

      testWidgets(
        'inherits builders and merges explicit style without leaking',
        (tester) async {
          final contexts = <MfmEmojiContext>[];
          Widget buildEmoji(String _, MfmEmojiContext context) {
            contexts.add(context);
            return const SizedBox.square(dimension: 20);
          }

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MfmConfig(
                  config: MfmRenderConfig(
                    emojiBuilder: buildEmoji,
                    unicodeEmojiBuilder: buildEmoji,
                  ),
                  child: MfmText(
                    text: '\$[x2 $emoji] $emoji',
                    config: const MfmRenderConfig(
                      baseTextStyle: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(contexts, [
            const MfmEmojiContext(fontSize: 40, scale: 2),
            const MfmEmojiContext(fontSize: 20, scale: 1),
          ]);
        },
      );
    });
  }

  testWidgets('font size is completed before constructing emoji context', (
    tester,
  ) async {
    MfmEmojiContext? received;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MfmText(
            text: ':emoji:',
            config: MfmRenderConfig(
              baseTextStyle: const TextStyle(color: Colors.red),
              emojiBuilder: (_, context) {
                received = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    expect(received, const MfmEmojiContext(fontSize: 14, scale: 1));
  });
}
