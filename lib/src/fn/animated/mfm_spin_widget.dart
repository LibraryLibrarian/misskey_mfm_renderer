import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

/// spinアニメーションの軸
enum MfmSpinAxis { z, x, y }

/// spinアニメーションの方向
enum MfmSpinDirection { normal, reverse, alternate }

class MfmSpinWidget extends StatelessWidget {
  const MfmSpinWidget({
    super.key,
    required this.child,
    this.axis = MfmSpinAxis.z,
    this.direction = MfmSpinDirection.normal,
    this.duration = const Duration(milliseconds: 1500),
    this.delay = Duration.zero,
    this.enabled = true,
  });

  final Widget child;
  final MfmSpinAxis axis;
  final MfmSpinDirection direction;
  final Duration duration;
  final Duration delay;
  final bool enabled;

  double _resolveAngle(double progress) {
    final angle = progress * 2 * math.pi;
    if (direction == MfmSpinDirection.reverse) {
      return -angle;
    }
    return angle;
  }

  Matrix4 _buildTransform(double angle) {
    switch (axis) {
      case MfmSpinAxis.z:
        return Matrix4.rotationZ(angle);
      case MfmSpinAxis.x:
        return Matrix4.identity()
          ..setEntry(3, 2, 1 / 128)
          ..rotateX(angle);
      case MfmSpinAxis.y:
        return Matrix4.identity()
          ..setEntry(3, 2, 1 / 128)
          ..rotateY(angle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      reverse: direction == MfmSpinDirection.alternate,
      child: child,
      builder: (context, child, controller) {
        final angle = _resolveAngle(controller.value);
        return Transform(
          alignment: Alignment.center,
          transform: _buildTransform(angle),
          child: child,
        );
      },
    );
  }
}
