import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// Generate/compare only in the fixed Linux amd64 / Flutter 3.38.7 environment.
// Load the actual SDK icon font: a missing-glyph box is not a valid baseline.
void main() {
  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final packages = (config['packages'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final flutter = packages.singleWhere(
      (package) => package['name'] == 'flutter',
    );
    final flutterUri = configFile.uri.resolve(flutter['rootUri'] as String);
    final sdk = Directory.fromUri(flutterUri).parent.parent;
    final font = File(
      '${sdk.path}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    final loader = FontLoader('MaterialIcons')
      ..addFont(font.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  });

  testWidgets('labelled link icons, styling, wrapping and baseline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const boundary = ValueKey('labelled-links');
    const config = MfmRenderConfig(
      localHost: 'social.example',
      baseTextStyle: TextStyle(
        fontFamily: 'Ahem',
        fontSize: 20,
        height: 1.2,
        color: Color(0xFF202020),
      ),
      brightness: Brightness.light,
      enableAnimation: false,
      lightColorScheme: MfmColorScheme.light(link: Color(0xFF286BAA)),
    );
    const rows = [
      'H [External](https://other.example) H',
      'H [Self](https://social.example) H',
      'H ?[Silent](https://other.example) H',
      'H <small>[Small](https://other.example)</small> H',
      'H [**Bold** ~~Strike~~](https://other.example) H',
      r'H [$[fg.color=dd2244 Red] End](https://other.example) H',
      r'H [$[ruby Base Ruby]](https://other.example) H',
      r'$[rainbow H [Link](https://other.example) H]',
      r'H $[border.width=3 [Link](https://other.example)] H',
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
                height: 740,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final text in rows)
                        SizedBox(
                          height: 60,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MfmText(text: text, config: config),
                          ),
                        ),
                      const SizedBox(
                        width: 220,
                        child: MfmText(
                          text:
                              '[Long label wraps here](https://other.example)',
                          config: config,
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
    expect(
      find.byIcon(
        const IconData(
          0xe45c,
          fontFamily: 'MaterialIcons',
          matchTextDirection: true,
        ),
      ),
      findsNWidgets(9),
    );
    await expectLater(
      find.byKey(boundary),
      matchesGoldenFile('goldens/labelled_links.png'),
    );
  }, tags: 'golden');
}
