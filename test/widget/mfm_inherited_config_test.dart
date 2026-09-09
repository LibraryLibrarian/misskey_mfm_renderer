import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_code_block.dart';

void main() {
  testWidgets('MfmConfig.of returns inherited config', (tester) async {
    const inherited = MfmRenderConfig(
      enableAdvancedMfm: false,
      enableAnimation: false,
    );
    late MfmRenderConfig found;

    await tester.pumpWidget(
      MfmConfig(
        config: inherited,
        child: Builder(
          builder: (context) {
            found = MfmConfig.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(identical(found, inherited), isTrue);
  });

  testWidgets('MfmText uses inherited config when explicit is default', (
    tester,
  ) async {
    const inherited = MfmRenderConfig(emojiBuilder: _emojiTextBuilder);

    await tester.pumpWidget(
      const MfmConfig(
        config: inherited,
        child: MaterialApp(
          home: Scaffold(body: MfmText(text: ':emoji:', simple: true)),
        ),
      ),
    );

    expect(find.text('inherited:14.0:1.0'), findsOneWidget);
  });

  testWidgets('MfmText merges inherited and explicit config', (tester) async {
    const inherited = MfmRenderConfig(emojiBuilder: _emojiTextBuilder);

    final explicit = MfmRenderConfig(onLinkTap: (_) {});

    await tester.pumpWidget(
      MfmConfig(
        config: inherited,
        child: MaterialApp(
          home: Scaffold(
            body: MfmText(text: ':emoji:', simple: true, config: explicit),
          ),
        ),
      ),
    );

    expect(find.text('inherited:14.0:1.0'), findsOneWidget);
  });

  testWidgets('explicit emojiBuilder overrides inherited', (tester) async {
    const inherited = MfmRenderConfig(emojiBuilder: _emojiTextBuilder);

    const explicit = MfmRenderConfig(emojiBuilder: _emojiTextBuilderExplicit);

    await tester.pumpWidget(
      const MfmConfig(
        config: inherited,
        child: MaterialApp(
          home: Scaffold(
            body: MfmText(text: ':emoji:', simple: true, config: explicit),
          ),
        ),
      ),
    );

    expect(find.text('explicit:14.0:1.0'), findsOneWidget);
  });

  group('MFM配色の継承', () {
    const inheritedLight = MfmColorScheme.light(link: Colors.orange);
    const inheritedDark = MfmColorScheme.dark(link: Colors.purple);

    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name}配色を既存の明示設定と結合する', (tester) async {
        await tester.pumpWidget(
          MfmConfig(
            config: const MfmRenderConfig(
              lightColorScheme: inheritedLight,
              darkColorScheme: inheritedDark,
            ),
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const Scaffold(
                body: MfmText(
                  text: 'https://example.com',
                  config: MfmRenderConfig(enableAnimation: false),
                ),
              ),
            ),
          ),
        );

        expect(
          _spanForText(tester, 'https://example.com').style!.color,
          brightness == Brightness.dark ? Colors.purple : Colors.orange,
        );
      });
    }

    testWidgets('明示配色が継承配色より優先される', (tester) async {
      await tester.pumpWidget(
        const MfmConfig(
          config: MfmRenderConfig(lightColorScheme: inheritedLight),
          child: MaterialApp(
            home: Scaffold(
              body: MfmText(
                text: 'https://example.com',
                config: MfmRenderConfig(
                  lightColorScheme: MfmColorScheme.light(link: Colors.teal),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        _spanForText(tester, 'https://example.com').style!.color,
        Colors.teal,
      );
    });
  });

  group('コードコピー設定の継承', () {
    void inheritedCallback(String _) {}
    void explicitCallback(String _) {}
    final inherited = MfmRenderConfig(
      onCodeCopied: inheritedCallback,
      codeCopyTooltip: 'Inherited tooltip',
      codeCopiedMessage: 'Inherited message',
    );

    final cases = {
      '既定設定': const MfmRenderConfig(),
      '既存フィールドのみの明示設定': const MfmRenderConfig(enableAnimation: false),
      'コールバックのみの明示設定': MfmRenderConfig(onCodeCopied: explicitCallback),
      'ツールチップのみの明示設定': const MfmRenderConfig(
        codeCopyTooltip: 'Explicit tooltip',
      ),
      '完了メッセージのみの明示設定': const MfmRenderConfig(
        codeCopiedMessage: 'Explicit message',
      ),
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key}と継承したコピー設定を結合する', (tester) async {
        final explicit = entry.value;
        await tester.pumpWidget(
          MfmConfig(
            config: inherited,
            child: MaterialApp(
              home: Scaffold(
                body: MfmText(text: '```\ncode\n```', config: explicit),
              ),
            ),
          ),
        );

        final block = tester.widget<MfmCodeBlock>(find.byType(MfmCodeBlock));
        expect(
          block.onCodeCopied,
          same(explicit.onCodeCopied ?? inheritedCallback),
        );
        expect(
          block.copyTooltip,
          explicit.codeCopyTooltip ?? 'Inherited tooltip',
        );
        expect(
          block.copiedMessage,
          explicit.codeCopiedMessage ?? 'Inherited message',
        );
        expect(
          find.bySemanticsLabel(
            explicit.codeCopyTooltip ?? 'Inherited tooltip',
          ),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('MfmText inherits searchButtonLabel', (tester) async {
    await tester.pumpWidget(
      const MfmConfig(
        config: MfmRenderConfig(searchButtonLabel: 'Inherited search'),
        child: MaterialApp(
          home: Scaffold(body: MfmText(text: 'flutter Search')),
        ),
      ),
    );

    expect(find.text('Inherited search'), findsOneWidget);
  });

  testWidgets('explicit searchButtonLabel overrides inherited', (tester) async {
    await tester.pumpWidget(
      const MfmConfig(
        config: MfmRenderConfig(searchButtonLabel: 'Inherited search'),
        child: MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: 'flutter Search',
              config: MfmRenderConfig(searchButtonLabel: 'Explicit search'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Explicit search'), findsOneWidget);
    expect(find.text('Inherited search'), findsNothing);
  });

  testWidgets('explicit locale label clears inherited searchButtonLabel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MfmConfig(
        config: const MfmRenderConfig(searchButtonLabel: 'Inherited search'),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: const MfmText(
                  text: 'flutter Search',
                  config: MfmRenderConfig(useLocaleSearchButtonLabel: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('検索'), findsOneWidget);
    expect(find.text('Inherited search'), findsNothing);
  });
}

TextSpan _spanForText(WidgetTester tester, String text) {
  final root = tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
  return _findSpan(root, text)!;
}

TextSpan? _findSpan(TextSpan span, String text) {
  if (span.text == text) return span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) {
      final found = _findSpan(child, text);
      if (found != null) return found;
    }
  }
  return null;
}

Widget _emojiTextBuilder(String _, MfmEmojiContext context) =>
    Text('inherited:${context.fontSize}:${context.scale}');

Widget _emojiTextBuilderExplicit(String _, MfmEmojiContext context) =>
    Text('explicit:${context.fontSize}:${context.scale}');
