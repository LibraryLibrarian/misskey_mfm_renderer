import 'package:example/app/app.dart';
import 'package:example/app/home_page.dart';
import 'package:example/core/emoji/example_startup.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:example/core/widgets/mfm_preview_card.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:example/features/catalog/presentation/widgets/catalog_lists.dart';
import 'package:example/features/playground/presentation/playground_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

Future<void> _pumpTransition(WidgetTester tester) async {
  // Periodic previews never settle; advance a bounded sequence of frames.
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _start(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MfmExampleApp(emojiStatus: ExampleEmojiStatus.offline),
  );
  await _pumpTransition(tester);
}

Future<void> _open(WidgetTester tester, List<String> path) async {
  for (final id in path) {
    final row = find.byKey(ValueKey('catalog-node:$id'));
    final scroll = find.descendant(
      of: find.byType(CatalogMenuList),
      matching: find.byType(Scrollable),
    );
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await _pumpTransition(tester);
    await tester.scrollUntilVisible(row, 200, scrollable: scroll);
    await tester.tap(row);
    await _pumpTransition(tester);
  }
}

Future<void> _tapSetup(WidgetTester tester, Finder expansion) async {
  final title = find.descendant(of: expansion, matching: find.text('使用設定'));
  await Scrollable.ensureVisible(tester.element(title), alignment: 0.2);
  await _pumpTransition(tester);
  expect(title.hitTestable(), findsOneWidget);
  await tester.tap(title);
}

Finder _detailScroll() => find
    .descendant(
      of: find.byType(CatalogDetailList),
      matching: find.byType(Scrollable),
    )
    .first;

ExampleSettings _settings(WidgetTester tester) => ExampleSettingsScope.of(
  tester.element(find.byType(HomePage)),
);

PlaygroundTab _playground(WidgetTester tester) => tester.widget<PlaygroundTab>(
  find.byType(PlaygroundTab, skipOffstage: false),
);

void main() {
  testWidgets('menus contain no previews and back unwinds each level', (
    tester,
  ) async {
    await _start(tester);
    expect(find.byType(CatalogMenuList), findsOneWidget);
    expect(find.byType(MfmPreviewCard), findsNothing);
    expect(find.byType(MfmText), findsNothing);
    await _open(tester, ['fn']);
    expect(find.byType(MfmText), findsNothing);
    expect(
      tester.widget<CatalogMenuList>(find.byType(CatalogMenuList)).menu.id,
      'fn',
    );
    await _open(tester, ['animation']);
    expect(find.byType(MfmText), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    await _open(tester, ['animation.rotation']);
    expect(find.byKey(const ValueKey('Spin (Z軸)')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _pumpTransition(tester);
    expect(
      tester.widget<CatalogMenuList>(find.byType(CatalogMenuList)).menu.id,
      'animation',
    );
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(
      tester.widget<CatalogMenuList>(find.byType(CatalogMenuList)).menu.id,
      'fn',
    );
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(
      tester.widget<CatalogMenuList>(find.byType(CatalogMenuList)).menu.id,
      'catalog',
    );
    expect(find.byType(BackButton), findsNothing);
  });

  for (final entry in [
    (
      path: ['text'],
      sections: [
        'text.bold',
        'text.italic',
        'text.strike',
        'text.small',
        'text.plain',
        'text.center',
      ],
    ),
    (path: ['fn', 'size'], sections: ['size.x2', 'size.x3', 'size.x4']),
    (
      path: ['fn', 'transform'],
      sections: [
        'transform.flip',
        'transform.rotate',
        'transform.scale',
        'transform.position',
      ],
    ),
  ]) {
    testWidgets('${entry.path.last} shows all sections without another route', (
      tester,
    ) async {
      await _start(tester);
      await _open(tester, entry.path);
      final list = tester.widget<CatalogDetailList>(
        find.byType(CatalogDetailList),
      );
      expect(list.page.groups.map((group) => group.id), entry.sections);
      final scrollState = tester.state<ScrollableState>(_detailScroll());
      for (final group in list.page.groups) {
        final heading = find.byKey(ValueKey('catalog-section:${group.id}'));
        await tester.scrollUntilVisible(
          heading,
          200,
          scrollable: _detailScroll(),
        );
        expect(tester.widget<Semantics>(heading).properties.header, isTrue);
        for (final example in group.examples) {
          final card = find.byKey(ValueKey(example.name));
          await tester.scrollUntilVisible(
            card,
            200,
            scrollable: _detailScroll(),
          );
          expect(tester.widget<MfmPreviewCard>(card).mfm, example.mfm);
        }
      }
      expect(tester.state<ScrollableState>(_detailScroll()), same(scrollState));
      await tester.tap(find.byType(BackButton));
      await _pumpTransition(tester);
      expect(find.byType(CatalogMenuList), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('settings back and root confirmation back retain detail', (
    tester,
  ) async {
    await _start(tester);
    await _open(tester, ['text']);
    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await _pumpTransition(tester);
    expect(find.text('表示設定'), findsOneWidget);
    expect(find.byType(CatalogDetailList), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('resetSettingsButton')),
      300,
    );
    await tester.tap(find.byKey(const Key('resetSettingsButton')));
    await _pumpTransition(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('表示設定'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(find.text('表示設定'), findsNothing);
    expect(find.byType(CatalogDetailList), findsOneWidget);
    _playground(tester).controller.editor.text = 'keep this draft';
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('try:Bold')));
    await _pumpTransition(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(CatalogDetailList), findsOneWidget);
    expect(_playground(tester).controller.text, 'keep this draft');
    await tester.tap(find.byKey(const ValueKey('try:Bold')));
    await _pumpTransition(tester);
    await tester.tap(find.text('キャンセル'));
    await _pumpTransition(tester);
    expect(find.byType(CatalogDetailList), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('try:Bold')));
    await _pumpTransition(tester);
    await tester.tap(find.text('破棄して続ける'));
    await _pumpTransition(tester);
    expect(find.byType(PlaygroundTab), findsOneWidget);
    expect(_playground(tester).controller.text, '**太字テキスト**');
    await tester.tap(find.text('カタログ'));
    await _pumpTransition(tester);
    expect(find.byType(CatalogDetailList), findsOneWidget);
  });

  testWidgets('inactive catalog cannot consume back or lose its route', (
    tester,
  ) async {
    await _start(tester);
    await _open(tester, ['text']);
    await tester.tap(find.text('プレイグラウンド'));
    await _pumpTransition(tester);
    final handler = tester.widget<NavigatorPopHandler<void>>(
      find.byType(NavigatorPopHandler<void>, skipOffstage: false),
    );
    expect(handler.enabled, isFalse);
    handler.onPopWithResult!(null);
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    await tester.tap(find.text('カタログ'));
    await _pumpTransition(tester);
    expect(find.byType(CatalogDetailList), findsOneWidget);
    expect(find.byKey(const ValueKey('try:Bold')), findsOneWidget);
  });

  testWidgets('detail, scroll and setup survive tabs, width and settings', (
    tester,
  ) async {
    await _start(tester);
    await _open(tester, ['fn', 'special']);
    const name = 'Unixtime (日本語)';
    final card = find.byKey(const ValueKey(name));
    await tester.scrollUntilVisible(card, 250, scrollable: _detailScroll());
    final expansion = find.descendant(
      of: card,
      matching: find.byType(ExpansionTile),
    );
    await _tapSetup(tester, expansion);
    await _pumpTransition(tester);
    final example = MfmExamples.categories
        .expand((category) => category.examples)
        .singleWhere((example) => example.name == name);
    expect(find.text(example.setupCode!), findsOneWidget);
    final scrollState = tester.state<ScrollableState>(_detailScroll());
    final offset = scrollState.position.pixels;
    await tester.tap(find.text('プレイグラウンド'));
    await _pumpTransition(tester);
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    await _pumpTransition(tester);
    _settings(tester).themeMode = ThemeMode.dark;
    _settings(tester).rootScale = 1.2;
    await _pumpTransition(tester);
    await tester.tap(find.text('カタログ'));
    await _pumpTransition(tester);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await _pumpTransition(tester);
    expect(tester.state<ScrollableState>(_detailScroll()), same(scrollState));
    expect(scrollState.position.pixels, closeTo(offset, 1));
    expect(find.text(example.setupCode!), findsOneWidget);
    final preview = tester.widget<MfmText>(
      find.descendant(of: card, matching: find.byType(MfmText)),
    );
    expect(preview.config, same(example.config));
    expect(preview.rootScale, 1.2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deep detail retains scroll and setup across the settings route',
    (
      tester,
    ) async {
      await _start(tester);
      await _open(tester, ['fn', 'special']);
      final card = find.byKey(const ValueKey('Unixtime (日本語)'));
      await tester.scrollUntilVisible(card, 250, scrollable: _detailScroll());
      await _tapSetup(
        tester,
        find.descendant(of: card, matching: find.byType(ExpansionTile)),
      );
      await _pumpTransition(tester);
      final scrollState = tester.state<ScrollableState>(_detailScroll());
      final offset = scrollState.position.pixels;
      final code = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data;
      final settings = _settings(tester);
      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await _pumpTransition(tester);
      await tester.tap(find.text('ダーク'));
      await _pumpTransition(tester);
      expect(settings.themeMode, ThemeMode.dark);
      final catSettings = find.byKey(const Key('catLanguageSettingsTile'));
      await tester.scrollUntilVisible(catSettings, 200);
      await tester.tap(catSettings);
      await _pumpTransition(tester);
      expect(find.text('猫語変換'), findsOneWidget);
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await _pumpTransition(tester);
      expect(find.byType(NavigationRail), findsNothing);
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await _pumpTransition(tester);
      await tester.binding.handlePopRoute();
      await _pumpTransition(tester);
      expect(find.byKey(const Key('catLanguageSettingsTile')), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await _pumpTransition(tester);
      expect(tester.state<ScrollableState>(_detailScroll()), same(scrollState));
      expect(scrollState.position.pixels, closeTo(offset, 1));
      expect(find.text(code!), findsOneWidget);
      expect(
        tester
            .widget<CatalogDetailList>(find.byType(CatalogDetailList))
            .page
            .id,
        'special',
      );
      await tester.binding.handlePopRoute();
      await _pumpTransition(tester);
      expect(
        tester.widget<CatalogMenuList>(find.byType(CatalogMenuList)).menu.id,
        'fn',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lazy setup panels restore independently without storage casts', (
    tester,
  ) async {
    await _start(tester);
    await _open(tester, ['fn', 'special']);
    const firstName = 'Unixtime (日本語)';
    const secondName = 'Unixtime (English・absolute)';
    final first = find.byKey(const ValueKey(firstName));
    await tester.scrollUntilVisible(first, 250, scrollable: _detailScroll());
    final firstTile = find.descendant(
      of: first,
      matching: find.byType(ExpansionTile),
    );
    await _tapSetup(tester, firstTile);
    await _pumpTransition(tester);
    final position = tester.state<ScrollableState>(_detailScroll()).position;
    final offset = position.pixels;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('Unixtime (invalid)')),
      300,
      scrollable: _detailScroll(),
    );
    await _pumpTransition(tester);
    expect(first, findsNothing);
    position.jumpTo(offset);
    await _pumpTransition(tester);
    final examples = MfmExamples.categories.expand(
      (category) => category.examples,
    );
    expect(
      find.text(examples.singleWhere((e) => e.name == firstName).setupCode!),
      findsOneWidget,
    );
    final second = find.byKey(const ValueKey(secondName));
    await tester.scrollUntilVisible(second, 250, scrollable: _detailScroll());
    expect(
      find.text(examples.singleWhere((e) => e.name == secondName).setupCode!),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iOS edge swipe can cancel and complete without stale headers',
    (
      tester,
    ) async {
      await _start(tester);
      await _open(tester, ['text']);
      final short = await tester.startGesture(const Offset(1, 350));
      await short.moveBy(const Offset(25, 0));
      await tester.pump();
      await short.moveBy(const Offset(35, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await short.up();
      await _pumpTransition(tester);
      expect(find.byType(CatalogDetailList), findsOneWidget);
      final complete = await tester.startGesture(const Offset(1, 350));
      await complete.moveBy(const Offset(25, 0));
      await tester.pump();
      await complete.moveBy(const Offset(330, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await complete.up();
      await _pumpTransition(tester);
      expect(find.byType(CatalogMenuList), findsOneWidget);
      expect(find.byType(CatalogDetailList), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('MFM Renderer'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'parent positions persist and distinct details start separately',
    (
      tester,
    ) async {
      await _start(tester);
      await tester.binding.setSurfaceSize(const Size(400, 400));
      await _pumpTransition(tester);
      final category = find.byKey(const ValueKey('catalog-node:fn'));
      await tester.scrollUntilVisible(category, 200);
      await _pumpTransition(tester);
      final categoriesScroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(CatalogMenuList),
          matching: find.byType(Scrollable),
        ),
      );
      final categoryOffset = categoriesScroll.position.pixels;
      expect(categoryOffset, greaterThan(0));
      await tester.tap(category);
      await _pumpTransition(tester);
      await _open(tester, ['special']);
      final card = find.byKey(const ValueKey('Unixtime (日本語)'));
      await tester.scrollUntilVisible(card, 250, scrollable: _detailScroll());
      await _tapSetup(
        tester,
        find.descendant(of: card, matching: find.byType(ExpansionTile)),
      );
      await _pumpTransition(tester);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        tester.state<ScrollableState>(_detailScroll()).position.pixels,
        greaterThan(0),
      );
      await tester.tap(find.byType(BackButton));
      await _pumpTransition(tester);
      await _open(tester, ['size']);
      expect(
        tester
            .widget<CatalogDetailList>(
              find.byType(CatalogDetailList),
            )
            .page
            .id,
        'size',
      );
      expect(tester.state<ScrollableState>(_detailScroll()).position.pixels, 0);
      expect(find.byType(SelectableText), findsNothing);
      await tester.tap(find.byType(BackButton));
      await _pumpTransition(tester);
      await tester.tap(find.byType(BackButton));
      await _pumpTransition(tester);
      expect(categoriesScroll.position.pixels, categoryOffset);
      expect(category.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('landscape insets and keyboard leave page controls reachable', (
    tester,
  ) async {
    await _start(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(
      left: 30,
      right: 30,
      bottom: 20,
    );
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    await tester.binding.setSurfaceSize(const Size(900, 500));
    await _pumpTransition(tester);
    await _open(tester, ['text']);
    final settings = find.byKey(const Key('openSettingsButton'));
    expect(settings.hitTestable(), findsOneWidget);
    expect(tester.getRect(settings).right, lessThanOrEqualTo(870));
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);
    await tester.tap(find.text('プレイグラウンド'));
    await _pumpTransition(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await _pumpTransition(tester);
    expect(settings.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow enlarged layout keeps indexes and detail usable', (
    tester,
  ) async {
    await _start(tester);
    await tester.binding.setSurfaceSize(const Size(360, 720));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpTransition(tester);
    await _open(tester, ['mentions']);
    final card = find.byKey(const ValueKey('Display Name'));
    await tester.scrollUntilVisible(card, 250, scrollable: _detailScroll());
    await _tapSetup(
      tester,
      find.descendant(of: card, matching: find.byType(ExpansionTile)),
    );
    await _pumpTransition(tester);
    expect(find.byType(SelectableText), findsOneWidget);
    final preview = find.descendant(of: card, matching: find.byType(MfmText));
    await Scrollable.ensureVisible(tester.element(preview), alignment: 0.5);
    await _pumpTransition(tester);
    expect(preview.hitTestable(), findsOneWidget);
    expect(tester.widget<MfmText>(preview).text, 'Alice :offline: @alice');
    expect(tester.takeException(), isNull);
  });
}
