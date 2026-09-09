import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('remote custom emoji context', () {
    testWidgets('local post ignores emojiUrls and passes no host or URL', (
      tester,
    ) async {
      MfmEmojiContext? received;
      await tester.pumpWidget(
        MaterialApp(
          home: MfmText(
            text: ':wave:',
            config: MfmRenderConfig(
              emojiUrls: const {'wave': 'https://cdn.example/wave.webp'},
              emojiBuilder: (_, context) {
                received = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(received?.host, isNull);
      expect(received?.url, isNull);
    });

    testWidgets('remote post passes the mapped direct URL', (tester) async {
      MfmEmojiContext? received;
      await tester.pumpWidget(
        MaterialApp(
          home: MfmText(
            text: ':wave:',
            config: MfmRenderConfig(
              author: const MfmAuthorContext(host: 'remote.example'),
              emojiUrls: const {'wave': 'https://cdn.example/wave.webp'},
              emojiBuilder: (_, context) {
                received = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(received?.host, 'remote.example');
      expect(received?.url, Uri.parse('https://cdn.example/wave.webp'));
    });

    testWidgets('remote post renders a literal when its map has no shortcode', (
      tester,
    ) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MfmText(
            text: ':wave:',
            config: MfmRenderConfig(
              author: const MfmAuthorContext(host: 'remote.example'),
              emojiUrls: const {'other': 'https://cdn.example/other.webp'},
              emojiBuilder: (_, _) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(buildCount, 0);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect((richText.text as TextSpan).toPlainText(), ':wave:');
    });

    testWidgets('remote post without a map passes its host and no URL', (
      tester,
    ) async {
      MfmEmojiContext? received;
      await tester.pumpWidget(
        MaterialApp(
          home: MfmText(
            text: ':wave:',
            config: MfmRenderConfig(
              author: const MfmAuthorContext(host: 'remote.example'),
              emojiBuilder: (_, context) {
                received = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(received?.host, 'remote.example');
      expect(received?.url, isNull);
    });

    testWidgets('an empty mapped URL is treated as no direct URL', (
      tester,
    ) async {
      MfmEmojiContext? received;
      await tester.pumpWidget(
        MaterialApp(
          home: MfmText(
            text: ':wave:',
            config: MfmRenderConfig(
              author: const MfmAuthorContext(host: 'remote.example'),
              emojiUrls: const {'wave': ''},
              emojiBuilder: (_, context) {
                received = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(received?.host, 'remote.example');
      expect(received?.url, isNull);
    });
  });
}
