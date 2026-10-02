import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../fn/mfm_border_options.dart';

/// Internal border wrapper; keeps the child element and its natural baseline.
class MfmBorder extends StatelessWidget {
  const MfmBorder({
    super.key,
    required this.options,
    required this.color,
    required this.child,
  });

  final MfmBorderOptions options;
  // Already attenuated by the builder, independently of the child text.
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: MfmBorderDecoration(options: options, color: color),
    child: ClipPath(
      clipper: options.noclip ? null : MfmBorderClipper(options),
      clipBehavior: options.noclip ? Clip.none : Clip.antiAlias,
      child: Padding(padding: EdgeInsets.all(options.width), child: child),
    ),
  );
}

/// All boundaries derive from one normalized outer radius, not independently
/// normalized inset rectangles. Empty/invalid geometry never reaches Canvas.
class MfmBorderGeometry {
  MfmBorderGeometry(this.size, this.width, double radius)
    : radius = size.width.isFinite && size.height.isFinite && radius.isFinite
          ? math.max(0, math.min(radius, math.min(size.width, size.height) / 2))
          : 0;

  final Size size;
  final double width;
  final double radius;

  bool get valid =>
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0 &&
      width.isFinite &&
      width >= 0;

  RRect? boundary(double inset) {
    if (!valid ||
        !inset.isFinite ||
        inset < 0 ||
        inset >= size.width / 2 ||
        inset >= size.height / 2) {
      return null;
    }
    return RRect.fromRectAndRadius(
      Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
      Radius.circular(math.max(0, radius - inset)),
    );
  }

  Path path(double inset) {
    final rect = boundary(inset);
    return rect == null ? Path() : (Path()..addRRect(rect));
  }

  Path ring(double start, double end) => Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(path(start), Offset.zero)
    ..addPath(path(end), Offset.zero);

  Rect get innerBounds => boundary(width)?.outerRect ?? Rect.zero;

  /// Null requests the bounded solid fallback. Check before integer conversion
  /// so huge ratios are safe on both native and JavaScript runtimes.
  int? patternCount(double length, {required bool dotted}) {
    if (!length.isFinite || length <= 0 || !width.isFinite || width <= 0) {
      return null;
    }
    final target = length / (width * (dotted ? 2 : 6));
    if (!target.isFinite || target > 2048) return null;
    return math.max(1, target.round());
  }
}

class MfmBorderClipper extends CustomClipper<Path> {
  const MfmBorderClipper(this.options);
  final MfmBorderOptions options;

  @override
  Path getClip(Size size) => MfmBorderGeometry(
    size,
    options.width,
    options.radius,
  ).path(options.width);

  @override
  Rect getApproximateClipRect(Size size) =>
      MfmBorderGeometry(size, options.width, options.radius).innerBounds;

  @override
  bool shouldReclip(MfmBorderClipper oldClipper) =>
      options.width != oldClipper.options.width ||
      options.radius != oldClipper.options.radius;
}

class MfmBorderDecoration extends Decoration {
  const MfmBorderDecoration({required this.options, required this.color});
  final MfmBorderOptions options;
  final Color color;

  // Padding is explicit in MfmBorder, exactly once.
  @override
  EdgeInsetsGeometry get padding => EdgeInsets.zero;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) => MfmBorderGeometry(
    rect.size,
    options.width,
    options.radius,
  ).path(0).shift(rect.topLeft);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _BorderPainter(this, onChanged);
}

class _BorderPainter extends BoxPainter {
  _BorderPainter(this.decoration, super.onChanged);
  final MfmBorderDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final options = decoration.options;
    final size = configuration.size;
    if (size == null ||
        options.width <= 0 ||
        decoration.color.a == 0 ||
        !offset.dx.isFinite ||
        !offset.dy.isFinite) {
      return;
    }
    final geometry = MfmBorderGeometry(size, options.width, options.radius);
    if (!geometry.valid) return;
    final width = options.width;
    final ring = geometry.ring(0, width);
    final paint = Paint()..color = decoration.color;
    canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    switch (options.style) {
      case MfmBorderStyle.hidden:
        break;
      case MfmBorderStyle.solid:
        canvas.drawPath(ring, paint);
      case MfmBorderStyle.double:
        if (width < 3) {
          canvas.drawPath(ring, paint);
        } else {
          canvas
            ..drawPath(geometry.ring(0, width / 3), paint)
            ..drawPath(geometry.ring(width * 2 / 3, width), paint);
        }
      case MfmBorderStyle.dotted:
      case MfmBorderStyle.dashed:
        _pattern(canvas, geometry, ring, paint, options.style);
      case MfmBorderStyle.inset:
      case MfmBorderStyle.outset:
        _shadeBands(
          canvas,
          geometry,
          ring,
          options.style == MfmBorderStyle.inset,
          false,
        );
      case MfmBorderStyle.groove:
      case MfmBorderStyle.ridge:
        final inset = options.style == MfmBorderStyle.groove;
        _shadeBands(canvas, geometry, ring, inset, true);
    }
    canvas.restore();
  }

  void _pattern(
    Canvas canvas,
    MfmBorderGeometry geometry,
    Path ring,
    Paint paint,
    MfmBorderStyle style,
  ) {
    final metrics = geometry.path(geometry.width / 2).computeMetrics().iterator;
    if (!metrics.moveNext()) {
      canvas.drawPath(ring, paint);
      return;
    }
    final metric = metrics.current;
    final dotted = style == MfmBorderStyle.dotted;
    final count = geometry.patternCount(metric.length, dotted: dotted);
    if (count == null) {
      canvas.drawPath(ring, paint);
      return;
    }
    final step = metric.length / count;
    canvas
      ..save()
      ..clipPath(ring);
    // Path.addRRect fixes the seam and direction; no duplicate endpoint.
    for (var i = 0; i < count; i++) {
      if (dotted) {
        final tangent = metric.getTangentForOffset(i * step);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, geometry.width / 2, paint);
        }
      } else {
        canvas.drawPath(
          metric.extractPath(i * step, (i + 0.5) * step),
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = geometry.width
            ..strokeCap = StrokeCap.butt,
        );
      }
    }
    canvas.restore();
  }

  void _shadeBands(
    Canvas canvas,
    MfmBorderGeometry geometry,
    Path ring,
    bool inset,
    bool split,
  ) {
    canvas
      ..save()
      ..clipPath(ring)
      ..saveLayer(Offset.zero & geometry.size, Paint());
    final bounds = Path()..addRect(Offset.zero & geometry.size);
    if (split) {
      final middle = geometry.path(geometry.width / 2);
      _shaded(
        canvas,
        geometry,
        Path.combine(PathOperation.difference, bounds, middle),
        inset,
      );
      _shaded(canvas, geometry, middle, !inset);
    } else {
      _shaded(canvas, geometry, bounds, inset);
    }
    canvas
      ..restore()
      ..restore();
  }

  void _shaded(
    Canvas canvas,
    MfmBorderGeometry geometry,
    Path ring,
    bool inset,
  ) {
    final color = decoration.color;
    final dark = Color.from(
      alpha: color.a,
      red: color.r * 0.5,
      green: color.g * 0.5,
      blue: color.b * 0.5,
    );
    final light = Color.from(
      alpha: color.a,
      red: (color.r + 1) * 0.5,
      green: (color.g + 1) * 0.5,
      blue: (color.b + 1) * 0.5,
    );
    final w = geometry.size.width;
    final h = geometry.size.height;
    final m = math.min(w, h) / 2;
    final topLeft = Path()
      ..addPolygon([
        Offset.zero,
        Offset(w, 0),
        Offset(w - m, m),
        Offset(m, h - m),
        Offset(0, h),
      ], true);
    final bottomRight = Path()
      ..addPolygon([
        Offset(w, 0),
        Offset(w, h),
        Offset(0, h),
        Offset(m, h - m),
        Offset(w - m, m),
      ], true);
    // Apply the AA ring once on layer composition. Hard, exclusive nearest-edge
    // partitions avoid both transparent cracks and doubled alpha at diagonals.
    canvas
      ..save()
      ..clipPath(ring, doAntiAlias: false);
    for (final entry in [
      (topLeft, inset ? dark : light),
      (bottomRight, inset ? light : dark),
    ]) {
      canvas
        ..save()
        ..clipPath(entry.$1, doAntiAlias: false)
        ..drawPaint(Paint()..color = entry.$2)
        ..restore();
    }
    canvas.restore();
  }
}
