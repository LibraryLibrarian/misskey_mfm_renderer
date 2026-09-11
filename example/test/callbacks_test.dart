import 'package:example/core/callbacks/example_callbacks.dart';
import 'package:example/core/settings/example_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  testWidgets('リンク、メンション、ハッシュタグのタップを表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final config = _config(messengerKey);

    await tester.pumpWidget(
      _callbackApp(
        messengerKey: messengerKey,
        config: config,
        text: 'https://example.org',
      ),
    );
    await tester.tap(find.byType(RichText).first);
    await tester.pump();
    expect(find.text('リンク: https://example.org'), findsOneWidget);

    await tester.pumpWidget(
      _callbackApp(
        messengerKey: messengerKey,
        config: config,
        text: '@user',
      ),
    );
    await tester.tap(find.byType(RichText).first);
    await tester.pump();
    expect(find.text('メンション: @user'), findsOneWidget);

    await tester.pumpWidget(
      _callbackApp(messengerKey: messengerKey, config: config, text: '#tag'),
    );
    await tester.tap(find.byType(RichText).first);
    await tester.pump();
    expect(
      find.text('ハッシュタグ: #tag（isNote=true, path=/tags/tag）'),
      findsOneWidget,
    );
  });

  testWidgets('isNote に応じたハッシュタグの path を表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      _callbackApp(
        messengerKey: messengerKey,
        config: _config(messengerKey),
        text: '#tag',
        isNote: false,
      ),
    );

    await tester.tap(find.byType(RichText).first);
    await tester.pump();

    expect(
      find.text('ハッシュタグ: #tag（isNote=false, path=/user-tags/tag）'),
      findsOneWidget,
    );
  });

  testWidgets('検索と clickable のタップを表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final config = _config(
      messengerKey,
      base: const MfmRenderConfig(searchButtonLabel: '検索'),
    );

    await tester.pumpWidget(
      _callbackApp(
        messengerKey: messengerKey,
        config: config,
        text: 'Misskey [検索]',
      ),
    );
    await tester.tap(find.text('検索'));
    await tester.pump();
    expect(find.text('検索: Misskey'), findsOneWidget);

    await tester.pumpWidget(
      _callbackApp(
        messengerKey: messengerKey,
        config: config,
        text: r'$[clickable.ev=hello タップ]',
      ),
    );
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(find.text('clickable: hello'), findsOneWidget);
  });
}

MfmRenderConfig _config(
  GlobalKey<ScaffoldMessengerState> messengerKey, {
  MfmRenderConfig base = const MfmRenderConfig(),
}) {
  return buildRenderConfig(
    ExampleSettings(),
    base,
    ExampleCallbacks(messengerKey),
  );
}

Widget _callbackApp({
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  required MfmRenderConfig config,
  required String text,
  bool isNote = true,
}) {
  return MaterialApp(
    scaffoldMessengerKey: messengerKey,
    home: Scaffold(
      body: MfmText(text: text, config: config, isNote: isNote),
    ),
  );
}
