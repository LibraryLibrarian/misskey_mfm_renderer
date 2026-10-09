import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

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

  testWidgets('editable search controls, widths and typography', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 1180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const boundary = ValueKey('search-golden');

    Widget sample(
      String title, {
      String query = 'Flutter',
      String label = 'Search',
      double width = 400,
      double scale = 1,
      double fontSize = 18,
      bool dark = false,
      bool enabled = true,
      MfmColorScheme? colors,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Ahem',
                fontSize: 12,
                color: Color(0xFF444444),
              ),
            ),
            ColoredBox(
              color: dark ? const Color(0xFF232323) : const Color(0xFFFFFFFF),
              child: SizedBox(
                width: width,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: MfmText(
                    text: '$query Search',
                    config: MfmRenderConfig(
                      baseTextStyle: TextStyle(
                        fontFamily: 'Ahem',
                        fontSize: fontSize,
                        height: 1.2,
                        color: dark
                            ? const Color(0xFFC7D1D8)
                            : const Color(0xFF676767),
                      ),
                      brightness: dark ? Brightness.dark : Brightness.light,
                      enableAnimation: false,
                      searchButtonLabel: label,
                      lightColorScheme: colors,
                      onSearchTap: enabled ? (_) {} : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (context, child) => Center(
          child: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: SizedBox(
                width: 600,
                height: 1140,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sample('standard'),
                      sample('label override', label: 'Find'),
                      sample(
                        'long query',
                        query: 'A long search query beyond the visible field',
                        width: 240,
                      ),
                      sample(
                        'long label and narrow width',
                        label: 'Search everywhere',
                        width: 160,
                      ),
                      sample('narrow at scale two', width: 100, scale: 2),
                      sample('large typography', fontSize: 26),
                      sample('disabled submission', enabled: false),
                      sample('dark', dark: true),
                      sample(
                        'custom divider',
                        colors: const MfmColorScheme.light(
                          divider: Color(0xFFBB3377),
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
    expect(find.byType(EditableText), findsNWidgets(9));
    expect(
      find.byIcon(const IconData(0xe567, fontFamily: 'MaterialIcons')),
      findsNWidgets(9),
    );
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .every(
            (field) => !field.focusNode.hasFocus,
          ),
      isTrue,
    );
    await expectLater(
      find.byKey(boundary),
      matchesGoldenFile('goldens/search.png'),
    );
  }, tags: 'golden');
}
