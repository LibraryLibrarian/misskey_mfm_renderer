import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  const context = MfmEmojiContext(fontSize: 20, scale: 1);
  final filenames = {
    '©': 'a9.png',
    '😀': '1f600.png',
    '❤': '2764.png',
    '❤️': '2764.png',
    '👍🏽': '1f44d-1f3fd.png',
    '1️⃣': '31-20e3.png',
    '#️⃣': '23-20e3.png',
    '🇯🇵': '1f1ef-1f1f5.png',
    '🏳️‍🌈': '1f3f3-fe0f-200d-1f308.png',
    '🏴\u{e0067}\u{e0062}\u{e0065}\u{e006e}\u{e0067}\u{e007f}':
        '1f3f4-e0067-e0062-e0065-e006e-e0067-e007f.png',
    'not emoji': '6e-6f-74-20-65-6d-6f-6a-69.png',
    '😀‍😀': '1f600-200d-1f600.png',
  };
  for (final entry in filenames.entries) {
    test('filename ${entry.value}', () {
      final calls = <String>[];
      final helper = MfmTwemojiBuilder(
        imageProvider: (name) {
          calls.add(name);
          return null;
        },
      );
      // Observe only the filename passed to the public callback.
      // ignore: cascade_invocations
      helper.build(entry.key, context);
      expect(calls, [entry.value]);
    });
  }
  for (final emoji in ['', '️', '️️', '❤︎', '😀︎‍😀']) {
    test('guard ${emoji.runes.toList()}', () {
      final helper = MfmTwemojiBuilder(
        imageProvider: (_) => fail('provider called'),
      );
      expect(helper.build(emoji, context), isA<Widget>());
    });
  }
  test('callback programming exceptions propagate', () {
    final error = StateError('callback');
    final helper = MfmTwemojiBuilder(imageProvider: (_) => throw error);
    expect(() => helper.build('😀', context), throwsA(same(error)));
  });
  test('Uri normalizes an empty user-info marker before validation', () {
    final url = Uri.parse('https://@example.test/');
    expect(url.toString(), 'https://example.test/');
    expect(url.userInfo, isEmpty);
    expect(MfmTwemojiBuilder.network(baseUrl: url), isA<MfmTwemojiBuilder>());
  });
  for (final url in [
    'relative/path',
    '//example.test/png/',
    'ftp://example.test/png/',
    'https:/png/',
    'https://user:pass@example.test/',
    'https://example.test/?',
    'https://example.test/?v=1',
    'https://example.test/#',
    'https://example.test/#part',
  ]) {
    test('reject network base $url at construction', () {
      expect(
        () => MfmTwemojiBuilder.network(baseUrl: Uri.parse(url)),
        throwsArgumentError,
      );
    });
  }
}
