import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class _JumpKeyframe {
  const _JumpKeyframe(this.t, this.y);

  final double t;
  final double y;
}

class MfmJumpWidget extends StatelessWidget {
  const MfmJumpWidget({
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
  // 0%: 0, 25%: -16px, 50%: 0, 75%: -8px, 100%: 0
  static const _keyframes = <_JumpKeyframe>[
    _JumpKeyframe(0, 0),
    _JumpKeyframe(0.25, -16),
    _JumpKeyframe(0.5, 0),
    _JumpKeyframe(0.75, -8),
    _JumpKeyframe(1, 0),
  ];

  double _resolveY(double t) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final start = _keyframes[i];
      final end = _keyframes[i + 1];

      if (t >= start.t && t <= end.t) {
        final localT = (t - start.t) / (end.t - start.t);
        return start.y + (end.y - start.y) * localT;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      child: child,
      builder: (context, child, controller) {
        final y = _resolveY(controller.value);
        return Transform.translate(
          offset: Offset(0, y),
          child: child,
        );
      },
    );
  }
}
