import 'package:example/app/app.dart';
import 'package:example/app/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  testWidgets('アプリが起動しカタログとプレイグラウンドを表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MfmExampleApp());
    await tester.pump();

    expect(find.text('MFM Renderer'), findsOneWidget);
    expect(find.text('カタログ'), findsOneWidget);
    expect(find.text('プレイグラウンド'), findsOneWidget);
    expect(find.text('テキスト整形'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);

    await tester.tap(find.text('プレイグラウンド'));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('設定ドロワーから Advanced MFM を切り替える', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MfmExampleApp());
    await tester.pump();

    await tester.tap(find.byKey(const Key('openSettingsDrawerButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('表示設定'), findsOneWidget);

    await tester.tap(find.byKey(const Key('enableAdvancedMfmSwitch')));
    await tester.pump();

    final homeContext = tester.element(find.byType(HomePage));
    expect(MfmConfig.of(homeContext).enableAdvancedMfm, isFalse);
  });

  testWidgets('幅に応じてナビゲーションを切り替える', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    await tester.pumpWidget(const MfmExampleApp());
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pump();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
