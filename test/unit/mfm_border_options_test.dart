import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/src/fn/mfm_border_options.dart';

const accent = Color(0xFF123456);
MfmBorderOptions resolve(Map<String, dynamic> args) =>
    MfmBorderOptions.resolve(args, accent);

void main() {
  test('style allowlist is case sensitive; no CSS none', () {
    for (final style in MfmBorderStyle.values) {
      expect(resolve({'style': style.name}).style, style);
    }
    for (final value in [null, '', true, 'none', 'DASHED', 'unknown', 2]) {
      expect(resolve({'style': value}).style, MfmBorderStyle.solid);
    }
  });

  test('JS decimal prefixes and direct AST numeric compatibility', () {
    final cases = <Object?, double>{
      null: 1,
      true: 1,
      false: 1,
      '': 1,
      'NaN': 1,
      double.nan: 1,
      '12abc': 12,
      '.5': 0.5,
      '+.5tail': 0.5,
      '1e1': 10,
      '1e': 1,
      '1e+tail': 1,
      '0x10': 0,
      '-0': 0,
      '1.2.3': 1.2,
      '1e-2junk': 0.01,
      12: 12,
      0.5: 0.5,
      '1023.9': 1023.9,
      '1024': 1024,
      '1024.1': 1024,
      '1e300': 1024,
      '\u008512': 1,
      '᠎12': 1,
      '​12': 1,
    };
    for (final entry in cases.entries) {
      expect(
        resolve({'width': entry.key}).width,
        entry.value,
        reason: '${entry.key}',
      );
    }
    for (final code in [
      9,
      10,
      11,
      12,
      13,
      32,
      0xa0,
      0x1680,
      ...List.generate(11, (i) => 0x2000 + i),
      0x2028,
      0x2029,
      0x202f,
      0x205f,
      0x3000,
      0xfeff,
    ]) {
      expect(
        resolve({'width': '${String.fromCharCode(code)}12x'}).width,
        12,
        reason: 'whitespace $code',
      );
    }
    for (final value in [<Object>[], <String, Object>{}, Object()]) {
      expect(resolve({'width': value}).width, 1);
    }
  });

  test(
    'invalid, hidden and zero retain distinct state and independent radius',
    () {
      for (final value in [
        -1,
        '-.5x',
        double.infinity,
        double.negativeInfinity,
        'Infinitytail',
        '+Infinity',
        '-Infinity',
        '1e999',
      ]) {
        final options = resolve({'width': value, 'radius': 10});
        expect(options.validity, MfmBorderValidity.invalid, reason: '$value');
        expect(options.width, 0);
        expect(options.radius, 10);
      }
      expect(
        resolve({'style': 'hidden', 'width': 10}).validity,
        MfmBorderValidity.hidden,
      );
      expect(resolve({'width': '-0'}).validity, MfmBorderValidity.zero);
      for (final value in [
        -1,
        double.infinity,
        'Infinity',
        double.nan,
        'bad',
        true,
      ]) {
        expect(resolve({'radius': value}).radius, 0);
      }
      expect(resolve({'radius': '1e300x'}).radius, 1e300);
      expect(resolve({'radius': '12px'}).radius, 12);
    },
  );

  test('RGB, CSS RGBA, invalid five hex and accent fallback', () {
    for (final entry in {
      'f00': 0xFFFF0000,
      'AbC': 0xFFAABBCC,
      '123456': 0xFF123456,
      'f008': 0x88FF0000,
      '1234': 0x44112233,
      'fff0': 0x00FFFFFF,
    }.entries) {
      final options = resolve({'color': entry.key, 'width': 8});
      expect(options.color, Color(entry.value));
      expect(options.width, 8);
    }
    for (final value in ['12345', 'abcde']) {
      expect(resolve({'color': value}).validity, MfmBorderValidity.invalid);
    }
    for (final value in [
      'zzzzz',
      '#f00',
      '12345678',
      'red',
      '',
      'ff',
      true,
      123,
    ]) {
      final options = resolve({'color': value});
      expect(options.color, accent);
      expect(options.width, 1);
    }
  });

  test('noclip uses JS truthiness, including empty objects', () {
    for (final value in [null, false, 0, -0.0, double.nan, '']) {
      expect(resolve({'noclip': value}).noclip, isFalse);
    }
    for (final value in [
      true,
      1,
      -1,
      double.infinity,
      'false',
      '0',
      <Object>[],
      <String, Object>{},
      Object(),
    ]) {
      expect(resolve({'noclip': value}).noclip, isTrue);
    }
  });
}
