import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MockEmojiResolver {
  MockEmojiResolver(
    this.responses, {
    this.delay = Duration.zero,
    this.error,
  });

  final Map<String, EmojiImage?> responses;
  final Duration delay;
  final Exception? error;

  String? lastRequested;

  Future<EmojiImage?> call(String shortcodeOrColonWrapped) async {
    lastRequested = shortcodeOrColonWrapped;
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) {
      throw error!;
    }
    return responses[shortcodeOrColonWrapped];
  }
}

void main() {
  group('MfmCustomEmoji', () {
    testWidgets('解決成功時に画像ウィジェットを表示する', (tester) async {
      final resolver = MockEmojiResolver(
        {
          'test': EmojiImage(
            url: Uri.parse('https://example.com/emoji.png'),
            animated: false,
            isSensitive: false,
          ),
        },
        delay: const Duration(milliseconds: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'test',
              resolver: resolver.call,
              size: 32,
            ),
          ),
        ),
      );

      // 初回はローディング表示
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // resolve完了後に画像ウィジェットが構築される
      await tester.pump(const Duration(milliseconds: 1));

      expect(resolver.lastRequested, 'test');
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://example.com/emoji.png');
      expect(image.width, 32.0);
      expect(image.height, 32.0);
    });

    testWidgets('絵文字が見つからない場合はフォールバック表示する', (tester) async {
      final resolver = MockEmojiResolver({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'notfound',
              resolver: resolver.call,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text(':notfound:'), findsOneWidget);
    });

    testWidgets('カスタムフォールバックビルダーが使用される', (tester) async {
      final resolver = MockEmojiResolver({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'custom',
              resolver: resolver.call,
              fallbackBuilder: (context, name) => Text(
                'CUSTOM:$name',
                key: const Key('custom-fallback'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('custom-fallback')), findsOneWidget);
    });

    testWidgets('解決時にエラーが発生した場合はエラービルダーが使用される', (tester) async {
      final resolver = MockEmojiResolver(
        {},
        error: Exception('resolve failed'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'error',
              resolver: resolver.call,
              errorBuilder: (context, name, error) => Text(
                'ERROR:$name',
                key: const Key('custom-error'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('custom-error')), findsOneWidget);
      expect(find.text('ERROR:error'), findsOneWidget);
    });
  });
}
