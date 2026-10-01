import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import '../config/mfm_unixtime_options.dart';

/// ECMAScript parseIntの整数prefix。Dateの範囲を超える前に計算を止める。
int? parseUnixtime(List<MfmNode> children) {
  if (children.isEmpty || children.first is! TextNode) return null;
  final text = (children.first as TextNode).text;
  var index = 0;
  while (index < text.length && _isWhitespace(text.codeUnitAt(index))) {
    index++;
  }
  var sign = 1;
  if (index < text.length) {
    final code = text.codeUnitAt(index);
    if (code == 43 || code == 45) {
      sign = code == 45 ? -1 : 1;
      index++;
    }
  }
  var radix = 10;
  if (index + 1 < text.length && text.codeUnitAt(index) == 48) {
    final next = text.codeUnitAt(index + 1);
    if (next == 120 || next == 88) {
      radix = 16;
      index += 2;
    }
  }
  final start = index;
  var value = 0;
  const limit = 8640000000000;
  while (index < text.length) {
    final code = text.codeUnitAt(index);
    final digit = switch (code) {
      >= 48 && <= 57 => code - 48,
      >= 65 && <= 70 => code - 65 + 10,
      >= 97 && <= 102 => code - 97 + 10,
      _ => -1,
    };
    if (digit < 0 || digit >= radix) break;
    if (value > (limit - digit) ~/ radix) return null;
    value = value * radix + digit;
    index++;
  }
  return index == start ? null : value * sign;
}

bool _isWhitespace(int code) =>
    (code >= 0x09 && code <= 0x0d) ||
    code == 0x20 ||
    code == 0xa0 ||
    code == 0x1680 ||
    (code >= 0x2000 && code <= 0x200a) ||
    code == 0x2028 ||
    code == 0x2029 ||
    code == 0x202f ||
    code == 0x205f ||
    code == 0x3000 ||
    code == 0xfeff;

/// epochを保持し、表示のたびに現在の端末timezoneで再生成する。
DateTime? unixtimeDateTime(int? seconds) {
  if (seconds == null || seconds.abs() > 8640000000000) return null;
  // DateTimeのプラットフォーム実装が端点を拒否してもinvalidへ戻す。
  try {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    // ignore: avoid_catching_errors
  } on ArgumentError {
    return null;
  }
}

String formatUnixtime(MfmUnixtimeFormatContext context) {
  final date = context.dateTime;
  final ja = context.locale.languageCode == 'ja';
  if (date == null) return ja ? '日時の解析に失敗' : 'None';
  if (context.mode == MfmUnixtimeMode.relative) {
    return _relative(date, context.now, ja: ja);
  }
  final year = date.year <= 0 ? 1 - date.year : date.year;
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final absolute = ja
      ? '$year/${date.month}/${date.day} ${date.hour}:$minute:$second'
      : '${date.month}/${date.day}/$year, $hour:$minute:$second ${date.hour < 12 ? 'AM' : 'PM'}';
  return context.mode == MfmUnixtimeMode.absolute
      ? absolute
      : '$absolute (${_relative(date, context.now, ja: ja)})';
}

String _relative(DateTime date, DateTime now, {required bool ja}) {
  final ago = (now.millisecondsSinceEpoch - date.millisecondsSinceEpoch) / 1000;
  const units = [
    (31536000, '年', 'y'),
    (2592000, 'ヶ月', 'mo'),
    (604800, '週間', 'w'),
    (86400, '日', 'd'),
    (3600, '時間', 'h'),
  ];
  String label(
    int value,
    String japanese,
    String english, {
    required bool future,
  }) => ja
      ? '$value$japanese${future ? '後' : '前'}'
      : future
      ? 'In $value$english'
      : '$value$english ago';
  // 英語はMisskeyの短いラベル。月と分を区別する。
  for (final unit in units) {
    if (ago >= unit.$1 || ago < -unit.$1) {
      return label(
        (ago.abs() / unit.$1).round(),
        unit.$2,
        unit.$3,
        future: ago < 0,
      );
    }
  }
  if (ago >= 60 || ago < -60) {
    return label((ago.abs() / 60).truncate(), '分', 'm', future: ago < 0);
  }
  if (ago >= 10) return label((ago % 60).truncate(), '秒', 's', future: false);
  if (ago >= -3) return ja ? 'たった今' : 'Just now';
  return label((-ago % 60).truncate(), '秒', 's', future: true);
}
