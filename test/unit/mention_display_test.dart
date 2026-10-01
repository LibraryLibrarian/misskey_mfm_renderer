import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/utils/mention_display.dart';

void main() {
  test(
    'avatar URI uses local origin and one safely escaped account segment',
    () {
      final uri = mentionAvatarUri(
        'https://local.test:8443/',
        '@a@remote.test',
      );
      expect(uri.origin, 'https://local.test:8443');
      expect(uri.pathSegments, ['avatar', '@a@remote.test']);
      expect(
        mentionAvatarUri('https://local.test', '@a@bad/host?#').pathSegments,
        ['avatar', '@a@bad/host?#'],
      );
      expect(
        mentionAvatarUri('https://bücher.example', '@a').host,
        'xn--bcher-kva.example',
      );
    },
  );
  test('Unicode origin and explicit default port retain mention identity', () {
    const config = MfmRenderConfig(
      localHost: 'xn--bcher-kva.example:443',
      mentionOptions: MfmMentionOptions(
        localOrigin: 'https://bücher.example:443',
        viewerAcct: '@a',
      ),
    );
    validateMentionConfig(config);
    final display = resolveMentionDisplay(
      username: 'a',
      nodeHost: 'BÜCHER.example:443',
      config: config,
    );
    expect(display.isSelf, isTrue);
    expect(display.host, isEmpty);
  });

  for (final invalid in [
    '',
    ' example.test',
    'example.test ',
    'a b',
    'a@b',
    'https://a',
    'a/b',
    'a?b',
    'a#b',
    'a%20b',
    'a\\b',
    'a:',
    'a:0',
    'a:65536',
    'a:-1',
    'a:+80',
    'a:1.5',
    'a:80:90',
    'a..',
    '-a',
    'a-',
    'a_b',
    '[::1',
    '::1',
    '[gg::1]',
    '[::1]x',
    '999.1.1.1',
  ]) {
    test('reject authority $invalid', () {
      expect(parseMentionAuthority(invalid), isNull);
    });
  }
  for (final pair in [
    ('EXAMPLE.test.', 'example.test'),
    ('xn--bcher-kva.example', 'bücher.example'),
    ('[2001:db8::1]:80', '[2001:0db8:0:0:0:0:0:1]:80'),
    ('127.0.0.1:123', '127.0.0.1:123'),
  ]) {
    test('normalized authorities ${pair.$1}', () {
      expect(
        parseMentionAuthority(
          pair.$1,
        )!.matches(parseMentionAuthority(pair.$2)!),
        isTrue,
      );
    });
  }
  test('absent and explicit ports differ for mentions', () {
    expect(
      parseMentionAuthority(
        'example.test',
      )!.matches(parseMentionAuthority('example.test:443')!),
      isFalse,
    );
  });
  for (final value in [
    'ftp://example.test',
    '/relative',
    'https://user@example.test',
    'https://@example.test',
    'https://example.test/path',
    'https://example.test?',
    'https://example.test#',
    'https://example.test:0',
    'https://example.test:65536',
  ]) {
    test('invalid origin $value', () {
      expect(
        () => validateMentionConfig(
          MfmRenderConfig(
            mentionOptions: MfmMentionOptions(localOrigin: value),
          ),
        ),
        throwsArgumentError,
      );
    });
  }
  test('origin consistency alone supplies scheme default ports', () {
    validateMentionConfig(
      const MfmRenderConfig(
        localHost: 'EXAMPLE.test.:443',
        mentionOptions: MfmMentionOptions(
          localOrigin: 'https://example.test/',
        ),
      ),
    );
    expect(
      () => validateMentionConfig(
        const MfmRenderConfig(
          localHost: 'example.test',
          mentionOptions: MfmMentionOptions(
            localOrigin: 'https://example.test:8443',
          ),
        ),
      ),
      throwsArgumentError,
    );
    validateMentionConfig(
      const MfmRenderConfig(localHost: 'old malformed host'),
    );
  });
  for (final viewer in [
    'alice',
    '@',
    '@a-b',
    '@a@',
    '@a@a/b',
    '@a@@b',
    '@a\n',
  ]) {
    test('invalid viewer $viewer', () {
      expect(
        () => validateMentionConfig(
          MfmRenderConfig(
            localHost: 'local.test',
            mentionOptions: MfmMentionOptions(viewerAcct: viewer),
          ),
        ),
        throwsArgumentError,
      );
    });
  }
  test('hostless viewer cannot borrow author host', () {
    expect(
      () => validateMentionConfig(
        const MfmRenderConfig(
          author: MfmAuthorContext(host: 'author.test'),
          mentionOptions: MfmMentionOptions(viewerAcct: '@alice'),
        ),
      ),
      throwsArgumentError,
    );
  });
  test('host precedence, local hiding and independent viewer', () {
    const config = MfmRenderConfig(
      localHost: 'local.test',
      author: MfmAuthorContext(host: 'author.test'),
      mentionOptions: MfmMentionOptions(viewerAcct: '@alice'),
    );
    MentionDisplay resolve(String? host) => resolveMentionDisplay(
      username: 'Alice',
      nodeHost: host,
      config: config,
    );
    expect(resolve(null).label, '@Alice@author.test');
    expect(resolve(null).isSelf, isFalse);
    expect(resolve('LOCAL.test.').label, '@Alice');
    expect(resolve('LOCAL.test.').isSelf, isTrue);
    expect(resolve('local.test:443').isSelf, isFalse);
    expect(resolve('xn--bcher-kva.example').host, '@bücher.example');
    expect(resolve('bad host').host, '@bad host');
    expect(resolve('bad host').isSelf, isFalse);
  });
  test('origin only supplements internal identity, with raw avatar host', () {
    const config = MfmRenderConfig(
      mentionOptions: MfmMentionOptions(
        localOrigin: 'https://local.test',
        viewerAcct: '@alice',
      ),
    );
    validateMentionConfig(config);
    final display = resolveMentionDisplay(
      username: 'Alice',
      nodeHost: null,
      config: config,
    );
    expect(display.label, '@Alice');
    expect(display.isSelf, isTrue);
    expect(display.avatarAcct, '@Alice@local.test');
  });
  test('options copyWith preserves, replaces and clears only own value', () {
    const options = MfmMentionOptions(viewerAcct: '@alice@local.test');
    const config = MfmRenderConfig(mentionOptions: options);
    expect(config.copyWith().mentionOptions, same(options));
    expect(
      config.copyWith(mentionOptions: const MfmMentionOptions()).mentionOptions,
      isNot(same(options)),
    );
    expect(config.copyWith(clearMentionOptions: true).mentionOptions, isNull);
    expect(
      () => config.copyWith(mentionOptions: options, clearMentionOptions: true),
      throwsArgumentError,
    );
  });
}
