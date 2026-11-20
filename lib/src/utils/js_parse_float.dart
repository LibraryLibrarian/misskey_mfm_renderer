/// 本家 mfm-renderer.ts の `safeParseFloat` に相当する数値の読み取り。
///
/// JavaScript の `parseFloat` と同じく、先頭の空白を飛ばして数値として
/// 読める最長の接頭辞だけを使う（`45deg` は 45、`1e` は 1、`0x10` は 0）。
/// 文字列以外・空文字・接頭辞がない値は null を返す。`Infinity` は無限大になる。
///
/// 本家は文字列だけを受け付けるが、AST を直接組み立てる利用者との互換のため
/// [num] も受け付ける（NaN は null）。
double? jsParseFloat(Object? value) {
  final double? parsed;
  if (value is num) {
    parsed = value.toDouble();
  } else if (value is String) {
    final prefix = _prefix.firstMatch(value)?.group(1);
    parsed = prefix == null ? null : double.tryParse(prefix);
  } else {
    parsed = null;
  }
  return parsed == null || parsed.isNaN ? null : parsed;
}

// ECMAScript WhiteSpace + LineTerminator, not Dart's broader trim set.
final _prefix = RegExp(
  r'^[\u0009-\u000D   '
  r' -    '
  r' 　﻿]*'
  r'([+-]?(?:Infinity|(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?))',
);
