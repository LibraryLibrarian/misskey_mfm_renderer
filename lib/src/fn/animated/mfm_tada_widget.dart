import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class _TadaKeyframe {
  const _TadaKeyframe(this.t, this.scale, this.rotateDeg);

  final double t;
  final double scale;
  final double rotateDeg;
}

class MfmTadaWidget extends StatelessWidget {
  const MfmTadaWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool enabled;

  // 本家CSSのglobal-tadaキーフレームを再現
  static const _keyframes = <_TadaKeyframe>[
    _TadaKeyframe(0, 1, 0),
    _TadaKeyframe(0.10, 0.91, -2),
    _TadaKeyframe(0.20, 0.91, -2),
    _TadaKeyframe(0.30, 1.09, 2),
    _TadaKeyframe(0.50, 1.09, -2),
    _TadaKeyframe(0.70, 1.09, 2),
    _TadaKeyframe(0.90, 1.09, -2),
    _TadaKeyframe(1, 1, 0),
  ];

  _TadaKeyframe _resolveKeyframe(double t) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final start = _keyframes[i];
      final end = _keyframes[i + 1];

      if (t >= start.t && t <= end.t) {
        final localT = (t - start.t) / (end.t - start.t);
        return _TadaKeyframe(
          t,
          start.scale + (end.scale - start.scale) * localT,
          start.rotateDeg + (end.rotateDeg - start.rotateDeg) * localT,
        );
      }
    }

    return _keyframes.last;
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scaleByDouble(1.5, 1.5, 1, 1),
        child: child,
      );
    }

    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      child: child,
      builder: (context, child, controller, progress) {
        final kf = _resolveKeyframe(progress.value);
        final radians = kf.rotateDeg * math.pi / 180;
        final totalScale = 1.5 * kf.scale;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(totalScale, totalScale, 1, 1)
            ..rotateZ(radians),
          child: child,
        );
      },
    );
  }
}
