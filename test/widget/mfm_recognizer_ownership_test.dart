import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _urlA = 'https://outside.test/a';
const _urlB = 'https://outside.test/b';
const _style = TextStyle(fontFamily: 'Ahem', fontSize: 14, height: 1);

Widget _host(
  String source,
  MfmRenderConfig config, {
  bool isNote = true,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(
    style: _style,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 700,
        child: MfmText(text: source, config: config, isNote: isNote),
      ),
    ),
  ),
);

MfmRenderConfig _config(void Function(String)? callback, {String? localHost}) =>
    MfmRenderConfig(
      localHost: localHost,
      onLinkTap: callback,
      onMentionTap: callback,
      onHashtagTap: callback,
      mentionOptions: const MfmMentionOptions(
        presentation: MfmMentionPresentation.text,
      ),
    );

Finder get _paragraphs => find.descendant(
  of: find.byType(MfmText),
  matching: find.byWidgetPredicate((widget) => widget is RichText),
);

List<TapGestureRecognizer> _recognizers(WidgetTester tester) {
  final recognizers = <TapGestureRecognizer>{};
  void visit(InlineSpan span) {
    if (span is! TextSpan) return;
    final recognizer = span.recognizer;
    if (recognizer is TapGestureRecognizer) recognizers.add(recognizer);
    span.children?.forEach(visit);
  }

  for (final paragraph in tester.widgetList<RichText>(_paragraphs)) {
    visit(paragraph.text);
  }
  return recognizers.toList();
}

Offset _firstGlyph(WidgetTester tester) {
  final paragraph = tester.renderObject<RenderParagraph>(_paragraphs.first);
  final box = paragraph
      .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
      .first;
  return paragraph.localToGlobal(box.toRect().center);
}

class _RecognizerTracker {
  final created = <TapGestureRecognizer>{};
  final disposed = <TapGestureRecognizer>{};

  void onEvent(ObjectEvent event) {
    final object = event.object;
    if (object is! TapGestureRecognizer) return;
    if (event is ObjectCreated) created.add(object);
    if (event is ObjectDisposed) disposed.add(object);
  }

  void start() {
    expect(kFlutterMemoryAllocationsEnabled, isTrue);
    FlutterMemoryAllocations.instance.addListener(onEvent);
    addTearDown(() {
      FlutterMemoryAllocations.instance.removeListener(onEvent);
      for (final recognizer in created.difference(disposed)) {
        recognizer.dispose();
      }
    });
  }
}

void main() {
  for (final sample in [
    (name: 'URL', a: _urlA, b: _urlB),
    (name: 'link', a: '[link]($_urlA)', b: '[link]($_urlB)'),
  ]) {
    testWidgets('${sample.name} replacement cannot inherit a pending tap', (
      tester,
    ) async {
      final calls = <String>[];
      final tracker = _RecognizerTracker()..start();
      await tester.pumpWidget(_host(sample.a, _config(calls.add)));
      final original = _recognizers(tester).single;
      final pointer = await tester.startGesture(_firstGlyph(tester));
      // Let the original recognizer accept the tap before replacing its target.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpWidget(_host(sample.b, _config(calls.add)));
      expect(_recognizers(tester).single, isNot(same(original)));
      expect(tracker.disposed, contains(original));
      await pointer.up();
      await tester.pump();
      expect(calls, isNot(contains(_urlB)));
      expect(calls, everyElement(_urlA));
      expect(tester.takeException(), isNull);
      // The replacement still accepts a new tap.
      await tester.tapAt(_firstGlyph(tester));
      expect(calls.last, _urlB);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tracker.disposed, containsAll(tracker.created));
    });

    testWidgets('${sample.name} clears and disposes a disabled callback', (
      tester,
    ) async {
      final calls = <String>[];
      final tracker = _RecognizerTracker()..start();
      await tester.pumpWidget(_host(sample.a, _config(calls.add)));
      final original = _recognizers(tester).single;
      final pointer = await tester.startGesture(_firstGlyph(tester));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpWidget(_host(sample.a, _config(null)));
      expect(_recognizers(tester), isEmpty);
      expect(tracker.disposed, contains(original));
      await pointer.up();
      await tester.pump();
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
      // Re-enabling uses a fresh recognizer and keeps the icon tappable.
      await tester.pumpWidget(_host(sample.a, _config(calls.add)));
      expect(_recognizers(tester).single, isNot(same(original)));
      await tester.tap(find.byType(Icon));
      expect(calls, [_urlA]);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tracker.disposed, containsAll(tracker.created));
    });

    testWidgets('${sample.name} icon shares the glyph recognizer', (
      tester,
    ) async {
      final calls = <String>[];
      final tracker = _RecognizerTracker()..start();
      await tester.pumpWidget(_host(sample.a, _config(calls.add)));
      final recognizer = _recognizers(tester).single;
      final listener = tester.widget<Listener>(
        find.ancestor(of: find.byType(Icon), matching: find.byType(Listener)),
      );
      expect(listener.onPointerDown, recognizer.addPointer);
      expect(tracker.created, {recognizer});
      await tester.tap(find.byType(Icon));
      expect(calls, [_urlA]);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tracker.disposed, {recognizer});
    });
  }

  for (final sample in [
    (name: 'URL', a: _urlA, b: _urlB, target: _urlA),
    (
      name: 'link',
      a: '[link]($_urlA)',
      b: '[link]($_urlB)',
      target: _urlA,
    ),
    (name: 'mention', a: '@alice', b: '@bob', target: '@alice'),
    (name: 'hashtag', a: '#tag', b: '#other', target: 'tag'),
  ]) {
    testWidgets('${sample.name} reuses identity with the latest callback', (
      tester,
    ) async {
      final before = <String>[];
      final after = <String>[];
      final tracker = _RecognizerTracker()..start();
      await tester.pumpWidget(_host(sample.a, _config(before.add)));
      final original = _recognizers(tester).single;
      final pointer = await tester.startGesture(_firstGlyph(tester));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpWidget(_host(sample.a, _config(after.add)));
      expect(_recognizers(tester).single, same(original));
      expect(tracker.created, {original});
      expect(tracker.disposed, isEmpty);
      await pointer.up();
      await tester.pump();
      expect(before, isEmpty);
      expect(after, [sample.target]);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tracker.disposed, {original});
    });

    testWidgets('${sample.name} tracks occurrence within each target', (
      tester,
    ) async {
      final tracker = _RecognizerTracker()..start();
      final config = _config((_) {});
      await tester.pumpWidget(
        _host('${sample.a} ${sample.a} ${sample.b}', config),
      );
      final original = _recognizers(tester);
      expect(original, hasLength(3));
      await tester.pumpWidget(
        _host('${sample.b} ${sample.a} ${sample.a}', config),
      );
      expect(_recognizers(tester), [original[2], original[0], original[1]]);
      expect(tracker.created, original.toSet());
      expect(tracker.disposed, isEmpty);
      await tester.pumpWidget(_host('${sample.b} ${sample.a}', config));
      expect(_recognizers(tester), [original[2], original[0]]);
      expect(tracker.disposed, {original[1]});
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tracker.disposed, original.toSet());
    });
  }

  testWidgets('URL and labelled link to the same target have separate keys', (
    tester,
  ) async {
    final config = _config((_) {});
    await tester.pumpWidget(_host('$_urlA [link]($_urlA)', config));
    final original = _recognizers(tester);
    expect(original, hasLength(2));
    await tester.pumpWidget(_host('[link]($_urlA) $_urlA', config));
    expect(_recognizers(tester), original.reversed.toList());
  });

  testWidgets('mention identity uses the resolved account', (tester) async {
    final calls = <String>[];
    final tracker = _RecognizerTracker()..start();
    await tester.pumpWidget(
      _host('@alice', _config(calls.add, localHost: 'first.test')),
    );
    final original = _recognizers(tester).single;
    final pointer = await tester.startGesture(_firstGlyph(tester));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(
      _host('@alice', _config(calls.add, localHost: 'second.test')),
    );
    expect(_recognizers(tester).single, isNot(same(original)));
    expect(tracker.disposed, contains(original));
    await pointer.up();
    expect(calls, isEmpty);
    await tester.tapAt(_firstGlyph(tester));
    expect(calls, ['@alice@second.test']);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tracker.disposed, containsAll(tracker.created));
  });

  testWidgets('nested builder copies share the State-owned pool', (
    tester,
  ) async {
    final tracker = _RecognizerTracker()..start();
    const source = r'> **https://outside.test/a** $[flip @alice #tag]';
    await tester.pumpWidget(_host(source, _config((_) {})));
    final original = _recognizers(tester);
    expect(original, hasLength(3));
    await tester.pumpWidget(_host(source, _config((_) {})));
    expect(_recognizers(tester), original);
    expect(tracker.created, original.toSet());
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tracker.disposed, original.toSet());
  });

  testWidgets('hashtag callback changes reuse identity and update details', (
    tester,
  ) async {
    final calls = <String>[];
    final details = <MfmHashtagTapDetails>[];
    await tester.pumpWidget(_host('#tag', _config(calls.add)));
    final original = _recognizers(tester).single;
    final detailedConfig = MfmRenderConfig(onHashtagTapDetails: details.add);
    await tester.pumpWidget(_host('#tag', detailedConfig, isNote: false));
    expect(_recognizers(tester).single, same(original));
    await tester.tapAt(_firstGlyph(tester));
    expect(calls, isEmpty);
    expect(details.single.tag, 'tag');
    expect(details.single.isNote, isFalse);
    expect(details.single.path, '/user-tags/tag');
    details.clear();
    await tester.pumpWidget(_host('#tag', detailedConfig));
    expect(_recognizers(tester).single, same(original));
    await tester.tapAt(_firstGlyph(tester));
    expect(calls, isEmpty);
    expect(details.single.tag, 'tag');
    expect(details.single.isNote, isTrue);
    expect(details.single.path, '/tags/tag');
  });
}
