import 'dart:async';

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

class TestRefreshNotifier extends ChangeNotifier {
  bool get hasRegisteredListeners => hasListeners;

  void notify() => notifyListeners();
}

void main() {
  group('MfmCustomEmoji', () {
    setUp(MfmCustomEmoji.debugClearCaches);

    testWidgets('解決成功時に画像ウィジェットを表示する', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // 幅が未知の間は0幅のプレースホルダのみを表示
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // resolve完了後に画像ウィジェットが構築される
      await tester.pump(const Duration(milliseconds: 1));

      expect(resolver.lastRequested, 'test');
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://example.com/emoji.png');
      expect(image.width, isNull);
      expect(image.height, 32.0);
      expect(image.fit, BoxFit.contain);
      expect(image.memCacheWidth, isNull);
      expect(image.memCacheHeight, 64);
      expect(image.imageBuilder, isNull);
    });

    testWidgets('最大幅を指定した場合のみ画像の幅を制約する', (tester) async {
      final resolver = MockEmojiResolver({
        'wide': EmojiImage(
          url: Uri.parse('https://example.com/wide.png'),
          animated: false,
          isSensitive: false,
        ),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'wide',
              resolver: resolver.call,
              maxWidth: 70,
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.width, isNull);
      expect(image.height, 24);

      final widthConstraint = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 70,
      );
      expect(widthConstraint, findsOneWidget);
    });

    testWidgets('未知の絵文字の読み込み中は正方形の幅を確保しない', (tester) async {
      final pending = Completer<EmojiImage?>();
      Future<EmojiImage?> resolver(String _) => pending.future;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'unknown-size',
              resolver: resolver,
            ),
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 0 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('未知の絵文字は最大幅を推定幅として使用しない', (tester) async {
      final pending = Completer<EmojiImage?>();
      Future<EmojiImage?> resolver(String _) => pending.future;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'unknown-size-limited',
              resolver: resolver,
              maxWidth: 70,
            ),
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 0 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('幅が未知でもカスタムローディング表示は使用する', (tester) async {
      final pending = Completer<EmojiImage?>();
      Future<EmojiImage?> resolver(String _) => pending.future;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'custom-loading',
              resolver: resolver,
              loadingBuilder: (_) => const Icon(
                Icons.hourglass_empty,
                key: Key('custom-loading'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom-loading')), findsOneWidget);
    });

    testWidgets('既知のアスペクト比を初回の読み込み表示に反映する', (tester) async {
      final pending = Completer<EmojiImage?>();
      Future<EmojiImage?> resolver(String _) => pending.future;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'known-size',
              resolver: resolver,
              aspectRatio: 4,
            ),
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 96 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('判明済みのアスペクト比をState再生成時に再利用する', (tester) async {
      final image = EmojiImage(
        url: Uri.parse('https://example.com/cached-ratio.png'),
        animated: false,
        isSensitive: false,
      );
      final pending = Completer<EmojiImage?>();
      var resolveCount = 0;
      Future<EmojiImage?> resolver(String _) {
        resolveCount++;
        return resolveCount == 1 ? Future.value(image) : pending.future;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'cached-ratio',
            resolver: resolver,
            aspectRatio: 4,
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'cached-ratio',
            resolver: resolver,
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 96 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
    });

    testWidgets('同じcacheScopeでは異なるresolverでも判明済み比率を再利用する', (
      tester,
    ) async {
      final scope = Object();
      final image = EmojiImage(
        url: Uri.parse('https://example.com/scoped-ratio.png'),
        animated: false,
        isSensitive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'scoped-ratio',
              resolver: (_) async => image,
              aspectRatio: 4,
              cacheScope: scope,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      final pending = Completer<EmojiImage?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'scoped-ratio',
              resolver: (_) => pending.future,
              cacheScope: scope,
            ),
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 96 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
    });

    testWidgets('異なるcacheScopeでは同名絵文字の比率を共有しない', (tester) async {
      final image = EmojiImage(
        url: Uri.parse('https://example.com/isolated-ratio.png'),
        animated: false,
        isSensitive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'isolated-ratio',
              resolver: (_) async => image,
              aspectRatio: 4,
              cacheScope: Object(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      final pending = Completer<EmojiImage?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'isolated-ratio',
              resolver: (_) => pending.future,
              cacheScope: Object(),
            ),
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 0 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
    });

    testWidgets('debugClearCachesで判明済み比率を破棄する', (tester) async {
      final scope = Object();
      final image = EmojiImage(
        url: Uri.parse('https://example.com/cleared-ratio.png'),
        animated: false,
        isSensitive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'cleared-ratio',
              resolver: (_) async => image,
              aspectRatio: 4,
              cacheScope: scope,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      MfmCustomEmoji.debugClearCaches();

      final pending = Completer<EmojiImage?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'cleared-ratio',
              resolver: (_) => pending.future,
              cacheScope: scope,
            ),
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 0 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
    });

    testWidgets('同じcacheScopeでもresolverクロージャが変われば再解決する', (
      tester,
    ) async {
      final scope = Object();
      var resolveCount = 0;
      Widget buildApp(String preferredHost) => MaterialApp(
        home: Scaffold(
          body: MfmCustomEmoji(
            name: 'scoped-host',
            resolver: (_) async {
              resolveCount++;
              return EmojiImage(
                url: Uri.parse('https://$preferredHost/emoji.png'),
                animated: false,
                isSensitive: false,
              );
            },
            cacheScope: scope,
          ),
        ),
      );

      await tester.pumpWidget(buildApp('first.example.com'));
      await tester.pump();
      expect(resolveCount, 1);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://first.example.com/emoji.png',
      );

      await tester.pumpWidget(buildApp('second.example.com'));
      await tester.pump();
      expect(resolveCount, 2);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://second.example.com/emoji.png',
      );
    });

    testWidgets('cacheScopeが変わった場合は同じ絵文字を再解決する', (tester) async {
      var resolveCount = 0;
      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        return EmojiImage(
          url: Uri.parse('https://example.com/scope-changed.png'),
          animated: false,
          isSensitive: false,
        );
      }

      Widget buildApp(Object scope) => MaterialApp(
        home: Scaffold(
          body: MfmCustomEmoji(
            name: 'scope-changed',
            resolver: resolver,
            cacheScope: scope,
          ),
        ),
      );

      await tester.pumpWidget(buildApp(Object()));
      await tester.pump();
      expect(resolveCount, 1);

      await tester.pumpWidget(buildApp(Object()));
      await tester.pump();
      expect(resolveCount, 2);
    });

    testWidgets('親が再ビルドされても同じ絵文字を再解決しない', (tester) async {
      var resolveCount = 0;
      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        return EmojiImage(
          url: Uri.parse('https://example.com/stable.png'),
          animated: false,
          isSensitive: false,
        );
      }

      Widget buildApp(ThemeMode themeMode) => MaterialApp(
        themeMode: themeMode,
        home: Scaffold(
          body: MfmCustomEmoji(name: 'stable', resolver: resolver),
        ),
      );

      await tester.pumpWidget(buildApp(ThemeMode.light));
      await tester.pump();
      expect(resolveCount, 1);

      await tester.pumpWidget(buildApp(ThemeMode.dark));
      await tester.pump();
      expect(resolveCount, 1);
    });

    testWidgets('未解決の絵文字は親の更新時に再試行する', (tester) async {
      var resolveCount = 0;
      var available = false;

      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        if (!available) {
          return null;
        }
        return EmojiImage(
          url: Uri.parse('https://example.com/retried.png'),
          animated: false,
          isSensitive: false,
        );
      }

      Widget buildApp(ThemeMode themeMode) => MaterialApp(
        themeMode: themeMode,
        home: Scaffold(
          body: MfmCustomEmoji(name: 'retry', resolver: resolver),
        ),
      );

      await tester.pumpWidget(buildApp(ThemeMode.light));
      await tester.pump();
      expect(resolveCount, 1);
      expect(find.text(':retry:'), findsOneWidget);

      available = true;
      await tester.pumpWidget(buildApp(ThemeMode.dark));
      await tester.pump();

      expect(resolveCount, 2);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('更新通知を受けると同じ絵文字を再解決する', (tester) async {
      final refreshNotifier = ValueNotifier(0);
      addTearDown(refreshNotifier.dispose);
      var resolveCount = 0;
      var available = false;

      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        if (!available) {
          return null;
        }
        return EmojiImage(
          url: Uri.parse('https://example.com/refreshed.png'),
          animated: false,
          isSensitive: false,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MfmCustomEmoji(
              name: 'refreshable',
              resolver: resolver,
              refreshListenable: refreshNotifier,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(resolveCount, 1);
      expect(find.text(':refreshable:'), findsOneWidget);

      available = true;
      refreshNotifier.value++;
      await tester.pump();
      await tester.pump();

      expect(resolveCount, 2);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://example.com/refreshed.png');
    });

    testWidgets('更新通知元の変更時にリスナーを付け替える', (tester) async {
      final oldNotifier = TestRefreshNotifier();
      final newNotifier = TestRefreshNotifier();
      addTearDown(oldNotifier.dispose);
      addTearDown(newNotifier.dispose);
      var resolveCount = 0;

      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        return EmojiImage(
          url: Uri.parse('https://example.com/listener.png'),
          animated: false,
          isSensitive: false,
        );
      }

      Widget buildApp(TestRefreshNotifier notifier) => MaterialApp(
        home: Scaffold(
          body: MfmCustomEmoji(
            name: 'replace-listener',
            resolver: resolver,
            refreshListenable: notifier,
          ),
        ),
      );

      await tester.pumpWidget(buildApp(oldNotifier));
      await tester.pump();
      expect(resolveCount, 1);
      expect(oldNotifier.hasRegisteredListeners, isTrue);

      await tester.pumpWidget(buildApp(newNotifier));
      await tester.pump();
      expect(oldNotifier.hasRegisteredListeners, isFalse);
      expect(newNotifier.hasRegisteredListeners, isTrue);

      oldNotifier.notify();
      await tester.pump();
      expect(resolveCount, 1);

      newNotifier.notify();
      await tester.pump();
      expect(resolveCount, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(newNotifier.hasRegisteredListeners, isFalse);
    });

    testWidgets('絵文字名が変わった場合は新しい絵文字を解決する', (tester) async {
      final requestedNames = <String>[];
      Future<EmojiImage?> resolver(String name) async {
        requestedNames.add(name);
        return null;
      }

      Widget buildApp(String name) => MaterialApp(
        home: Scaffold(
          body: MfmCustomEmoji(name: name, resolver: resolver),
        ),
      );

      await tester.pumpWidget(buildApp('first'));
      await tester.pump();

      await tester.pumpWidget(buildApp('second'));
      await tester.pump();

      expect(requestedNames, ['first', 'second']);
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
