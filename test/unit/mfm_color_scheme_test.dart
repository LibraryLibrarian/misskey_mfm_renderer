import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('MfmColorScheme', () {
    test('light preset matches Mi Light', () {
      const scheme = MfmColorScheme.light();

      expect(scheme.accent, const Color(0xFF86B300));
      expect(scheme.link, const Color(0xFF44A4C1));
      expect(scheme.hashtag, const Color(0xFFFF9156));
      expect(scheme.mention, const Color(0xFF86B300));
      expect(scheme.mentionMe, const Color(0xFF00B346));
      expect(scheme.fg, const Color(0xFF676767));
      expect(scheme.bg, const Color(0xFFF9F9F9));
      expect(scheme.divider, const Color(0xFFE8E8E8));
      expect(scheme.panel, const Color(0xFFFFFFFF));
    });

    test('dark preset matches Mi Dark', () {
      const scheme = MfmColorScheme.dark();

      expect(scheme.accent, const Color(0xFF86B300));
      expect(scheme.link, const Color(0xFF86B300));
      expect(scheme.hashtag, const Color(0xFF4CB8D4));
      expect(scheme.mention, const Color(0xFFDA6D35));
      expect(scheme.mentionMe, const Color(0xFFD44C4C));
      expect(scheme.fg, const Color(0xFFC7D1D8));
      expect(scheme.bg, const Color(0xFF232323));
      expect(scheme.divider, const Color.fromRGBO(255, 255, 255, 0.14));
      expect(scheme.panel, const Color(0xFF2D2D2D));
    });

    test('preset named arguments override only specified resolved colors', () {
      const light = MfmColorScheme.light(
        accent: Color(0xFF010101),
        bg: Color(0xFF020202),
      );
      const dark = MfmColorScheme.dark(
        mention: Color(0xFF030303),
        panel: Color(0xFF040404),
      );

      expect(light.accent, const Color(0xFF010101));
      expect(light.bg, const Color(0xFF020202));
      expect(light.mention, const Color(0xFF86B300));
      expect(dark.mention, const Color(0xFF030303));
      expect(dark.panel, const Color(0xFF040404));
      expect(dark.accent, const Color(0xFF86B300));
    });

    test('copyWith replaces selected colors and preserves the rest', () {
      const original = MfmColorScheme.light();
      final copied = original.copyWith(
        link: const Color(0xFF111111),
        divider: const Color(0xFF222222),
      );

      expect(copied.link, const Color(0xFF111111));
      expect(copied.divider, const Color(0xFF222222));
      expect(copied.accent, original.accent);
      expect(copied.hashtag, original.hashtag);
      expect(copied.mention, original.mention);
      expect(copied.mentionMe, original.mentionMe);
      expect(copied.fg, original.fg);
      expect(copied.bg, original.bg);
      expect(copied.panel, original.panel);
    });

    test('supports value equality, hashCode, and descriptive toString', () {
      const first = MfmColorScheme.light();
      const same = MfmColorScheme.light();
      const different = MfmColorScheme.light(link: Color(0xFF000000));

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
      expect(
        first.toString(),
        allOf(
          startsWith('MfmColorScheme('),
          contains('accent:'),
          contains('mentionMe:'),
          contains('panel:'),
        ),
      );
    });
  });
}
