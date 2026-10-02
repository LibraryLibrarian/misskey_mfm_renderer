import 'package:example/core/settings/example_settings.dart';
import 'package:example/core/widgets/mfm_preview_card.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:example/features/catalog/presentation/widgets/catalog_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_shake_widget.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_twitch_widget.dart';

void main() {
  for (final isShake in [false, true]) {
    final name = isShake ? 'Shake' : 'Twitch';
    testWidgets('$name (開始遅延) は2秒間無変形で待機して開始する', (tester) async {
      await _pumpExample(tester, '$name (開始遅延)');
      final transforms = find.descendant(
        of: find.byType(isShake ? MfmShakeWidget : MfmTwitchWidget),
        matching: find.byType(Transform),
      );
      expect(transforms, findsOneWidget);
      expect(_richTextPlainText(tester), contains('2秒待ってから動く'));
      expect(
        tester.widget<Transform>(transforms).transform.isIdentity(),
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 1999));
      expect(
        tester.widget<Transform>(transforms).transform.isIdentity(),
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      final matrix = tester.widget<Transform>(transforms).transform;
      expect(matrix.storage[12], isShake ? -3 : 7);
      expect(matrix.storage[13], isShake ? -1 : -2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'catalog forwards config/plain/nowrap while retaining app config',
    (tester) async {
      final settings = ExampleSettings();
      addTearDown(settings.dispose);
      final example = MfmExamples.categories
          .expand((c) => c.examples)
          .singleWhere((e) => e.name == 'Display Name');
      await tester.pumpWidget(
        MaterialApp(
          home: ExampleSettingsScope(
            settings: settings,
            child: MfmConfig(
              config: const MfmRenderConfig(
                baseTextStyle: TextStyle(fontSize: 23),
              ),
              child: Scaffold(
                body: CatalogSection(
                  category: MfmCategory(title: 'fixture', examples: [example]),
                ),
              ),
            ),
          ),
        ),
      );
      final card = tester.widget<MfmPreviewCard>(find.byType(MfmPreviewCard));
      expect(card.config, same(example.config));
      expect(card.plain, isTrue);
      expect(card.nowrap, isTrue);
      final text = tester.widget<MfmText>(find.byType(MfmText));
      expect(text.plain, isTrue);
      expect(text.nowrap, isTrue);
      final rich = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(MfmText),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(rich.text.style!.fontSize, 23);
    },
  );

  testWidgets('display name is plain, nowrap and offline', (tester) async {
    await _pumpExample(tester, 'Display Name');
    final widget = tester.widget<MfmText>(find.byType(MfmText));
    expect(widget.plain, isTrue);
    expect(widget.nowrap, isTrue);
    expect(widget.config.author!.host, 'remote.test');
    expect(widget.config.emojiUrls, contains('offline'));
    expect(_richTextPlainText(tester), contains('@alice'));
    expect(find.byType(Image), findsNothing);
  });

  final examples = MfmExamples.categories
      .expand((category) => category.examples)
      .toList(growable: false);

  test('カタログのサンプル名と表示用構文は有効', () {
    final names = examples.map((example) => example.name).toList();

    expect(names.toSet(), hasLength(names.length));
    for (final example in examples) {
      expect(example.syntax, isNotEmpty, reason: example.name);
      expect(example.mfm, isNotEmpty, reason: example.name);
    }
  });

  testWidgets('全サンプルを構文どおりに描画できる', (tester) async {
    for (final example in examples) {
      await _pumpMfm(tester, example.mfm, example: example);

      final plainText = _richTextPlainText(tester);
      if (example.name == 'Plain') {
        expect(plainText, contains('**そのまま**'));
        expect(plainText, contains(r'$[x2 表示]'));
      } else {
        for (final literalSyntax in const [
          r'$[',
          '**',
          '~~',
          '<center>',
          '<small>',
          '<i>',
        ]) {
          expect(
            plainText,
            isNot(contains(literalSyntax)),
            reason: '${example.name} に未解釈の構文があります',
          );
        }
      }
    }
  });

  testWidgets('Bold は太字のTextSpanとして描画される', (tester) async {
    await _pumpExample(tester, 'Bold');

    expect(
      _textSpans(tester).any(
        (span) => span.style?.fontWeight == FontWeight.bold,
      ),
      isTrue,
    );
  });

  testWidgets('Italic は斜体のTextSpanとして描画される', (tester) async {
    await _pumpExample(tester, 'Italic (HTML)');

    expect(
      _textSpans(tester).any(
        (span) => span.style?.fontStyle == FontStyle.italic,
      ),
      isTrue,
    );
  });

  testWidgets('不正なfg色は赤として描画される', (tester) async {
    await _pumpExample(tester, 'Foreground Color (不正値)');

    expect(
      _textSpans(tester).any(
        (span) => span.style?.color == const Color(0xFFFF0000),
      ),
      isTrue,
    );
  });

  testWidgets('x2 は元の2倍のフォントサイズで描画される', (tester) async {
    await _pumpExample(tester, 'x2');

    expect(
      _textSpans(tester).any((span) => span.style?.fontSize == 28),
      isTrue,
    );
  });

  testWidgets('Math Block は等幅フォントで描画される', (tester) async {
    await _pumpExample(tester, 'Math Block');

    expect(
      _textSpans(tester).any((span) => span.style?.fontFamily == 'monospace'),
      isTrue,
    );
  });

  testWidgets('punycode URL は復号したホスト名を表示する', (tester) async {
    await _pumpExample(tester, 'URL (punycode)');

    expect(_richTextPlainText(tester), contains('日本語.jp'));
  });

  for (final sample in [
    (name: 'Unixtime (過去・detail)', fragment: '2023,'),
    (name: 'Unixtime (整数prefix)', fragment: '2023,'),
    (name: 'Unixtime (invalid)', fragment: 'None'),
    (name: 'Unixtime (日本語)', fragment: '2033/'),
    (name: 'Unixtime (English・absolute)', fragment: '2033,'),
  ]) {
    testWidgets('${sample.name} は設定された日時書式で描画する', (tester) async {
      await _pumpExample(tester, sample.name);
      expect(_richTextPlainText(tester), contains(sample.fragment));
      expect(find.byType(Icon), findsOneWidget);
      if (sample.name.endsWith('absolute)')) {
        expect(_richTextPlainText(tester), isNot(contains('(')));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Search は検索ボタンを描画する', (tester) async {
    await _pumpExample(tester, 'Search');

    expect(find.text('Search'), findsWidgets);
  });
}

Future<void> _pumpExample(WidgetTester tester, String name) {
  final example = MfmExamples.categories
      .expand((category) => category.examples)
      .singleWhere((example) => example.name == name);
  return _pumpMfm(tester, example.mfm, example: example);
}

Future<void> _pumpMfm(
  WidgetTester tester,
  String mfm, {
  MfmExample? example,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: MfmText(
            text: mfm,
            config: example?.config ?? const MfmRenderConfig(),
            plain: example?.plain ?? false,
            nowrap: example?.nowrap ?? false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

String _richTextPlainText(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((richText) => richText.text.toPlainText())
      .join();
}

List<TextSpan> _textSpans(WidgetTester tester) {
  final spans = <TextSpan>[];
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    richText.text.visitChildren((child) {
      if (child is TextSpan) {
        spans.add(child);
      }
      return true;
    });
    _collectStyledTextSpans(richText.text, spans);
  }
  return spans;
}

void _collectStyledTextSpans(InlineSpan span, List<TextSpan> textSpans) {
  if (span is! TextSpan || span.children == null) {
    return;
  }

  textSpans.add(span);
  for (final child in span.children!) {
    _collectStyledTextSpans(child, textSpans);
  }
}
