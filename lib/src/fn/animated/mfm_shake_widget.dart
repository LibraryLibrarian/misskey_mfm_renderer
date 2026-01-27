import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class _ShakeKeyframe {
  const _ShakeKeyframe(this.t, this.x, this.y, this.rotateDeg);

  final double t;
  final double x;
  final double y;
  final double rotateDeg;
}

class MfmShakeWidget extends StatelessWidget {
  const MfmShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool enabled;

  // 本家CSSのキーフレームを再現（translate x, y, rotate deg）
  static const _keyframes = <_ShakeKeyframe>[
    _ShakeKeyframe(0, -3, -1, -8),
    _ShakeKeyframe(0.05, 0, -1, -10),
    _ShakeKeyframe(0.10, 1, -3, 0),
    _ShakeKeyframe(0.15, 1, 1, 11),
    _ShakeKeyframe(0.20, -2, 1, 1),
    _ShakeKeyframe(0.25, -1, -2, -2),
    _ShakeKeyframe(0.30, -1, 2, -3),
    _ShakeKeyframe(0.35, 2, 1, 6),
    _ShakeKeyframe(0.40, -2, -3, -9),
    _ShakeKeyframe(0.45, 0, -1, -12),
    _ShakeKeyframe(0.50, 1, 2, 10),
    _ShakeKeyframe(0.55, 0, -3, 8),
    _ShakeKeyframe(0.60, 1, -1, 8),
    _ShakeKeyframe(0.65, 0, -1, -7),
    _ShakeKeyframe(0.70, -1, -3, 6),
    _ShakeKeyframe(0.75, 0, -2, 4),
    _ShakeKeyframe(0.80, -2, -1, 3),
    _ShakeKeyframe(0.85, 1, -3, -10),
    _ShakeKeyframe(0.90, 1, 0, 3),
    _ShakeKeyframe(0.95, -2, 0, -3),
    _ShakeKeyframe(1, 2, 1, 2),
  ];

  // CSS ease = cubic-bezier(0.25, 0.1, 0.25, 1.0)
  static const Curve _shakeCurve = Cubic(0.25, 0.1, 0.25, 1.0);

  _ShakeKeyframe _resolveKeyframe(double t) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final start = _keyframes[i];
      final end = _keyframes[i + 1];

      if (t >= start.t && t <= end.t) {
        final localT = (t - start.t) / (end.t - start.t);
        return _ShakeKeyframe(
          t,
          start.x + (end.x - start.x) * localT,
          start.y + (end.y - start.y) * localT,
          start.rotateDeg + (end.rotateDeg - start.rotateDeg) * localT,
        );
      }
    }

    return _keyframes.last;
  }

  @override
  Widget build(BuildContext context) {
    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      curve: _shakeCurve,
      child: child,
      builder: (context, child, controller, progress) {
        final kf = _resolveKeyframe(progress.value);
        final radians = kf.rotateDeg * math.pi / 180;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(kf.x, kf.y, 0, 1)
            ..rotateZ(radians),
          child: child,
        );
      },
    );
  }
}
