import 'package:example/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('アプリが起動しカタログとプレイグラウンドのタブを表示する', (
    tester,
  ) async {
    await tester.pumpWidget(const MfmExampleApp());
    await tester.pump();

    expect(find.text('MFM Renderer'), findsOneWidget);
    expect(find.text('カタログ'), findsOneWidget);
    expect(find.text('プレイグラウンド'), findsOneWidget);
    expect(find.text('テキスト整形'), findsOneWidget);
  });
}
