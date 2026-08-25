import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('MfmRenderConfig', () {
    test('default values are correct', () {
      const config = MfmRenderConfig();
      expect(config.enableAdvancedMfm, true);
      expect(config.enableAnimation, true);
      expect(config.enableNyaize, false);
      expect(config.baseTextStyle, null);
      expect(config.author, null);
      expect(config.localHost, null);
    });

    test('copyWith works correctly', () {
      const config = MfmRenderConfig();
      final newConfig = config.copyWith(enableAdvancedMfm: false);
      expect(newConfig.enableAdvancedMfm, false);
      expect(newConfig.enableAnimation, true);
    });

    test('copyWith preserves and overrides mention context', () {
      const author = MfmAuthorContext(host: 'remote.example');
      const config = MfmRenderConfig(
        author: author,
        localHost: 'local.example',
      );

      final preserved = config.copyWith(enableAdvancedMfm: false);
      expect(identical(preserved.author, author), isTrue);
      expect(preserved.localHost, 'local.example');

      const replacement = MfmAuthorContext(host: 'other.example');
      final overridden = config.copyWith(
        author: replacement,
        localHost: 'new-local.example',
      );
      expect(identical(overridden.author, replacement), isTrue);
      expect(overridden.localHost, 'new-local.example');

      final cleared = config.copyWith(author: null, localHost: null);
      expect(cleared.author, isNull);
      expect(cleared.localHost, isNull);
    });
  });
}
