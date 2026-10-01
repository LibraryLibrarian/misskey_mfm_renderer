import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

const ValueKey<String> _boundary = ValueKey('mentions');
const _style = TextStyle(
  fontFamily: 'Ahem',
  fontSize: 20,
  height: 1,
  color: Color(0xFF202020),
);
const _colors = MfmColorScheme.light(
  mention: Color(0xCC165DAD),
  mentionMe: Color(0xFFE05932),
);

Future<MemoryImage> _avatar() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawColor(const Color(0xFF16B7A7), BlendMode.src)
    ..drawRect(
      const Rect.fromLTWH(0, 0, 16, 32),
      Paint()..color = const Color(0xFF174577),
    );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(32, 32);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return MemoryImage(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

void main() {
  testWidgets('mention presentation, style and constrained layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final avatar = (await tester.runAsync(_avatar))!;
    final config = MfmRenderConfig(
      baseTextStyle: _style,
      localHost: 'local.test',
      brightness: Brightness.light,
      lightColorScheme: _colors,
      enableAnimation: false,
      mentionOptions: MfmMentionOptions(
        viewerAcct: '@me',
        avatarProvider: (_) => avatar,
      ),
    );
    Widget row(
      String text, {
      MfmRenderConfig? override,
      double width = 560,
      double height = 62,
      double textScale = 1,
    }) => SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: MfmText(text: text, config: override ?? config),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: _style,
          child: Center(
            child: RepaintBoundary(
              key: _boundary,
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: SizedBox(
                  width: 600,
                  height: 860,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        row('a @bob@local.test z'),
                        row('a @bob@remote.test z'),
                        row('a @me z'),
                        row(
                          'a @bob z',
                          override: config.copyWith(
                            author: const MfmAuthorContext(host: 'remote.test'),
                          ),
                        ),
                        row(
                          'a @bob@remote.test z',
                          override: config.copyWith(
                            mentionOptions: const MfmMentionOptions(),
                          ),
                        ),
                        row(
                          'a @bob@remote.test z',
                          override: config.copyWith(
                            mentionOptions: const MfmMentionOptions(
                              presentation: MfmMentionPresentation.text,
                            ),
                          ),
                        ),
                        row('<small>@bob@remote.test</small>'),
                        row('> <small>@bob@remote.test</small>', height: 82),
                        row(r'$[fg.color=ff0000 @bob@remote.test]'),
                        row('@very_long_username@remote.test', width: 180),
                        row('@me', textScale: 2, height: 90),
                        row(
                          '**@bob@remote.test**',
                          override: config.copyWith(
                            baseTextStyle: _style.copyWith(
                              fontStyle: FontStyle.italic,
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
    );
    await tester.runAsync(
      () => precacheImage(avatar, tester.element(find.byKey(_boundary))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final images = tester.widgetList<RawImage>(find.byType(RawImage));
    expect(images, hasLength(10));
    expect(images.every((image) => image.image != null), isTrue);
    await expectLater(
      find.byKey(_boundary),
      matchesGoldenFile('goldens/mentions.png'),
    );
  }, tags: 'golden');
}
