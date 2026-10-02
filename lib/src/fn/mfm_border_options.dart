import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../utils/color_parser.dart';

/// Internal, resolved border arguments. Not part of the package's public API.
enum MfmBorderStyle {
  hidden,
  dotted,
  dashed,
  solid,
  double,
  groove,
  ridge,
  inset,
  outset,
}

enum MfmBorderValidity { valid, hidden, invalid, zero }

@immutable
class MfmBorderOptions {
  const MfmBorderOptions({
    required this.style,
    required this.validity,
    required this.width,
    required this.radius,
    required this.color,
    required this.noclip,
  });

  factory MfmBorderOptions.resolve(Map<String, dynamic> args, Color accent) {
    final rawWidth = _number(args['width'], 1);
    final rawRadius = _number(args['radius'], 0);
    final style = MfmBorderStyle.values.firstWhere(
      (style) => style.name == args['style'],
      orElse: () => MfmBorderStyle.solid,
    );
    var color = accent;
    var valid = rawWidth.isFinite && rawWidth >= 0;
    final value = args['color'];
    if (value is String && _hex.hasMatch(value)) {
      if (value.length == 5) {
        valid = false;
      } else if (value.length == 4) {
        final rgba = value
            .split('')
            .map((c) => int.parse('$c$c', radix: 16))
            .toList();
        color = Color.fromARGB(rgba[3], rgba[0], rgba[1], rgba[2]);
      } else {
        color = ColorParser.parse(value)!;
      }
    }
    final validity = !valid
        ? MfmBorderValidity.invalid
        : style == MfmBorderStyle.hidden
        ? MfmBorderValidity.hidden
        : rawWidth == 0
        ? MfmBorderValidity.zero
        : MfmBorderValidity.valid;
    return MfmBorderOptions(
      style: style,
      validity: validity,
      width: validity == MfmBorderValidity.valid ? math.min(rawWidth, 1024) : 0,
      radius: rawRadius.isFinite && rawRadius > 0 ? rawRadius : 0,
      color: color,
      noclip: _truthy(args['noclip']),
    );
  }

  final MfmBorderStyle style;
  final MfmBorderValidity validity;
  final double width;
  final double radius;
  final Color color;
  final bool noclip;

  static final _hex = RegExp(r'^[0-9a-fA-F]{3,6}$');
  // ECMAScript WhiteSpace + LineTerminator, not Dart's broader trim set.
  static final _prefix = RegExp(
    r'^[\u0009-\u000D\u0020\u00A0\u1680'
    r'\u2000-\u200A\u2028\u2029\u202F'
    r'\u205F\u3000\uFEFF]*'
    r'([+-]?(?:Infinity|(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?))',
  );

  static double _number(Object? value, double fallback) {
    final double? parsed;
    if (value is num) {
      parsed = value.toDouble();
    } else if (value is String) {
      final prefix = _prefix.firstMatch(value)?.group(1);
      parsed = prefix == null ? null : double.tryParse(prefix);
    } else {
      parsed = null;
    }
    return parsed == null || parsed.isNaN ? fallback : parsed;
  }

  static bool _truthy(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0 && !value.isNaN;
    if (value is String) return value.isNotEmpty;
    return true;
  }
}
