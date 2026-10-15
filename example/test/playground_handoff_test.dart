import 'package:example/app/app.dart';
import 'package:example/app/home_page.dart';
import 'package:example/core/emoji/example_startup.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:example/features/catalog/presentation/catalog_tab.dart';
import 'package:example/features/playground/presentation/playground_tab.dart';
import 'package:example/features/playground/presentation/widgets/mfm_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

MfmExample _example(String name) => MfmExamples.categories
    .expand((c) => c.examples)
    .singleWhere((e) => e.name == name);

Future<void> _start(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MfmExampleApp(emojiStatus: ExampleEmojiStatus.offline),
  );
  await tester.pump();
}

void _load(WidgetTester tester, String name) {
  tester
      .widget<CatalogTab>(find.byType(CatalogTab, skipOffstage: false))
      .onTryExample(_example(name));
}

PlaygroundTab _playground(WidgetTester tester) => tester.widget<PlaygroundTab>(
  find.byType(PlaygroundTab, skipOffstage: false),
);

void main() {
  testWidgets('catalog action opens the actual example with its overrides', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.byKey(const ValueKey('try:Bold')));
    await tester.pump();
    expect(_playground(tester).controller.example, same(_example('Bold')));
    expect(find.text('選択中: Bold'), findsOneWidget);

    _load(tester, 'Display Name');
    await tester.pump();
    final panel = tester.widget<MfmPreviewPanel>(find.byType(MfmPreviewPanel));
    expect(panel.config, same(_example('Display Name').config));
    expect(panel.plain, isTrue);
    expect(panel.nowrap, isTrue);
    final preview = tester.widget<MfmText>(
      find.descendant(
        of: find.byType(MfmPreviewPanel),
        matching: find.byType(MfmText),
      ),
    );
    expect(preview.plain, isTrue);
    expect(preview.nowrap, isTrue);
    final global = ExampleSettingsScope.of(
      tester.element(find.byType(HomePage)),
    );
    expect(global.plain, isFalse);
    expect(global.nowrap, isFalse);
  });

  testWidgets('confirmation cancellation, dismissal, acceptance and clear', (
    tester,
  ) async {
    await _start(tester);
    _load(tester, 'Display Name');
    await tester.pump();
    final controller = _playground(tester).controller;
    controller.editor.text = 'edited';
    await tester.pump();
    await tester.tap(find.text('カタログ'));
    await tester.pump();
    _load(tester, 'Bold');
    _load(tester, 'Italic (HTML)');
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.text, 'edited');
    expect(controller.example, same(_example('Display Name')));
    expect(find.text('テキスト整形'), findsOneWidget);

    _load(tester, 'Bold');
    await tester.pump();
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.text, 'edited');
    expect(find.text('テキスト整形'), findsOneWidget);

    _load(tester, 'Bold');
    await tester.pump();
    await tester.tap(find.text('破棄して続ける'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.example, same(_example('Bold')));
    expect(controller.text, _example('Bold').mfm);
    expect(find.text('選択中: Bold'), findsOneWidget);

    controller.editor.text = 'clear me';
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('clearPlaygroundText')));
    await tester.tap(find.byKey(const Key('clearPlaygroundText')));
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.text, 'clear me');
    await tester.tap(find.byKey(const Key('clearPlaygroundText')));
    await tester.pump();
    await tester.tap(find.text('破棄して続ける'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.text, isEmpty);
    expect(controller.example, same(_example('Bold')));
    expect(controller.needsDiscardConfirmation, isFalse);
    _load(tester, 'Display Name');
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'tab, width and global settings retain text, selection and setup',
    (
      tester,
    ) async {
      await _start(tester);
      _load(tester, 'Display Name');
      await tester.pump();
      final controller = _playground(tester).controller;
      controller.editor.text = 'edited text';
      const selection = TextSelection(baseOffset: 2, extentOffset: 5);
      controller.editor.selection = selection;
      final inputState = tester.state(find.byKey(const Key('playgroundInput')));
      final settings =
          ExampleSettingsScope.of(
              tester.element(find.byType(HomePage)),
            )
            ..themeMode = ThemeMode.dark
            ..plain = true;
      await tester.pump();
      settings.reset();
      await tester.pump();
      await tester.tap(find.text('カタログ'));
      await tester.pump();
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pump();
      await tester.tap(find.text('プレイグラウンド'));
      await tester.pump();
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pump();
      expect(
        tester.state(find.byKey(const Key('playgroundInput'))),
        same(inputState),
      );
      expect(controller.text, 'edited text');
      expect(controller.editor.selection, selection);
      expect(controller.example, same(_example('Display Name')));
      await tester.ensureVisible(find.byKey(const Key('releaseOverrides')));
      await tester.tap(find.byKey(const Key('releaseOverrides')));
      await tester.pump();
      expect(controller.text, 'edited text');
      expect(controller.editor.selection, selection);
      expect(controller.example, isNull);
      final panel = tester.widget<MfmPreviewPanel>(
        find.byType(MfmPreviewPanel),
      );
      expect(panel.config, isNull);
      expect(panel.plain, isNull);
      expect(panel.nowrap, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('explicit reload resets search input but cursor changes do not', (
    tester,
  ) async {
    await _start(tester);
    _load(tester, 'Search');
    await tester.pump();
    final searches = find.descendant(
      of: find.byType(MfmPreviewPanel),
      matching: find.byType(EditableText),
    );
    final search = tester.widget<EditableText>(searches.first).controller
      ..text = 'local search edit';
    _playground(tester).controller.editor.selection =
        const TextSelection.collapsed(offset: 1);
    await tester.pump();
    expect(
      tester.widget<EditableText>(searches.first).controller,
      same(search),
    );
    expect(search.text, 'local search edit');
    _load(tester, 'Search');
    await tester.pump();
    expect(
      tester.widget<EditableText>(searches.first).controller.text,
      'Misskey',
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'reloading after scrolling does not reuse offset as expansion state',
    (
      tester,
    ) async {
      await _start(tester);
      _load(tester, 'Display Name');
      await tester.pump();
      await tester.tap(find.text('使用設定'));
      await tester.pump(const Duration(milliseconds: 300));
      final scroll = find
          .descendant(
            of: find.byType(PlaygroundTab),
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(scroll).position.jumpTo(100);
      await tester.pump();
      _load(tester, 'Display Name');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('選択中: Display Name'), findsOneWidget);
    },
  );

  testWidgets('disposing while confirmation is pending does not update state', (
    tester,
  ) async {
    await _start(tester);
    _playground(tester).controller.editor.text = 'edited';
    _load(tester, 'Bold');
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow enlarged text and keyboard leave preview reachable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      const MfmExampleApp(emojiStatus: ExampleEmojiStatus.offline),
    );
    _load(tester, 'Display Name');
    await tester.pump();
    _playground(tester).controller.editor.text = List.filled(
      50,
      'long input',
    ).join('\n');
    await tester.pump();
    await tester.ensureVisible(find.text('プレビュー'));
    await tester.pump();
    expect(find.text('プレビュー').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
