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

    for (final fontSize in [14.0, 28.0, 84.0]) {
      for (final fixedSize in [null, 24.0]) {
        testWidgets(
          'fontSize=$fontSize fixedSize=$fixedSizeで中心をbaseline+0.25emに揃える',
          (tester) async {
            final pending = Completer<EmojiImage?>();
            final config = MfmEmojiConfig.fromResolver(
              resolver: (_) => pending.future,
              emojiSize: fixedSize,
            ).copyWith(baseTextStyle: TextStyle(fontSize: fontSize));
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MfmText(text: ':emoji:', config: config),
                ),
              ),
            );

            final size = fixedSize ?? fontSize * 2;
            final descent = size / 2 - fontSize * 0.25;
            final placeholder = find.byWidgetPredicate(
              (widget) =>
                  widget is SizedBox &&
                  widget.width == 0 &&
                  widget.height == size,
            );
            final paragraph = tester.renderObject<RenderBox>(
              find.byType(RichText),
            );
            final baseline =
                tester.getTopLeft(find.byType(RichText)).dy +
                paragraph.getDryBaseline(
                  paragraph.constraints,
                  TextBaseline.alphabetic,
                )!;
            expect(
              tester.getBottomLeft(placeholder).dy - baseline,
              closeTo(descent, 1e-6),
            );
            final emojiBox = tester.renderObject<RenderBox>(
              find.byType(MfmCustomEmoji),
            );
            expect(emojiBox.size.height, size);
            expect(
              emojiBox.getDryBaseline(
                emojiBox.constraints,
                TextBaseline.alphabetic,
              ),
              closeTo(size - descent, 1e-6),
            );
            for (final type in [Transform, LayoutBuilder]) {
              expect(
                find.descendant(
                  of: find.byType(MfmCustomEmoji),
                  matching: find.byType(type),
                ),
                findsNothing,
              );
            }
          },
        );
      }
    }

    testWidgets('Unicode画像の下降量を更新しても高さと幅を変えない', (tester) async {
      final pending = Completer<EmojiImage?>();
      Future<EmojiImage?> resolver(String _) => pending.future;
      const boxKey = Key('unicode-image-box');
      for (final offset in [null, 3.5, 7.0, 0.0, null]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Baseline(
                baseline: 100,
                baselineType: TextBaseline.alphabetic,
                child: MfmText(
                  text: '😀',
                  config: MfmRenderConfig(
                    baseTextStyle: const TextStyle(fontSize: 14),
                    unicodeEmojiBuilder: (emoji, context) => MfmCustomEmoji(
                      name: emoji,
                      resolver: resolver,
                      size: context.fontSize * 1.25,
                      baselineOffset: offset,
                      loadingBuilder: (_) => const SizedBox(
                        key: boxKey,
                        width: 35,
                        height: 17.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final baseline = tester.getTopLeft(find.byType(Baseline)).dy + 100;
        expect(tester.getSize(find.byKey(boxKey)), const Size(35, 17.5));
        if (offset != null) {
          final box = tester.renderObject<RenderBox>(
            find.byType(MfmCustomEmoji),
          );
          expect(
            box.getDryBaseline(box.constraints, TextBaseline.alphabetic),
            17.5 - offset,
          );
        }
        // Paragraph metrics round the 17.5px placeholder's line height.
        // The reported baseline is exact; painting may differ by half a pixel.
        expect(
          tester.getBottomLeft(find.byKey(boxKey)).dy - baseline,
          closeTo(offset ?? 0, 0.500001),
        );
      }
    });

    testWidgets('サイズ文脈の更新で画像とデコード高さが追随し再解決しない', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      var resolveCount = 0;
      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        return EmojiImage(
          url: Uri.parse('https://example.com/context-sized.png'),
          animated: false,
          isSensitive: false,
        );
      }

      final config = MfmEmojiConfig.fromResolver(resolver: resolver).copyWith(
        baseTextStyle: const TextStyle(fontSize: 14),
      );
      for (final testCase in [
        (text: ':emoji:', height: 28.0),
        (text: r'$[x2 :emoji:]', height: 56.0),
        (text: r'$[x4 :emoji:]', height: 168.0),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(text: testCase.text, config: config),
            ),
          ),
        );
        await tester.pump();
        final image = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(image.height, testCase.height);
        expect(image.memCacheHeight, (testCase.height * 2).ceil());
        expect(image.memCacheWidth, isNull);
        expect(resolveCount, 1);
      }
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

    testWidgets('URL直指定時はresolverを呼ばない', (tester) async {
      var resolveCount = 0;
      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'direct',
            url: Uri.parse('https://cdn.example/direct.webp'),
            resolver: resolver,
          ),
        ),
      );
      await tester.pump();

      expect(resolveCount, 0);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://cdn.example/direct.webp',
      );
    });

    testWidgets('URLとresolverの両指定時はURLを優先する', (tester) async {
      var resolveCount = 0;
      Future<EmojiImage?> resolver(String _) async {
        resolveCount++;
        return EmojiImage(
          url: Uri.parse('https://resolver.example/emoji.webp'),
          animated: false,
          isSensitive: false,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'preferred',
            url: Uri.parse('https://cdn.example/preferred.webp'),
            resolver: resolver,
          ),
        ),
      );
      await tester.pump();

      expect(resolveCount, 0);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://cdn.example/preferred.webp',
      );
    });

    testWidgets('URLの更新時に再解決する', (tester) async {
      Widget buildApp(Uri url) => MaterialApp(
        home: MfmCustomEmoji(name: 'updated', url: url),
      );

      await tester.pumpWidget(
        buildApp(Uri.parse('https://cdn.example/first.webp')),
      );
      await tester.pump();
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://cdn.example/first.webp',
      );

      await tester.pumpWidget(
        buildApp(Uri.parse('https://cdn.example/second.webp')),
      );
      await tester.pump();
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://cdn.example/second.webp',
      );
    });

    testWidgets('直指定URLの画像エラーはshortcodeへフォールバックする', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'broken',
            url: Uri.parse('https://cdn.example/broken.webp'),
          ),
        ),
      );
      await tester.pump();
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: image.errorWidget!(
            tester.element(find.byType(CachedNetworkImage)),
            image.imageUrl,
            Exception('image failed'),
          ),
        ),
      );

      expect(find.text(':broken:'), findsOneWidget);
    });

    testWidgets('同名でもURLが異なればアスペクト比キャッシュを分離する', (
      tester,
    ) async {
      final scope = Object();
      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'same-name',
            url: Uri.parse('https://first.remote.example/emoji.webp'),
            cacheScope: scope,
            aspectRatio: 4,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.pumpWidget(
        MaterialApp(
          home: MfmCustomEmoji(
            name: 'same-name',
            url: Uri.parse('https://second.remote.example/emoji.webp'),
            cacheScope: scope,
          ),
        ),
      );

      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 0 && widget.height == 24,
      );
      expect(placeholder, findsOneWidget);
    });
  });
}
