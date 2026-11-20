import 'package:example/core/settings/example_settings.dart';
import 'package:example/core/widgets/mfm_preview_card.dart';
import 'package:example/features/catalog/data/catalog_navigation.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:example/features/catalog/presentation/widgets/catalog_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'card shows setup, copies only MFM and hands off the same example',
    (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final example = MfmExamples.categories
            .expand((c) => c.examples)
            .singleWhere((e) => e.name == 'Unixtime (English・absolute)');
        final settings = ExampleSettings();
        addTearDown(settings.dispose);
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final clipboard = <Object?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard.add(call.arguments);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        MfmExample? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: ExampleSettingsScope(
              settings: settings,
              child: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: CatalogDetailList(
                    page: CatalogExamplePage(
                      id: 'fixture-page',
                      title: 'fixture',
                      description: '',
                      groups: [
                        MfmFeatureGroup(
                          id: 'fixture',
                          title: '設定',
                          examples: [example],
                        ),
                      ],
                    ),
                    onTryExample: (value) => selected = value,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text(example.setupSummary!), findsOneWidget);
        expect(find.text('MFMをコピー'), findsNothing);
        expect(find.text('この設定で試す'), findsNothing);
        for (final label in ['MFMをコピー', 'この設定で試す']) {
          expect(find.byTooltip(label), findsOneWidget);
          expect(
            tester
                .getSemantics(find.byTooltip(label))
                .getSemanticsData()
                .tooltip,
            label,
          );
        }
        for (final action in ['copy', 'try']) {
          final button = find.byKey(ValueKey('$action:${example.name}'));
          expect(tester.widget(button), isA<IconButton>());
          final size = tester.getSize(button);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        await tester.tap(find.byKey(ValueKey('copy:${example.name}')));
        await tester.pump();
        expect(clipboard, [
          <String, Object?>{'text': example.mfm},
        ]);
        await tester.tap(find.byKey(ValueKey('try:${example.name}')));
        expect(selected, same(example));
        await tester.ensureVisible(find.text('使用設定'));
        await tester.tap(find.text('使用設定'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(example.setupCode!), findsOneWidget);
        expect(find.byType(MfmPreviewCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
