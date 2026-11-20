import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/src/utils/js_parse_float.dart';

void main() {
  test('JavaScriptのparseFloatと同じ先頭の数値を読む', () {
    // 期待値は Node.js の parseFloat の結果。
    final cases = <String, double>{
      '45deg': 45,
      '1em': 1,
      '2foo': 2,
      '1e': 1,
      '1e+': 1,
      '1e1': 10,
      '0x10': 0,
      '.5': .5,
      '+.5': .5,
      '5.': 5,
      '-45': -45,
      ' \t\n12': 12,
      '　12': 12,
      'Infinity': double.infinity,
      '+Infinityx': double.infinity,
      '-Infinity': double.negativeInfinity,
      '1e400': double.infinity,
      '-1e400': double.negativeInfinity,
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(jsParseFloat(key), value, reason: key);
    }
    final negativeZero = jsParseFloat('-0');
    expect(negativeZero, 0);
    expect(negativeZero!.isNegative, isTrue);
  });

  test('数値として読めない値はnullを返す', () {
    // ECMAScriptの空白に含まれない文字（U+0085, U+180E, U+200B）は飛ばさない。
    for (final value in <Object?>[
      null,
      true,
      false,
      '',
      'abc',
      'NaN',
      'infinity',
      '.e1',
      '\u008512',
      '᠎12',
      '​12',
      double.nan,
    ]) {
      expect(jsParseFloat(value), isNull, reason: '$value');
    }
  });

  test('ASTを直接組み立てた数値はそのまま使う', () {
    expect(jsParseFloat(3), 3);
    expect(jsParseFloat(-1.5), -1.5);
  });
}
