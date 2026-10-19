import 'package:example/app/app.dart';
import 'package:example/app/settings_page.dart';
import 'package:example/core/emoji/example_startup.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  test('offline never calls the online initializer', () async {
    var calls = 0;
    final result = await resolveExampleStartup(
      offline: true,
      online: () {
        calls++;
        throw StateError('must not initialize');
      },
    );
    expect(calls, 0);
    expect(result.status, ExampleEmojiStatus.offline);
    expect(result.config, isNull);
    expect(result.error, isNull);
  });

  test(
    'online forwards config and distinguishes initialization failure',
    () async {
      const config = MfmRenderConfig(localHost: 'local.test');
      var calls = 0;
      final result = await resolveExampleStartup(
        offline: false,
        online: () async {
          calls++;
          return config;
        },
      );
      expect(calls, 1);
      expect(result.config, same(config));
      expect(result.status, ExampleEmojiStatus.online);
      final error = Exception('initialization failed');
      final failed = await resolveExampleStartup(
        offline: false,
        online: () async => throw error,
      );
      expect(failed.status, ExampleEmojiStatus.failed);
      expect(failed.config, isNull);
      expect(failed.error, same(error));
    },
  );

  for (final status in ExampleEmojiStatus.values) {
    testWidgets('settings distinguishes $status and gates online controls', (
      tester,
    ) async {
      final settings = ExampleSettings();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ExampleSettingsScope(
          settings: settings,
          child: MaterialApp(home: SettingsPage(emojiStatus: status)),
        ),
      );
      final expected = switch (status) {
        ExampleEmojiStatus.online => '同期済み',
        ExampleEmojiStatus.offline => 'オフライン起動',
        ExampleEmojiStatus.failed => '初期化に失敗',
      };
      await tester.scrollUntilVisible(find.textContaining(expected), 300);
      expect(find.textContaining(expected), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('emojiUrls を渡す'),
        300,
      );
      for (final label in ['リモート投稿として扱う', 'emojiUrls を渡す']) {
        final tile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, label),
        );
        expect(tile.onChanged != null, status == ExampleEmojiStatus.online);
      }
    });
  }

  testWidgets('app forwards explicit offline status', (tester) async {
    await tester.pumpWidget(
      const MfmExampleApp(emojiStatus: ExampleEmojiStatus.offline),
    );
    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(find.textContaining('オフライン起動'), 300);
    expect(find.textContaining('オフライン起動'), findsOneWidget);
  });
}
