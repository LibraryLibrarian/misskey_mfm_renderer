import 'package:example/core/settings/example_settings.dart';
import 'package:example/core/widgets/mfm_preview_card.dart';
import 'package:example/features/catalog/data/catalog_navigation.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:example/features/catalog/presentation/widgets/catalog_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<CatalogExamplePage> _pages(CatalogNode node) sync* {
  switch (node) {
    case CatalogMenu():
      for (final child in node.children) {
        yield* _pages(child);
      }
    case CatalogExamplePage():
      yield node;
  }
}

void main() {
  for (final page in _pages(CatalogNavigation.root)) {
    testWidgets('${page.id}: every section, card and action is reachable', (
      tester,
    ) async {
      final settings = ExampleSettings();
      addTearDown(settings.dispose);
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Object? clipboard;
      MfmExample? selected;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') clipboard = call.arguments;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExampleSettingsScope(
            settings: settings,
            child: Scaffold(
              body: CatalogDetailList(
                page: page,
                onTryExample: (example) => selected = example,
              ),
            ),
          ),
        ),
      );
      final scroll = find.byType(Scrollable).first;
      for (final group in page.groups) {
        final heading = find.byKey(ValueKey('catalog-section:${group.id}'));
        await tester.scrollUntilVisible(heading, 250, scrollable: scroll);
        expect(tester.widget<Semantics>(heading).properties.header, isTrue);
        for (final example in group.examples) {
          final card = find.byKey(ValueKey(example.name));
          await tester.scrollUntilVisible(card, 250, scrollable: scroll);
          final widget = tester.widget<MfmPreviewCard>(card);
          expect(widget.mfm, example.mfm);
          expect(widget.config, same(example.config));
          expect(widget.plain, example.plain);
          expect(widget.nowrap, example.nowrap);
          for (final action in ['copy', 'try']) {
            final button = find.byKey(ValueKey('$action:${example.name}'));
            await Scrollable.ensureVisible(tester.element(button));
            await tester.pump();
            expect(button.hitTestable(), findsOneWidget);
            await tester.tap(button);
            await tester.pump();
          }
          expect(clipboard, <String, Object?>{'text': example.mfm});
          expect(selected, same(example));
          expect(tester.takeException(), isNull);
        }
      }
      expect(
        find.byKey(ValueKey(page.groups.last.examples.last.name)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
