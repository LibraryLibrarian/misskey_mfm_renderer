import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../utils/color_parser.dart';
import '../utils/js_parse_float.dart';

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

  /// [maxWidth]は`MfmRenderConfig.maxBorderWidth`の値で、[effectiveMaxWidth]で解決する。
  factory MfmBorderOptions.resolve(
    Map<String, dynamic> args,
    Color accent, {
    double? maxWidth,
  }) {
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
      width: validity == MfmBorderValidity.valid
          ? math.min(rawWidth, effectiveMaxWidth(maxWidth))
          : 0,
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

  /// 線の太さの既定の上限（logical px）。
  static const defaultMaxWidth = 1024.0;

  /// `MfmRenderConfig.maxBorderWidth`で指定できる上限（logical px）。
  ///
  /// 本家を表示するChromiumがborderの太さと要素の寸法を飽和させる値（2^25）。
  /// Chrome 157のheadlessで、`display: inline-block; border: <width>px solid`の
  /// spanを描画し、getComputedStyleのborder-top-widthとgetBoundingClientRectを
  /// 確かめた。3.4e7px以上の指定はすべて33554432pxになる（2026-11-20に計測）。
  static const browserMaxWidth = 33554432.0;

  /// 指定された上限を解決する。nullと0以下、非有限の値は[defaultMaxWidth]になる。
  static double effectiveMaxWidth(double? value) =>
      value == null || !value.isFinite || value <= 0
      ? defaultMaxWidth
      : math.min(value, browserMaxWidth);

  static final _hex = RegExp(r'^[0-9a-fA-F]{3,6}$');

  static double _number(Object? value, double fallback) =>
      jsParseFloat(value) ?? fallback;

  static bool _truthy(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0 && !value.isNaN;
    if (value is String) return value.isNotEmpty;
    return true;
  }
}
