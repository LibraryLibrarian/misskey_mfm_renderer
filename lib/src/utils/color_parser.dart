import 'package:flutter/widgets.dart';

/// 16進カラー文字列をパースするユーティリティ
class ColorParser {
  ColorParser._();

  /// 16進カラー文字列をColorに変換
  ///
  /// 対応フォーマット:
  /// - 3桁: "RGB" -> "RRGGBB"
  /// - 6桁: "RRGGBB"
  /// - 先頭の#は省略可能
  ///
  /// 不正な値の場合はnullを返す
  static Color? parse(String value) {
    var hex = value.replaceFirst('#', '');

    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      return null;
    }

    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }

    if (hex.length != 6) {
      return null;
    }

    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) {
      return null;
    }

    return Color(0xFF000000 | intValue);
  }
}
