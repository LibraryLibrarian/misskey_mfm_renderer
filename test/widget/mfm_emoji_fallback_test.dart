import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  for (final plain in [false, true]) {
    for (final size in [null, 80.0]) {
      testWidgets('missing emoji is 1em, plain=$plain size=$size', (
        tester,
      ) async {
        final config = MfmEmojiConfig.fromResolver(
          resolver: (_) async => null,
          emojiSize: size,
        ).copyWith(baseTextStyle: const TextStyle(fontSize: 20));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: 'a :missing: b',
                plain: plain,
                config: config,
              ),
            ),
          ),
        );
        await tester.pump();
        final text = tester.widget<Text>(find.text(':missing:'));
        expect(text.style?.fontSize, 20);
        final emoji = tester.renderObject<RenderBox>(
          find.byType(MfmCustomEmoji),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(':missing:'),
            matching: find.byType(RichText),
          ),
        );
        expect(emoji.size, paragraph.size);
        expect(
          emoji.getDryBaseline(emoji.constraints, TextBaseline.alphabetic),
          paragraph.getDryBaseline(
            paragraph.constraints,
            TextBaseline.alphabetic,
          ),
        );
      });
    }
  }
}
