/// テキストを「猫語」に変換する純粋関数
///
/// Misskey本家 `packages/misskey-js/src/nyaize.ts` を Dart に移植したもの。
/// 日本語/英語/韓国語の3言語に対応する。
///
/// 仕様の概要:
/// - ja-JP: 「な/ナ/ﾅ」をそれぞれ「にゃ/ニャ/ﾆｬ」に置換
/// - en-US:
///   - 「n」の直後の「a」を「ya」（大文字なら「YA」）へ
///   - 「morn」の直後の「ing」を「yan」（全大文字なら「YAN」）へ
///   - 「every」の直後の「one」を「nyan」（全大文字なら「NYAN」）へ
/// - ko-KR:
///   - 「나-낳」を「냐-냫」へ（同オフセットでシフト）
///   - 文末や記号直前の「다」を「다냥」へ
///   - 同位置の「야」を「냥」へ
final _enRegex1 = RegExp('(?<=n)a', caseSensitive: false);
final _enRegex2 = RegExp('(?<=morn)ing', caseSensitive: false);
final _enRegex3 = RegExp('(?<=every)one', caseSensitive: false);
final _koRegex1 = RegExp('[나-낳]');
final _koRegex2 = RegExp(
  r'(다$)|(다(?=\.))|(다(?= ))|(다(?=!))|(다(?=\?))',
  multiLine: true,
);
final _koRegex3 = RegExp(r'(야(?=\?))|(야$)|(야(?= ))', multiLine: true);

// '냐' (U+B0D0) - '나' (U+B098) = 56。Hangul音節ブロックでの
// 母音「ㅏ」→「ㅑ」へのシフト量（終声28通り × 母音2ステップ）。
const int _koOffset = 0xB0D0 - 0xB098;

/// テキストを猫語へ変換して返す
String nyaize(String text) {
  var result = text
      .replaceAll('な', 'にゃ')
      .replaceAll('ナ', 'ニャ')
      .replaceAll('ﾅ', 'ﾆｬ');

  result = result.replaceAllMapped(_enRegex1, (m) {
    final matched = m.group(0)!;
    return matched == 'A' ? 'YA' : 'ya';
  });
  result = result.replaceAllMapped(_enRegex2, (m) {
    final matched = m.group(0)!;
    return matched == 'ING' ? 'YAN' : 'yan';
  });
  result = result.replaceAllMapped(_enRegex3, (m) {
    final matched = m.group(0)!;
    return matched == 'ONE' ? 'NYAN' : 'nyan';
  });

  result = result.replaceAllMapped(_koRegex1, (m) {
    final code = m.group(0)!.codeUnitAt(0);
    return String.fromCharCode(code + _koOffset);
  });
  result = result.replaceAll(_koRegex2, '다냥');
  result = result.replaceAll(_koRegex3, '냥');

  return result;
}
