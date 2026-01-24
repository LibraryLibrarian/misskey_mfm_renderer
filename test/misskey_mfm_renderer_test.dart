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
    });

    test('copyWith works correctly', () {
      const config = MfmRenderConfig();
      final newConfig = config.copyWith(enableAdvancedMfm: false);
      expect(newConfig.enableAdvancedMfm, false);
      expect(newConfig.enableAnimation, true);
    });
  });
}
