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
    await tester.pumpWidget(
      const CupertinoApp(home: MfmText(text: source)),
    );

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
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: entry.value)),
        );

        final highlight = tester.widget<HighlightView>(
          find.byType(HighlightView),
        );
        expect(highlight.textStyle?.fontSize, 24);
        expect(highlight.textStyle?.fontFamily, 'monospace');
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.byType(HighlightView),
            matching: find.byType(RichText),
          ),
        );
        expect(richText.text.style?.fontSize, 24);
        expect(richText.text.style?.fontFamily, 'monospace');
      });
    }

    testWidgets('サイズ未指定ならHighlightViewに固定サイズを渡さない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MfmCodeBlock(code: code, theme: {}),
          ),
        ),
      );

      final highlight = tester.widget<HighlightView>(
        find.byType(HighlightView),
      );
      expect(highlight.textStyle?.fontSize, isNull);
      expect(highlight.textStyle?.fontFamily, 'monospace');
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
            child: const MfmCodeBlock(code: code, theme: {}),
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
