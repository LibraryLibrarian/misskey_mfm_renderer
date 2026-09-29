import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const ValueKey<String> _boundaryKey = ValueKey('emoji-fallback-golden');
const _style = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 20,
  height: 1,
  color: Color(0x800000FF),
);

Widget _sample(String text, {bool plain = false, double? emojiSize}) => MfmText(
  text: text,
  plain: plain,
  config: MfmEmojiConfig.fromResolver(
    resolver: (_) async => null,
    emojiSize: emojiSize,
  ).copyWith(baseTextStyle: _style, enableAnimation: false),
);

void main() {
  testWidgets('missing emoji uses the surrounding text size and baseline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: _style,
          child: Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  width: 600,
                  height: 580,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Literal shortcode without a helper: 1em reference.
                        const MfmText(
                          text: 'A :missing: B',
                          config: MfmRenderConfig(baseTextStyle: _style),
                        ),
                        _sample('A :missing: B'),
                        _sample('A :missing: B', plain: true),
                        _sample('A :missing: B', emojiSize: 72),
                        _sample(r'$[x2 A :missing: B]'),
                        _sample('<small>A :missing: B</small>'),
                        _sample(
                          r'<small>$[fg.color=ff000080 A :missing: B]</small>',
                        ),
                        _sample('**<i>~~A :missing: B~~</i>**'),
                        _sample('> <small>A :missing: B</small>'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(_boundaryKey),
      matchesGoldenFile('goldens/emoji_fallback.png'),
    );
  }, tags: 'golden');
}
