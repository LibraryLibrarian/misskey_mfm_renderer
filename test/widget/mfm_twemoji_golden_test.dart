import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const _capture = Key('twemoji-golden');
const _assetNames = [
  '1f600.png',
  '2764.png',
  '31-20e3.png',
  '1f3f3-fe0f-200d-1f308.png',
  '1f44d-1f3fd.png',
  '1f1ef-1f1f5.png',
  '1f469-200d-2695-fe0f.png',
  '1f3f4-e0067-e0062-e0065-e006e-e0067-e007f.png',
];

void main() {
  testWidgets('opt-in Twemoji composition', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final images = <String, MemoryImage>{};
    await tester.runAsync(() async {
      for (final name in _assetNames) {
        images[name] = MemoryImage(
          await File('example/assets/twemoji/$name').readAsBytes(),
        );
      }
    });
    final twemoji = MfmTwemojiBuilder(imageProvider: (name) => images[name]);
    final config = MfmRenderConfig(
      unicodeEmojiBuilder: twemoji.build,
      enableAnimation: false,
      brightness: Brightness.light,
      baseTextStyle: const TextStyle(
        fontFamily: 'Ahem',
        fontSize: 20,
        height: 1.3,
        color: Color(0xFF202020),
      ),
    );
    Widget row(
      String label,
      String text, {
      bool plain = false,
      bool nowrap = false,
      double width = 552,
      MfmRenderConfig? override,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Ahem', fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: width,
            child: MfmText(
              text: text,
              config: override ?? config,
              plain: plain,
              nowrap: nowrap,
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Ahem',
              fontSize: 20,
              color: Color(0xFF202020),
            ),
            child: Center(
              child: RepaintBoundary(
                key: _capture,
                child: ColoredBox(
                  color: const Color(0xFFFFFFFF),
                  child: SizedBox(
                    width: 600,
                    height: 1040,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          row(
                            '1. All bundled sequences',
                            'Abg 😀 ❤️ 1️⃣ 🏳️‍🌈 👍🏽 🇯🇵 👩‍⚕️ '
                                '\u{1f3f4}\u{e0067}\u{e0062}\u{e0065}'
                                '\u{e006e}\u{e0067}\u{e007f} Abg',
                          ),
                          row('2. Enlarged x2', r'Abg $[x2 😀 ❤️] Abg'),
                          row('3. Small', '<small>Abg 😀 ❤️ Abg</small>'),
                          row(
                            '4. Quote and small',
                            '> <small>Abg 😀 ❤️ Abg</small>',
                          ),
                          row(
                            '5. Explicit foreground',
                            r'$[fg.color=ff0000 Abg 😀 ❤️]',
                          ),
                          row('6. Static rainbow', r'$[rainbow Abg 😀 ❤️ Abg]'),
                          row('7. Plain mode', 'Abg 😀 ❤️ Abg', plain: true),
                          row(
                            '8. Narrow wrapping',
                            'Abg 😀 ❤️ 1️⃣ Abg 😀 ❤️ Abg',
                            width: 180,
                          ),
                          row(
                            '9. Narrow nowrap',
                            'Abg 😀 ❤️ 1️⃣ Abg 😀 ❤️ Abg',
                            width: 180,
                            nowrap: true,
                          ),
                          row(
                            '10. Translucent inherited text',
                            '<small>Abg 😀 ❤️ Abg</small>',
                            override: config.copyWith(
                              baseTextStyle: const TextStyle(
                                fontFamily: 'Ahem',
                                fontSize: 20,
                                color: Color(0x80202020),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(MfmText).first);
    await tester.runAsync(() async {
      for (final image in images.values) {
        await precacheImage(image, context);
      }
    });
    await tester.pumpAndSettle();
    final decoded = tester.widgetList<RawImage>(find.byType(RawImage)).toList();
    final firstRow = find.descendant(
      of: find.byType(MfmText).first,
      matching: find.byType(RawImage),
    );
    expect(firstRow, findsNWidgets(_assetNames.length));
    expect(decoded.every((image) => image.image != null), isTrue);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(_capture),
      matchesGoldenFile('goldens/twemoji.png'),
    );
  }, tags: ['golden']);
}
