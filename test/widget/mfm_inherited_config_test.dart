import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  testWidgets('MfmConfig.of returns inherited config', (tester) async {
    const inherited = MfmRenderConfig(
      enableAdvancedMfm: false,
      enableAnimation: false,
    );
    late MfmRenderConfig found;

    await tester.pumpWidget(
      MfmConfig(
        config: inherited,
        child: Builder(
          builder: (context) {
            found = MfmConfig.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(identical(found, inherited), isTrue);
  });

  testWidgets('MfmText uses inherited config when explicit is default', (
    tester,
  ) async {
    const inherited = MfmRenderConfig(
      emojiBuilder: _emojiTextBuilder,
    );

    await tester.pumpWidget(
      MfmConfig(
        config: inherited,
        child: const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: ':emoji:',
              simple: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('inherited'), findsOneWidget);
  });

  testWidgets('MfmText merges inherited and explicit config', (tester) async {
    const inherited = MfmRenderConfig(
      emojiBuilder: _emojiTextBuilder,
    );

    final explicit = MfmRenderConfig(
      onLinkTap: (_) {},
    );

    await tester.pumpWidget(
      MfmConfig(
        config: inherited,
        child: MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: ':emoji:',
              simple: true,
              config: explicit,
            ),
          ),
        ),
      ),
    );

    expect(find.text('inherited'), findsOneWidget);
  });

  testWidgets('explicit emojiBuilder overrides inherited', (tester) async {
    const inherited = MfmRenderConfig(
      emojiBuilder: _emojiTextBuilder,
    );

    const explicit = MfmRenderConfig(
      emojiBuilder: _emojiTextBuilderExplicit,
    );

    await tester.pumpWidget(
      MfmConfig(
        config: inherited,
        child: const MaterialApp(
          home: Scaffold(
            body: MfmText(
              text: ':emoji:',
              simple: true,
              config: explicit,
            ),
          ),
        ),
      ),
    );

    expect(find.text('explicit'), findsOneWidget);
  });
}

Widget _emojiTextBuilder(String _) => const Text('inherited');

Widget _emojiTextBuilderExplicit(String _) => const Text('explicit');
