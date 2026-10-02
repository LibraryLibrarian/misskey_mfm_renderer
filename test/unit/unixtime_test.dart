import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/utils/unixtime.dart';
import 'package:timeago/timeago.dart' as timeago;

String relative(int milliseconds, {String locale = 'en'}) => formatUnixtime(
  MfmUnixtimeFormatContext(
    dateTime: DateTime.fromMillisecondsSinceEpoch(0),
    now: DateTime.fromMillisecondsSinceEpoch(milliseconds),
    locale: Locale(locale),
    mode: MfmUnixtimeMode.relative,
  ),
);

void main() {
  group('integer prefix', () {
    final values = <String, int?>{
      '1700000000foo': 1700000000,
      '1e3': 1,
      '1.5': 1,
      '0x10': 16,
      '0x7dba8218000': 8640000000000,
      '-0x7dba8218000': -8640000000000,
      '0x7dba8218001': null,
      '-0x7dba8218001': null,
      '0x${'f' * 10000}': null,
      '-0XfFtail': -255,
      '0b11': 0,
      '-0': 0,
      '+42suffix': 42,
      '\ufeff 42': 42,
      '\u008542': null,
      '': null,
      '+': null,
      '-': null,
      '0x': null,
      'foo': null,
      '8640000000000': 8640000000000,
      '-8640000000000': -8640000000000,
      '8640000000001': null,
      '-8640000000001': null,
      '9' * 10000: null,
      '0' * 10000 + '1': 1,
    };
    for (final entry in values.entries) {
      test(
        'prefix ${entry.key.length > 30 ? entry.key.length : entry.key}',
        () {
          expect(parseUnixtime([TextNode(entry.key)]), entry.value);
        },
      );
    }
    test('ECMAScript whitespace set', () {
      for (final code in [
        9,
        10,
        11,
        12,
        13,
        32,
        160,
        0x1680,
        for (var i = 0x2000; i <= 0x200a; i++) i,
        0x2028,
        0x2029,
        0x202f,
        0x205f,
        0x3000,
        0xfeff,
      ]) {
        expect(parseUnixtime([TextNode('${String.fromCharCode(code)}17')]), 17);
      }
      for (final code in [0x85, 0x180e, 0x200b]) {
        expect(
          parseUnixtime([TextNode('${String.fromCharCode(code)}17')]),
          isNull,
        );
      }
    });
    test('only first child, including empty and nontext', () {
      expect(parseUnixtime([]), isNull);
      expect(parseUnixtime(const [TextNode('bad'), TextNode('42')]), isNull);
      expect(
        parseUnixtime(const [
          BoldNode([TextNode('42')]),
          TextNode('42'),
        ]),
        isNull,
      );
      expect(parseUnixtime(const [TextNode('12'), TextNode('34')]), 12);
    });
    test('Date endpoints are inclusive and safe', () {
      for (final seconds in [-8640000000000, 8640000000000]) {
        expect(
          unixtimeDateTime(seconds)!.millisecondsSinceEpoch,
          seconds * 1000,
        );
        expect(unixtimeDateTime(seconds + seconds.sign), isNull);
        for (final locale in ['ja', 'en']) {
          expect(
            formatUnixtime(
              MfmUnixtimeFormatContext(
                dateTime: unixtimeDateTime(seconds),
                now: DateTime.fromMillisecondsSinceEpoch(0),
                locale: Locale(locale),
                mode: MfmUnixtimeMode.detail,
              ),
            ),
            isNotEmpty,
          );
        }
      }
    });
  });

  group('fractional past and future thresholds', () {
    final boundaries = [
      (10000, 'Just now', '10s ago', '10s ago'),
      (60000, '59s ago', '1m ago', '1m ago'),
      (3600000, '59m ago', '1h ago', '1h ago'),
      (86400000, '24h ago', '1d ago', '1d ago'),
      (604800000, '7d ago', '1w ago', '1w ago'),
      (2592000000, '4w ago', '1mo ago', '1mo ago'),
      (31536000000, '12mo ago', '1y ago', '1y ago'),
      (-3000, 'In 3s', 'Just now', 'Just now'),
      (-60000, 'In 1m', 'In 0s', 'In 59s'),
      (-3600000, 'In 1h', 'In 60m', 'In 59m'),
      (-86400000, 'In 1d', 'In 24h', 'In 24h'),
      (-604800000, 'In 1w', 'In 7d', 'In 7d'),
      (-2592000000, 'In 1mo', 'In 4w', 'In 4w'),
      (-31536000000, 'In 1y', 'In 12mo', 'In 12mo'),
    ];
    for (final boundary in boundaries) {
      test('${boundary.$1} +/-1ms', () {
        expect(relative(boundary.$1 - 1), boundary.$2);
        expect(relative(boundary.$1), boundary.$3);
        expect(relative(boundary.$1 + 1), boundary.$4);
      });
    }
    for (final seconds in [3600, 86400, 604800, 2592000, 31536000]) {
      test('round half boundary $seconds', () {
        for (final sign in [1, -1]) {
          expect(relative(sign * (seconds * 1500 - 1)), contains('1'));
          expect(relative(sign * seconds * 1500), contains('2'));
          expect(relative(sign * (seconds * 1500 + 1)), contains('2'));
        }
      });
    }
    test('Japanese and unsupported fallback', () {
      expect(relative(60000, locale: 'ja'), '1分前');
      expect(relative(-3600000, locale: 'ja'), '60分後');
      expect(relative(-3000, locale: 'ja'), 'たった今');
      expect(relative(60000, locale: 'fr'), '1m ago');
    });
  });

  test('absolute/detail, midnight/noon, era year and wide years', () {
    for (final year in [-10000, 0, 1, 2026, 10000]) {
      for (final hour in [0, 12, 23]) {
        final date = DateTime(year, 10, 2, hour, 4, 5);
        final displayYear = year <= 0 ? 1 - year : year;
        for (final ja in [true, false]) {
          final context = MfmUnixtimeFormatContext(
            dateTime: date,
            now: date,
            locale: Locale(ja ? 'ja' : 'en', 'GB'),
            mode: MfmUnixtimeMode.absolute,
          );
          final absolute = ja
              ? '$displayYear/10/2 $hour:04:05'
              : '10/2/$displayYear, ${hour == 23 ? 11 : 12}:04:05 ${hour < 12 ? 'AM' : 'PM'}';
          expect(formatUnixtime(context), absolute);
          expect(
            formatUnixtime(
              MfmUnixtimeFormatContext(
                dateTime: date,
                now: date,
                locale: context.locale,
                mode: MfmUnixtimeMode.detail,
              ),
            ),
            '$absolute (${ja ? 'たった今' : 'Just now'})',
          );
        }
      }
    }
  });

  test('local epoch conversion uses process timezone', () {
    final local = unixtimeDateTime(0)!;
    expect(local.isUtc, isFalse);
    expect(local.toUtc(), DateTime.utc(1970));
    expect(local.hour, local.timeZoneOffset.inHours % 24);
    const expectedOffset = String.fromEnvironment('EXPECTED_UNIXTIME_OFFSET');
    if (expectedOffset.isNotEmpty) {
      expect(local.timeZoneOffset.inHours, int.parse(expectedOffset));
    }
  });

  test('legacy retains timeago global locale and future behavior', () {
    addTearDown(() => timeago.setDefaultLocale('en'));
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    timeago.setDefaultLocale('ja');
    final now = DateTime(2026);
    for (final date in [
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1)),
      null,
    ]) {
      final context = MfmUnixtimeFormatContext(
        dateTime: date,
        now: now,
        locale: const Locale('en'),
        mode: MfmUnixtimeMode.relative,
      );
      expect(
        mfmLegacyUnixtimeFormatter(context),
        date == null ? 'None' : timeago.format(date, clock: now),
      );
      formatUnixtime(context);
      expect(
        timeago.format(now.subtract(const Duration(days: 1)), clock: now),
        timeago.format(
          now.subtract(const Duration(days: 1)),
          clock: now,
          locale: 'ja',
        ),
      );
    }
  });

  test('config copy, reset and conflicting clear', () {
    const options = MfmUnixtimeOptions(locale: Locale('ja'));
    const config = MfmRenderConfig(unixtimeOptions: options);
    expect(config.copyWith().unixtimeOptions, same(options));
    expect(config.copyWith(clearUnixtimeOptions: true).unixtimeOptions, isNull);
    expect(
      config
          .copyWith(unixtimeOptions: const MfmUnixtimeOptions())
          .unixtimeOptions!
          .locale,
      isNull,
    );
    expect(
      () =>
          config.copyWith(unixtimeOptions: options, clearUnixtimeOptions: true),
      throwsArgumentError,
    );
  });
}
