import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
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
      await _pumpMfm(tester, example.mfm);

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

  testWidgets('Search は検索ボタンを描画する', (tester) async {
    await _pumpExample(tester, 'Search');

    expect(find.text('Search'), findsWidgets);
  });
}

Future<void> _pumpExample(WidgetTester tester, String name) {
  final example = MfmExamples.categories
      .expand((category) => category.examples)
      .singleWhere((example) => example.name == name);
  return _pumpMfm(tester, example.mfm);
}

Future<void> _pumpMfm(WidgetTester tester, String mfm) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: MfmText(text: mfm),
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
