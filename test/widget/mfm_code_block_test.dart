import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_code_block.dart';

void main() {
  const code = 'void main() {}';
  const source = '```dart\n$code\n```';
  final clipboardCalls = <MethodCall>[];
  Future<void>? clipboardCompletion;

  setUp(() {
    clipboardCalls.clear();
    clipboardCompletion = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
            await clipboardCompletion;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Container codeBlockContainer(WidgetTester tester) {
    final containers = find.descendant(
      of: find.byType(MfmCodeBlock),
      matching: find.byType(Container),
    );
    return tester.widget<Container>(containers.first);
  }

  BoxDecoration codeBlockDecoration(WidgetTester tester) {
    return codeBlockContainer(tester).decoration! as BoxDecoration;
  }

  testWidgets('ScaffoldMessengerなしでもコードをコピーできる', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: MfmText(text: source),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ScaffoldMessenger), findsNothing);
    expect(find.byType(Scaffold), findsNothing);
    expect(find.byType(Overlay), findsNothing);
    expect(find.bySemanticsLabel('Copy'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();

    expect(clipboardCalls.single.arguments, {'text': code});
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Materialのないツリーでもコピーボタンがタップできる', (tester) async {
    await tester.pumpWidget(
      Theme(
        // Material 2のIconButtonは祖先のMaterialを要求するため、
        // Material非依存であることを確認する。
        data: ThemeData(useMaterial3: false),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(),
            child: MfmText(text: source),
          ),
        ),
      ),
    );

    expect(find.byType(Material), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();

    expect(clipboardCalls.single.arguments, {'text': code});
    expect(tester.takeException(), isNull);
  });

  testWidgets('WidgetsApp配下でもコピーボタンがタップできる', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, child) => const MfmText(text: source),
      ),
    );

    expect(find.byType(Material), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();

    expect(clipboardCalls.single.arguments, {'text': code});
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CupertinoApp配下でもコピーボタンがタップできる', (tester) async {
    await tester.pumpWidget(const CupertinoApp(home: MfmText(text: source)));

    expect(find.byType(Material), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();

    expect(clipboardCalls.single.arguments, {'text': code});
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('コピーボタンはMaterial依存のIconButton/Tooltipを使わない', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MfmText(text: source)),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(MfmCodeBlock),
        matching: find.byType(IconButton),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(MfmCodeBlock),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );
  });

  testWidgets('ホバーでコピーボタンの不透明度が変わる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MfmText(text: source)),
      ),
    );

    final opacity = find.descendant(
      of: find.byType(MfmCodeBlock),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(opacity).opacity, 0.5);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byIcon(Icons.content_copy));
    await tester.sendEventToBinding(pointer.hover(Offset.zero));
    await tester.pump();
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.pump();
    expect(tester.widget<Opacity>(opacity).opacity, 0.8);

    await tester.sendEventToBinding(pointer.hover(Offset.zero));
    await tester.pump();
    expect(tester.widget<Opacity>(opacity).opacity, 0.5);
  });

  testWidgets('コピー完了後にコードを通知し既定のSnackBarを表示しない', (tester) async {
    final completion = Completer<void>();
    clipboardCompletion = completion.future;
    final copiedCodes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MfmText(
            text: source,
            config: MfmRenderConfig(onCodeCopied: copiedCodes.add),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pump();
    expect(clipboardCalls.single.arguments, {'text': code});
    expect(copiedCodes, isEmpty);

    completion.complete();
    await tester.pumpAndSettle();
    expect(copiedCodes, [code]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('コピー待機中に破棄されてもSnackBarを表示しない', (tester) async {
    final completion = Completer<void>();
    clipboardCompletion = completion.future;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MfmText(text: source)),
      ),
    );
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  for (final locale in ['ja', 'en', 'fr']) {
    testWidgets('$localeロケールでコピー文言を解決する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: Locale(locale),
                child: const MfmText(text: source),
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(locale == 'ja' ? 'コピー' : 'Copy'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.content_copy));
      await tester.pumpAndSettle();
      expect(
        find.text(locale == 'ja' ? 'コードをコピーしました' : 'Copied to clipboard'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('指定したアクセシビリティラベルとコピー完了メッセージを使用する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MfmText(
            text: source,
            config: MfmRenderConfig(
              codeCopyTooltip: 'Copy source',
              codeCopiedMessage: 'Source copied',
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Copy source'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();
    expect(find.text('Source copied'), findsOneWidget);
  });

  group('コードブロックのフォントサイズ継承', () {
    final cases = {
      'baseTextStyle': const MfmText(
        text: source,
        config: MfmRenderConfig(baseTextStyle: TextStyle(fontSize: 24)),
      ),
      'Inherited config': const MfmConfig(
        config: MfmRenderConfig(baseTextStyle: TextStyle(fontSize: 24)),
        child: MfmText(text: source),
      ),
      'DefaultTextStyle': const DefaultTextStyle(
        style: TextStyle(fontSize: 24),
        child: MfmText(text: source),
      ),
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key}のサイズをコード本文に反映する', (tester) async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: entry.value)));

        final highlight = tester.widget<HighlightView>(
          find.byType(HighlightView),
        );
        expect(highlight.textStyle?.fontSize, 24);
        expect(highlight.textStyle?.fontFamily, 'Consolas');
        expect(highlight.textStyle?.fontFamilyFallback, const [
          'Monaco',
          'Andale Mono',
          'Ubuntu Mono',
          'monospace',
        ]);
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.byType(HighlightView),
            matching: find.byType(RichText),
          ),
        );
        expect(richText.text.style?.fontSize, 24);
        expect(richText.text.style?.fontFamily, 'Consolas');
        expect(richText.text.style?.fontFamilyFallback, const [
          'Monaco',
          'Andale Mono',
          'Ubuntu Mono',
          'monospace',
        ]);
      });
    }

    testWidgets('サイズ未指定ならHighlightViewに固定サイズを渡さない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmCodeBlock(
              code: code,
              theme: {},
              colorScheme: MfmColorScheme.light(),
            ),
          ),
        ),
      );

      final highlight = tester.widget<HighlightView>(
        find.byType(HighlightView),
      );
      expect(highlight.textStyle?.fontSize, isNull);
      expect(highlight.textStyle?.fontFamily, 'Consolas');
      expect(highlight.textStyle?.fontFamilyFallback, const [
        'Monaco',
        'Andale Mono',
        'Ubuntu Mono',
        'monospace',
      ]);
    });
  });

  group('コードブロックの本家MkCode外観', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name}ではdividerの枠線、8px角丸、clipを使う', (
        tester,
      ) async {
        final colorScheme = brightness == Brightness.dark
            ? const MfmColorScheme.dark()
            : const MfmColorScheme.light();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: source,
                config: MfmRenderConfig(brightness: brightness),
              ),
            ),
          ),
        );

        final container = codeBlockContainer(tester);
        final decoration = codeBlockDecoration(tester);
        final border = decoration.border! as Border;
        expect(border.top.color, colorScheme.divider);
        expect(border.top.width, 1);
        expect(decoration.borderRadius, BorderRadius.circular(8));
        expect(container.clipBehavior, Clip.antiAlias);
      });
    }

    testWidgets('実効フォントサイズと同じ1emのpaddingを使う', (tester) async {
      for (final fontSize in [14.0, 24.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: source,
                config: MfmRenderConfig(
                  baseTextStyle: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
          ),
        );

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.padding, EdgeInsets.all(fontSize));
      }
    });

    testWidgets('言語なしでは選択中のschemeの背景色と文字色を使う', (tester) async {
      const lightScheme = MfmColorScheme.light(
        bg: Color(0xFF112233),
        fg: Color(0xFF445566),
      );
      const darkScheme = MfmColorScheme.dark(
        bg: Color(0xFF778899),
        fg: Color(0xFFAABBCC),
      );
      for (final entry in <Brightness, MfmColorScheme>{
        Brightness.light: lightScheme,
        Brightness.dark: darkScheme,
      }.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: '```\nplain code\n```',
                config: MfmRenderConfig(
                  brightness: entry.key,
                  lightColorScheme: lightScheme,
                  darkColorScheme: darkScheme,
                ),
              ),
            ),
          ),
        );

        final rootStyle = tester
            .widget<HighlightView>(find.byType(HighlightView))
            .theme['root']!;
        expect(codeBlockDecoration(tester).color, entry.value.bg);
        expect(rootStyle.backgroundColor, entry.value.bg);
        expect(rootStyle.color, entry.value.fg);
      }
    });

    testWidgets('言語付きではハイライトテーマrootの背景を維持する', (tester) async {
      const highlightBackground = Color(0xFF123456);
      const schemeBackground = Color(0xFF654321);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: source,
              config: MfmRenderConfig(
                brightness: Brightness.light,
                lightColorScheme: MfmColorScheme.light(bg: schemeBackground),
                codeTheme: {
                  'root': TextStyle(backgroundColor: highlightBackground),
                },
              ),
            ),
          ),
        ),
      );

      final rootStyle = tester
          .widget<HighlightView>(find.byType(HighlightView))
          .theme['root']!;
      expect(codeBlockDecoration(tester).color, highlightBackground);
      expect(rootStyle.backgroundColor, highlightBackground);
    });

    testWidgets('言語付きtheme rootに背景がない場合だけscheme背景へfallbackする', (tester) async {
      const foreground = Color(0xFF123456);
      const background = Color(0xFF654321);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: source,
              config: MfmRenderConfig(
                brightness: Brightness.light,
                lightColorScheme: MfmColorScheme.light(bg: background),
                codeTheme: {'root': TextStyle(color: foreground)},
              ),
            ),
          ),
        ),
      );

      final rootStyle = tester
          .widget<HighlightView>(find.byType(HighlightView))
          .theme['root']!;
      expect(codeBlockDecoration(tester).color, background);
      expect(rootStyle.backgroundColor, background);
      expect(rootStyle.color, foreground);
    });

    testWidgets('言語なしだけ上下0.5emのmarginを持つ', (tester) async {
      const fontSize = 24.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: '```\nplain code\n```',
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: fontSize),
              ),
            ),
          ),
        ),
      );
      expect(
        codeBlockContainer(tester).margin,
        const EdgeInsets.symmetric(vertical: fontSize * 0.5),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: source,
              config: MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: fontSize),
              ),
            ),
          ),
        ),
      );
      expect(codeBlockContainer(tester).margin, EdgeInsets.zero);
    });

    testWidgets('コピーボタンは8px insetを維持する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MfmText(text: source)),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.top, 8);
      expect(positioned.right, 8);
    });
  });

  testWidgets('同じコードブロックがロケール変更をコピー文言に反映する', (tester) async {
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<Locale>(
            valueListenable: locale,
            child: const MfmCodeBlock(
              code: code,
              theme: {},
              colorScheme: MfmColorScheme.light(),
            ),
            builder: (context, currentLocale, child) => Localizations.override(
              context: context,
              locale: currentLocale,
              child: child,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Copy'), findsOneWidget);
    locale.value = const Locale('ja');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('コピー'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();
    expect(find.text('コードをコピーしました'), findsOneWidget);
  });
}
