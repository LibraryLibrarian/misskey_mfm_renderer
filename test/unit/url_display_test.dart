import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/src/utils/url_display.dart';

void main() {
  group('parseUrlDisplay', () {
    test('external URLを表示パートへ分解してdecodeする', () {
      final parts = parseUrlDisplay(
        'https://xn--r8jz45g.xn--zckzah:8443/'
        '%E3%83%91%E3%82%B9?q=%E3%81%82+b#%E7%89%87',
      );

      expect(
        parts,
        const UrlDisplayParts(
          scheme: 'https',
          host: '例え.テスト',
          port: '8443',
          path: '/パス',
          query: '?q=あ+b',
          fragment: '#片',
          isSelf: false,
        ),
      );
    });

    test('self URLも同じパートモデルを返す', () {
      final parts = parseUrlDisplay(
        'https://example.com/%E3%83%91%E3%82%B9?q=1#top',
        localHost: 'example.com',
      );

      expect(
        parts,
        const UrlDisplayParts(
          scheme: 'https',
          host: 'example.com',
          path: '/パス',
          query: '?q=1',
          fragment: '#top',
          isSelf: true,
        ),
      );
    });

    test('Punycode hostをUnicodeへ変換する', () {
      final parts = parseUrlDisplay(
        'https://xn--r8jz45g.xn--zckzah/path',
      );

      expect(parts!.host, '例え.テスト');
    });

    test('Unicode host入力をpercent decodeして保持する', () {
      final parts = parseUrlDisplay('https://例え.テスト/path');

      expect(parts!.host, '例え.テスト');
    });

    test('不完全なpercent escapeはパート単位で原文へfallbackする', () {
      final parts = parseUrlDisplay(
        'https://example.com/%E3%81?q=%E3%81#%E3%81',
      );

      expect(parts!.path, '/%E3%81');
      expect(parts.query, '?q=%E3%81');
      expect(parts.fragment, '#%E3%81');
    });

    test('空pathをJavaScript URLと同じroot pathへ補う', () {
      final parts = parseUrlDisplay('https://example.com');

      expect(parts!.path, '/');
    });

    test('空のquery delimiterとfragment delimiterは表示しない', () {
      expect(parseUrlDisplay('https://example.com?')!.query, isEmpty);
      expect(parseUrlDisplay('https://example.com#')!.fragment, isEmpty);
    });

    test('IPv6 hostはJavaScript URLと同じく角括弧付きで表示する', () {
      final parts = parseUrlDisplay(
        'http://[::1]:8080/path',
        localHost: '[::1]:8080',
      );

      expect(parts!.host, '[::1]');
      expect(parts.port, '8080');
      expect(parts.isSelf, isTrue);
    });

    test('既定portは非表示にし明示された非既定portだけ保持する', () {
      expect(parseUrlDisplay('https://example.com:443')!.port, isNull);
      expect(parseUrlDisplay('http://example.com:80')!.port, isNull);
      expect(parseUrlDisplay('https://example.com:8443')!.port, '8443');
      expect(parseUrlDisplay('http://example.com:8080')!.port, '8080');
    });

    test('http(s) absolute URL以外はnullを返す', () {
      for (final value in [
        'ftp://example.com/path',
        'mailto:user@example.com',
        '/relative/path',
        'not a url',
        'https:///path',
        'https://',
      ]) {
        expect(parseUrlDisplay(value), isNull, reason: value);
      }
    });

    test('localHostをcase-insensitiveかつ末尾dotなしで比較する', () {
      final parts = parseUrlDisplay(
        'https://Example.COM/path',
        localHost: 'EXAMPLE.com.',
      );

      expect(parts!.isSelf, isTrue);
    });

    test('localHostのPunycodeとURLのUnicode hostを同一視する', () {
      final parts = parseUrlDisplay(
        'https://例え.テスト/path',
        localHost: 'XN--R8JZ45G.XN--ZCKZAH.',
      );

      expect(parts!.isSelf, isTrue);
    });

    test('localHostにportがあればURLのeffective portと比較する', () {
      expect(
        parseUrlDisplay(
          'https://example.com/path',
          localHost: 'example.com:443',
        )!.isSelf,
        isTrue,
      );
      expect(
        parseUrlDisplay(
          'https://example.com:8443/path',
          localHost: 'example.com:8443',
        )!.isSelf,
        isTrue,
      );
      expect(
        parseUrlDisplay(
          'https://example.com:8443/path',
          localHost: 'example.com:443',
        )!.isSelf,
        isFalse,
      );
    });

    test('localHostにportがなければhostだけで近似判定する', () {
      final parts = parseUrlDisplay(
        'http://example.com:3000/path',
        localHost: 'example.com',
      );

      expect(parts!.isSelf, isTrue);
    });

    test('空または不正なlocalHostはself判定に使わない', () {
      for (final localHost in [null, '', ' ', 'example.com:not-a-port']) {
        expect(
          parseUrlDisplay(
            'https://example.com/path',
            localHost: localHost,
          )!.isSelf,
          isFalse,
          reason: '$localHost',
        );
      }
    });
  });
}
