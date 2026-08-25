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
      expect(config.searchButtonLabel, null);
    });

    test('copyWith works correctly', () {
      const config = MfmRenderConfig();
      final newConfig = config.copyWith(
        enableAdvancedMfm: false,
        searchButtonLabel: 'Find',
      );
      expect(newConfig.enableAdvancedMfm, false);
      expect(newConfig.enableAnimation, true);
      expect(newConfig.searchButtonLabel, 'Find');
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

      final preservedWithNull = config.copyWith(
        // ignore: avoid_redundant_argument_values
        author: null,
        // ignore: avoid_redundant_argument_values
        localHost: null,
      );
      expect(identical(preservedWithNull.author, author), isTrue);
      expect(preservedWithNull.localHost, 'local.example');

      final cleared = config.copyWith(
        clearAuthor: true,
        clearLocalHost: true,
      );
      expect(cleared.author, isNull);
      expect(cleared.localHost, isNull);
    });

    test('copyWith rejects conflicting mention context operations', () {
      const config = MfmRenderConfig(
        author: MfmAuthorContext(host: 'remote.example'),
        localHost: 'local.example',
      );

      expect(
        () => config.copyWith(
          author: const MfmAuthorContext(host: 'other.example'),
          clearAuthor: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => config.copyWith(
          localHost: 'other.example',
          clearLocalHost: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
