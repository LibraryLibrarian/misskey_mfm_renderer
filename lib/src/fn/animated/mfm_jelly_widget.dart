import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class _JellyKeyframe {
  const _JellyKeyframe(this.t, this.scaleX, this.scaleY);

  final double t;
  final double scaleX;
  final double scaleY;
}

class MfmJellyWidget extends StatelessWidget {
  const MfmJellyWidget({
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

  // 本家CSSのrubberBandキーフレームを再現
  static const _keyframes = <_JellyKeyframe>[
    _JellyKeyframe(0, 1, 1),
    _JellyKeyframe(0.30, 1.25, 0.75),
    _JellyKeyframe(0.40, 0.75, 1.25),
    _JellyKeyframe(0.50, 1.15, 0.85),
    _JellyKeyframe(0.65, 0.95, 1.05),
    _JellyKeyframe(0.75, 1.05, 0.95),
    _JellyKeyframe(1, 1, 1),
  ];

  _JellyKeyframe _resolveKeyframe(double t) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final start = _keyframes[i];
      final end = _keyframes[i + 1];

      if (t >= start.t && t <= end.t) {
        final localT = (t - start.t) / (end.t - start.t);
        return _JellyKeyframe(
          t,
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
      builder: (context, child, controller, progress) {
        final kf = _resolveKeyframe(progress.value);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(kf.scaleX, kf.scaleY, 1, 1),
          child: child,
        );
      },
    );
  }
}
