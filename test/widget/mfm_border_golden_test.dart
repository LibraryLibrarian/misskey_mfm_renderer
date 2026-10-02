import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// Generate/compare only in the project's fixed Linux amd64 / Flutter 3.38.7
// golden environment. Do not create a macOS-specific reference image.
void main() {
  testWidgets('border styles, radii, RGBA and clipping', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const boundary = ValueKey('borders');
    const config = MfmRenderConfig(
      baseTextStyle: TextStyle(
        fontFamily: 'Ahem',
        fontSize: 20,
        height: 1,
        color: Color(0xFF202020),
      ),
      brightness: Brightness.light,
      enableAnimation: false,
      lightColorScheme: MfmColorScheme.light(accent: Color(0xFF286BAA)),
    );
    final rows = [
      for (final style in [
        'hidden',
        'dotted',
        'dashed',
        'solid',
        'double',
        'groove',
        'ridge',
        'inset',
        'outset',
      ])
        // ignore: no_adjacent_strings_in_list
        '\$[border.style=$style,width=6,radius=14 $style] '
            '\$[border.style=$style,width=6,color=f008 RGBA]',
      // ignore: no_adjacent_strings_in_list
      r'$[border.width=2,style=double thin] '
          r'$[border.width=3,style=double double]',
      // ignore: no_adjacent_strings_in_list
      r'$[border.width=0 zero] $[border.width=12abc prefix] '
          r'$[border.color=abcde invalid]',
      // ignore: no_adjacent_strings_in_list
      r'$[border.width=6,radius=30 $[bg.color=ff8800 clip]] '
          r'$[border.width=6,radius=30,noclip $[bg.color=ff8800 noclip]]',
      r'A$[border.width=4 X]Z <small>$[border.width=4,color=00f8 alpha]</small>',
    ];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: boundary,
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
                      for (final text in rows)
                        SizedBox(
                          height: 62,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MfmText(text: text, config: config),
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
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundary),
      matchesGoldenFile('goldens/borders.png'),
    );
  }, tags: 'golden');
}
