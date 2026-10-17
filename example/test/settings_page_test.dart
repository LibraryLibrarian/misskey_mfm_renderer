import 'package:example/app/app.dart';
import 'package:example/app/home_page.dart';
import 'package:example/app/settings_page.dart';
import 'package:example/core/emoji/example_startup.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

Future<void> _pumpTransition(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ExampleSettings> _start(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MfmExampleApp(emojiStatus: ExampleEmojiStatus.online),
  );
  await _pumpTransition(tester);
  final settings = ExampleSettingsScope.of(
    tester.element(find.byType(HomePage)),
  );
  await tester.tap(find.byKey(const Key('openSettingsButton')));
  await _pumpTransition(tester);
  return settings;
}

Finder _scroll() => find.descendant(
  of: find.byKey(const PageStorageKey('settings-scroll')),
  matching: find.byType(Scrollable),
);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _scroll());
  await _pumpTransition(tester);
  expect(finder.hitTestable(), findsOneWidget);
}

List<Object> _values(ExampleSettings settings) => [
  settings.themeMode,
  settings.useCustomColorScheme,
  settings.enableAdvancedMfm,
  settings.enableAnimation,
  settings.showCodeBlockCopyButton,
  settings.nyaizeMode,
  settings.authorIsCat,
  settings.remoteAuthor,
  settings.useEmojiUrls,
  settings.showEmojiContext,
  settings.rootScale,
  settings.plain,
  settings.nowrap,
  settings.isNote,
];

void _changeAll(ExampleSettings settings) {
  settings
    ..themeMode = ThemeMode.dark
    ..useCustomColorScheme = true
    ..enableAdvancedMfm = false
    ..enableAnimation = false
    ..showCodeBlockCopyButton = false
    ..nyaizeMode = MfmNyaizeMode.respectAuthor
    ..authorIsCat = true
    ..remoteAuthor = true
    ..useEmojiUrls = true
    ..showEmojiContext = true
    ..rootScale = 2
    ..plain = true
    ..nowrap = true
    ..isNote = false;
}

void main() {
  testWidgets('all 14 controls update shared settings before leaving', (
    tester,
  ) async {
    final settings = await _start(tester);
    final pageState = tester.state(find.byType(SettingsPage));
    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('openSettingsButton')), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.text('ダーク'));
    await _pumpTransition(tester);
    expect(settings.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );

    for (final entry in <(String, bool Function(), bool)>[
      ('useCustomColorScheme', () => settings.useCustomColorScheme, true),
      ('enableAdvancedMfm', () => settings.enableAdvancedMfm, false),
      ('enableAnimation', () => settings.enableAnimation, false),
      (
        'showCodeBlockCopyButton',
        () => settings.showCodeBlockCopyButton,
        false,
      ),
    ]) {
      final control = find.byKey(Key('${entry.$1}Switch'));
      await _reveal(tester, control);
      await tester.tap(control);
      await tester.pump();
      expect(entry.$2(), entry.$3);
    }
    expect(
      MfmConfig.of(tester.element(find.byType(SettingsPage))).enableAdvancedMfm,
      isFalse,
    );
    await _reveal(tester, find.text('投稿者'));
    await tester.tap(find.text('投稿者'));
    await tester.pump();
    expect(settings.nyaizeMode, MfmNyaizeMode.respectAuthor);
    for (final entry in <(String, bool Function())>[
      ('authorIsCat', () => settings.authorIsCat),
      ('remoteAuthor', () => settings.remoteAuthor),
      ('useEmojiUrls', () => settings.useEmojiUrls),
      ('showEmojiContext', () => settings.showEmojiContext),
    ]) {
      final control = find.byKey(Key('${entry.$1}Switch'));
      await _reveal(tester, control);
      await tester.tap(control);
      await tester.pump();
      expect(entry.$2(), isTrue);
    }
    final scale = find.byKey(const Key('rootScaleDropdown'));
    await _reveal(tester, scale);
    await tester.tap(scale);
    await _pumpTransition(tester);
    await tester.tap(find.text('2.0').last);
    await _pumpTransition(tester);
    expect(settings.rootScale, 2);
    for (final entry in <(String, bool Function(), bool)>[
      ('plain', () => settings.plain, true),
      ('nowrap', () => settings.nowrap, true),
      ('isNote', () => settings.isNote, false),
    ]) {
      final control = find.byKey(Key('${entry.$1}Switch'));
      await _reveal(tester, control);
      await tester.tap(control);
      await tester.pump();
      expect(entry.$2(), entry.$3);
    }
    expect(tester.state(find.byType(SettingsPage)), same(pageState));
    await _reveal(tester, find.byKey(const Key('resetSettingsButton')));
    final position = tester.state<ScrollableState>(_scroll()).position;
    final offset = position.pixels;
    await tester.tap(find.byKey(const Key('resetSettingsButton')));
    await _pumpTransition(tester);
    await tester.tap(find.widgetWithText(FilledButton, '既定値に戻す'));
    await _pumpTransition(tester);
    final defaults = ExampleSettings();
    addTearDown(defaults.dispose);
    expect(_values(settings), _values(defaults));
    expect(tester.state(find.byType(SettingsPage)), same(pageState));
    expect(position.pixels, closeTo(offset, 1));
    expect(tester.takeException(), isNull);
  });

  for (final dismissal in ['cancel', 'back', 'barrier']) {
    testWidgets('reset $dismissal keeps all values and the settings route', (
      tester,
    ) async {
      final settings = await _start(tester);
      _changeAll(settings);
      await _pumpTransition(tester);
      final before = _values(settings);
      final reset = find.byKey(const Key('resetSettingsButton'));
      await _reveal(tester, reset);
      final open = tester.widget<OutlinedButton>(reset).onPressed!;
      open();
      open();
      await _pumpTransition(tester);
      expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
      switch (dismissal) {
        case 'cancel':
          await tester.tap(find.text('キャンセル'));
        case 'back':
          await tester.binding.handlePopRoute();
        case 'barrier':
          await tester.tapAt(const Offset(5, 5));
      }
      await _pumpTransition(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(_values(settings), before);
      await tester.tap(reset);
      await _pumpTransition(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await _pumpTransition(tester);
      await tester.binding.handlePopRoute();
      await _pumpTransition(tester);
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(_values(settings), before);
    });
  }

  testWidgets('opening repeatedly pushes one route and can reopen after back', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.byType(BackButton));
    await _pumpTransition(tester);
    final open = tester
        .widget<IconButton>(find.byKey(const Key('openSettingsButton')))
        .onPressed!;
    open();
    open();
    open();
    await _pumpTransition(tester);
    expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(find.byType(SettingsPage, skipOffstage: false), findsNothing);
    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await _pumpTransition(tester);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disposing with reset confirmation pending does not mutate settings',
    (tester) async {
      final settings = ExampleSettings()..plain = true;
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ExampleSettingsScope(
          settings: settings,
          child: const MaterialApp(
            home: SettingsPage(emojiStatus: ExampleEmojiStatus.offline),
          ),
        ),
      );
      await _reveal(tester, find.byKey(const Key('resetSettingsButton')));
      await tester.tap(find.byKey(const Key('resetSettingsButton')));
      await _pumpTransition(tester);
      await tester.pumpWidget(const SizedBox());
      await _pumpTransition(tester);
      expect(settings.plain, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final bottomInset in [24.0, 34.0]) {
    testWidgets(
      'settings scroll behind bottom inset $bottomInset '
      'with a safe reset button',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(bottom: bottomInset);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await _start(tester);

        final list = find.byKey(const PageStorageKey('settings-scroll'));
        expect(tester.getRect(list).bottom, 800);
        expect(
          tester.widget<ListView>(list).padding,
          EdgeInsets.only(bottom: 24 + bottomInset),
        );
        final headingTop = tester.getTopLeft(find.text('外観')).dy;
        tester.view.padding = FakeViewPadding.zero;
        await _pumpTransition(tester);
        expect(tester.getTopLeft(find.text('外観')).dy, headingTop);
        tester.view.padding = FakeViewPadding(bottom: bottomInset);
        await _pumpTransition(tester);

        final reset = find.byKey(const Key('resetSettingsButton'));
        await _reveal(tester, reset);
        final position = tester.state<ScrollableState>(_scroll()).position;
        position.jumpTo(position.maxScrollExtent);
        await _pumpTransition(tester);
        expect(tester.getRect(list).bottom, 800);
        expect(
          tester.getRect(reset).bottom,
          closeTo(800 - bottomInset - 24, 1),
        );
        expect(reset.hitTestable(), findsOneWidget);
        await tester.tap(reset);
        await _pumpTransition(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  for (final layout in [
    (size: const Size(320, 720), scale: 2.0, insets: false),
    (size: const Size(1200, 800), scale: 1.0, insets: false),
    (size: const Size(900, 500), scale: 1.0, insets: true),
  ]) {
    testWidgets(
      'settings remain reachable at ${layout.size} and scale ${layout.scale}',
      (tester) async {
        await _start(tester);
        await tester.binding.setSurfaceSize(layout.size);
        tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        if (layout.insets) {
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(
            left: 30,
            right: 30,
            bottom: 20,
          );
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);
        }
        await _pumpTransition(tester);
        final body = tester.getRect(
          find.byKey(const PageStorageKey('settings-scroll')),
        );
        expect(body.width, lessThanOrEqualTo(720));
        expect(body.center.dx, closeTo(layout.size.width / 2, 1));
        expect(body.bottom, layout.size.height);
        if (layout.insets) {
          expect(body.left, greaterThanOrEqualTo(30));
          expect(body.right, lessThanOrEqualTo(layout.size.width - 30));
        }
        final direction = tester
            .widget<SegmentedButton<ThemeMode>>(
              find.byType(SegmentedButton<ThemeMode>),
            )
            .direction;
        expect(direction, layout.scale == 2 ? Axis.vertical : Axis.horizontal);
        for (final title in [
          '外観',
          'MFMの描画',
          '投稿者・猫変換',
          'カスタム絵文字',
          'MfmTextの表示・動作',
        ]) {
          final heading = find.text(title);
          await _reveal(tester, heading);
          expect(
            find.ancestor(
              of: heading,
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.header == true,
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
        await _reveal(tester, find.byKey(const Key('resetSettingsButton')));
        await tester.tap(find.byKey(const Key('resetSettingsButton')));
        await _pumpTransition(tester);
        expect(
          find.widgetWithText(FilledButton, '既定値に戻す').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'iOS settings edge swipe cancels and completes normally',
    (tester) async {
      await _start(tester);
      final short = await tester.startGesture(const Offset(1, 350));
      await short.moveBy(const Offset(25, 0));
      await tester.pump();
      await short.moveBy(const Offset(35, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await short.up();
      await _pumpTransition(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      final complete = await tester.startGesture(const Offset(1, 350));
      await complete.moveBy(const Offset(25, 0));
      await tester.pump();
      await complete.moveBy(const Offset(330, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await complete.up();
      await _pumpTransition(tester);
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
