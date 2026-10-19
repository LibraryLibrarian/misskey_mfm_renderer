import 'dart:ui' as ui;

import 'package:example/app/app.dart';
import 'package:example/app/cat_language_settings_page.dart';
import 'package:example/app/home_page.dart';
import 'package:example/app/settings_page.dart';
import 'package:example/core/emoji/example_startup.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

final Finder _entry = find.byKey(const Key('catLanguageSettingsTile'));
final Finder _author = find.byKey(const Key('authorIsCatSwitch'));
final Finder _explanation = find.byKey(const Key('catLanguageExplanation'));

Finder _scroll({bool detail = true}) => find.descendant(
  of: find.byKey(
    PageStorageKey(detail ? 'cat-language-scroll' : 'settings-scroll'),
  ),
  matching: find.byType(Scrollable),
);

Future<void> _pumpTransition(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  bool detail = true,
}) async {
  tester.state<ScrollableState>(_scroll(detail: detail)).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: _scroll(detail: detail),
  );
  await _pumpTransition(tester);
  expect(target.hitTestable(), findsOneWidget);
}

Future<ExampleSettings> _start(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MfmExampleApp(emojiStatus: ExampleEmojiStatus.offline),
  );
  await _pumpTransition(tester);
  final settings = ExampleSettingsScope.of(
    tester.element(find.byType(HomePage)),
  );
  await tester.tap(find.byKey(const Key('openSettingsButton')));
  await _pumpTransition(tester);
  await _reveal(tester, _entry, detail: false);
  return settings;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_entry);
  await _pumpTransition(tester);
  expect(find.byType(CatLanguageSettingsPage), findsOneWidget);
}

Future<void> _select(WidgetTester tester, String key) async {
  final option = find.byKey(Key(key));
  await _reveal(tester, option);
  await tester.tap(option);
  await _pumpTransition(tester);
}

void main() {
  testWidgets('explained modes update shared config and parent summaries', (
    tester,
  ) async {
    final settings = await _start(tester);
    final parent = tester.state(find.byType(SettingsPage));
    final position = tester
        .state<ScrollableState>(_scroll(detail: false))
        .position;
    final offset = position.pixels;
    expect(tester.widget<ListTile>(_entry).subtitle, isA<Text>());
    expect((tester.widget<ListTile>(_entry).subtitle! as Text).data, '変換しない');
    await _open(tester);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('openSettingsButton')), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(RadioListTile<MfmNyaizeMode>), findsNWidgets(3));
    expect(find.text('投稿者の猫設定に関係なく、変換しません。'), findsOneWidget);
    expect(find.text('投稿者の猫設定に関係なく、変換します。'), findsOneWidget);
    expect(find.text('猫設定が有効な投稿者の文章だけ変換します。'), findsOneWidget);
    expect(settings.nyaizeMode, MfmNyaizeMode.disabled);
    expect(tester.widget<SwitchListTile>(_author).onChanged, isNull);

    for (final entry in [
      ('nyaizeEnabledRadio', MfmNyaizeMode.enabled, '常に変換'),
      ('nyaizeRespectAuthorRadio', MfmNyaizeMode.respectAuthor, '投稿者に従う'),
      ('nyaizeDisabledRadio', MfmNyaizeMode.disabled, '変換しない'),
    ]) {
      await _select(tester, entry.$1);
      expect(settings.nyaizeMode, entry.$2);
      expect(
        MfmConfig.of(
          tester.element(find.byType(CatLanguageSettingsPage)),
        ).nyaizeMode,
        entry.$2,
      );
      await tester.tap(find.byType(BackButton));
      await _pumpTransition(tester);
      expect(tester.state(find.byType(SettingsPage)), same(parent));
      expect(position.pixels, closeTo(offset, 1));
      expect(
        (tester.widget<ListTile>(_entry).subtitle! as Text).data,
        entry.$3,
      );
      await _open(tester);
    }
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(CatLanguageSettingsPage), findsNothing);
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('author switch retains its value while disabled in other modes', (
    tester,
  ) async {
    final settings = await _start(tester);
    await _open(tester);
    await _select(tester, 'nyaizeRespectAuthorRadio');
    await _reveal(tester, _author);
    await tester.tap(_author);
    await _pumpTransition(tester);
    expect(settings.authorIsCat, isTrue);
    expect(
      MfmConfig.of(
        tester.element(find.byType(CatLanguageSettingsPage)),
      ).author!.isCat,
      isTrue,
    );
    for (final key in ['nyaizeEnabledRadio', 'nyaizeDisabledRadio']) {
      await _select(tester, key);
      await _reveal(tester, _author);
      expect(tester.widget<SwitchListTile>(_author).onChanged, isNull);
      expect(tester.widget<SwitchListTile>(_author).value, isTrue);
      expect(find.text('「投稿者に従う」を選ぶと変更できます。'), findsOneWidget);
      await tester.tap(_author);
      await tester.pump();
      expect(settings.authorIsCat, isTrue);
    }
    await _select(tester, 'nyaizeRespectAuthorRadio');
    await _reveal(tester, _author);
    expect(tester.widget<SwitchListTile>(_author).onChanged, isNotNull);
    expect(tester.widget<SwitchListTile>(_author).value, isTrue);
    await tester.tap(_author);
    await tester.pump();
    expect(settings.authorIsCat, isFalse);
  });

  testWidgets(
    'detail exposes radio, switch, heading and explanation semantics',
    (
      tester,
    ) async {
      await _start(tester);
      await _open(tester);
      final disabledRadio = tester
          .getSemantics(find.byKey(const Key('nyaizeDisabledRadio')))
          .getSemanticsData();
      expect(disabledRadio.flagsCollection.isChecked, ui.CheckedState.isTrue);
      expect(disabledRadio.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      await _reveal(tester, _author);
      final disabledAuthor = tester.getSemantics(_author).getSemanticsData();
      expect(disabledAuthor.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(disabledAuthor.flagsCollection.isToggled, ui.Tristate.isFalse);
      final heading = tester
          .getSemantics(find.text('サンプルの投稿者'))
          .getSemanticsData();
      expect(heading.flagsCollection.isHeader, isTrue);
      await _select(tester, 'nyaizeRespectAuthorRadio');
      final respectAuthorRadio = tester
          .getSemantics(find.byKey(const Key('nyaizeRespectAuthorRadio')))
          .getSemanticsData();
      expect(
        respectAuthorRadio.flagsCollection.isChecked,
        ui.CheckedState.isTrue,
      );
      expect(
        respectAuthorRadio.flagsCollection.isInMutuallyExclusiveGroup,
        isTrue,
      );
      await _reveal(tester, _author);
      await tester.tap(_author);
      await tester.pump();
      final enabledAuthor = tester.getSemantics(_author).getSemanticsData();
      expect(enabledAuthor.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(enabledAuthor.flagsCollection.isToggled, ui.Tristate.isTrue);
      await _reveal(tester, _explanation);
      final explanation = tester.getSemantics(_explanation).getSemanticsData();
      expect(explanation.label, tester.widget<Text>(_explanation).data);
    },
  );

  testWidgets('repeated entry pushes once and allows reopening after pop', (
    tester,
  ) async {
    await _start(tester);
    final open = tester.widget<ListTile>(_entry).onTap!;
    open();
    open();
    open();
    await _pumpTransition(tester);
    expect(
      find.byType(CatLanguageSettingsPage, skipOffstage: false),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await _pumpTransition(tester);
    expect(
      find.byType(CatLanguageSettingsPage, skipOffstage: false),
      findsNothing,
    );
    await _open(tester);
  });

  testWidgets('parent reset restores detail defaults when reopened', (
    tester,
  ) async {
    final settings = await _start(tester);
    await _open(tester);
    await _select(tester, 'nyaizeRespectAuthorRadio');
    await _reveal(tester, _author);
    await tester.tap(_author);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await _pumpTransition(tester);
    final reset = find.byKey(const Key('resetSettingsButton'));
    await _reveal(tester, reset, detail: false);
    await tester.tap(reset);
    await _pumpTransition(tester);
    await tester.tap(find.widgetWithText(FilledButton, '既定値に戻す'));
    await _pumpTransition(tester);
    expect(settings.nyaizeMode, MfmNyaizeMode.disabled);
    expect(settings.authorIsCat, isFalse);
    await _reveal(tester, _entry, detail: false);
    expect((tester.widget<ListTile>(_entry).subtitle! as Text).data, '変換しない');
    await _open(tester);
    expect(
      tester
          .widget<RadioGroup<MfmNyaizeMode>>(
            find.byType(RadioGroup<MfmNyaizeMode>),
          )
          .groupValue,
      MfmNyaizeMode.disabled,
    );
    expect(tester.widget<SwitchListTile>(_author).value, isFalse);
    expect(tester.widget<SwitchListTile>(_author).onChanged, isNull);
  });

  for (final layout in [
    (size: const Size(320, 720), scale: 2.0, insets: false),
    (size: const Size(1200, 800), scale: 1.0, insets: false),
    (size: const Size(900, 500), scale: 1.0, insets: true),
  ]) {
    testWidgets('detail layout ${layout.size} at scale ${layout.scale}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.padding = layout.insets
          ? const FakeViewPadding(left: 30, right: 30, bottom: 20)
          : FakeViewPadding.zero;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _start(tester, size: layout.size);
      await _open(tester);
      final list = find.byKey(const PageStorageKey('cat-language-scroll'));
      final rect = tester.getRect(list);
      expect(rect.width, lessThanOrEqualTo(720));
      expect(rect.center.dx, closeTo(layout.size.width / 2, 1));
      expect(rect.bottom, layout.size.height);
      if (layout.insets) {
        expect(rect.left, greaterThanOrEqualTo(30));
        expect(rect.right, lessThanOrEqualTo(layout.size.width - 30));
      }
      expect(
        tester.widget<ListView>(list).padding,
        EdgeInsets.only(bottom: 24 + (layout.insets ? 20 : 0)),
      );
      await _select(tester, 'nyaizeRespectAuthorRadio');
      await _reveal(tester, _author);
      await tester.tap(_author);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(_author).value, isTrue);
      await _reveal(tester, _explanation);
      final position = tester.state<ScrollableState>(_scroll()).position;
      position.jumpTo(position.maxScrollExtent);
      await _pumpTransition(tester);
      expect(
        tester.getRect(_explanation).bottom,
        lessThanOrEqualTo(layout.size.height - 24 - (layout.insets ? 20 : 0)),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final inset in [24.0, 34.0]) {
    testWidgets(
      'detail extends behind bottom inset $inset with safe trailing padding',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(bottom: inset);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await _start(tester);
        await _open(tester);
        final list = find.byKey(const PageStorageKey('cat-language-scroll'));
        expect(tester.getRect(list).bottom, 800);
        expect(
          tester.widget<ListView>(list).padding,
          EdgeInsets.only(bottom: 24 + inset),
        );
        await _reveal(tester, _explanation);
        final position = tester.state<ScrollableState>(_scroll()).position;
        position.jumpTo(position.maxScrollExtent);
        await _pumpTransition(tester);
        expect(
          tester.getRect(_explanation).bottom,
          lessThanOrEqualTo(776 - inset),
        );
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  testWidgets(
    'iOS back swipe cancels or returns only one settings level',
    (tester) async {
      await _start(tester);
      await _open(tester);
      final short = await tester.startGesture(const Offset(1, 350));
      await short.moveBy(const Offset(25, 0));
      await tester.pump();
      await short.moveBy(const Offset(35, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await short.up();
      await _pumpTransition(tester);
      expect(find.byType(CatLanguageSettingsPage), findsOneWidget);
      for (var level = 0; level < 2; level++) {
        final complete = await tester.startGesture(const Offset(1, 350));
        await complete.moveBy(const Offset(25, 0));
        await tester.pump();
        await complete.moveBy(const Offset(330, 0));
        await tester.pump(const Duration(milliseconds: 300));
        await complete.up();
        await _pumpTransition(tester);
        expect(find.byType(CatLanguageSettingsPage), findsNothing);
        expect(
          find.byType(SettingsPage),
          level == 0 ? findsOneWidget : findsNothing,
        );
      }
      expect(find.byType(HomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
