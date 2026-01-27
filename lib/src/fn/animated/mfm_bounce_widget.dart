import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class _BounceKeyframe {
  const _BounceKeyframe(this.t, this.y, this.scaleX, this.scaleY);

  final double t;
  final double y;
  final double scaleX;
  final double scaleY;
}

class MfmBounceWidget extends StatelessWidget {
  const MfmBounceWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 750),
    this.delay = Duration.zero,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool enabled;

  // 本家CSSのキーフレームを再現
  // 0%: translateY(0) scale(1, 1)
  // 25%: translateY(-16px) scale(1, 1)
  // 50%: translateY(0) scale(1, 1)
  // 75%: translateY(0) scale(1.5, 0.75)
  // 100%: translateY(0) scale(1, 1)
  static const _keyframes = <_BounceKeyframe>[
    _BounceKeyframe(0, 0, 1, 1),
    _BounceKeyframe(0.25, -16, 1, 1),
    _BounceKeyframe(0.5, 0, 1, 1),
    _BounceKeyframe(0.75, 0, 1.5, 0.75),
    _BounceKeyframe(1, 0, 1, 1),
  ];

  _BounceKeyframe _resolveKeyframe(double t) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final start = _keyframes[i];
      final end = _keyframes[i + 1];

      if (t >= start.t && t <= end.t) {
        final localT = (t - start.t) / (end.t - start.t);
        return _BounceKeyframe(
          t,
          start.y + (end.y - start.y) * localT,
          start.scaleX + (end.scaleX - start.scaleX) * localT,
          start.scaleY + (end.scaleY - start.scaleY) * localT,
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
      child: child,
      builder: (context, child, controller) {
        final kf = _resolveKeyframe(controller.value);

        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(0, kf.y, 0, 1)
            ..scaleByDouble(kf.scaleX, kf.scaleY, 1, 1),
          child: child,
        );
      },
    );
  }
}
