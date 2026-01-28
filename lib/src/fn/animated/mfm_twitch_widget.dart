import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class _TwitchKeyframe {
  const _TwitchKeyframe(this.t, this.x, this.y);

  final double t;
  final double x;
  final double y;
}

class MfmTwitchWidget extends StatelessWidget {
  const MfmTwitchWidget({
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

  // 本家CSSのキーフレームを再現（translate x, y のみ）
  static const _keyframes = <_TwitchKeyframe>[
    _TwitchKeyframe(0, 7, -2),
    _TwitchKeyframe(0.05, -3, 1),
    _TwitchKeyframe(0.10, -7, -1),
    _TwitchKeyframe(0.15, 0, -1),
    _TwitchKeyframe(0.20, -8, 6),
    _TwitchKeyframe(0.25, -4, -3),
    _TwitchKeyframe(0.30, -4, -6),
    _TwitchKeyframe(0.35, -8, -8),
    _TwitchKeyframe(0.40, 4, 6),
    _TwitchKeyframe(0.45, -3, 1),
    _TwitchKeyframe(0.50, 2, -10),
    _TwitchKeyframe(0.55, -7, 0),
    _TwitchKeyframe(0.60, -2, 4),
    _TwitchKeyframe(0.65, 3, -8),
    _TwitchKeyframe(0.70, 6, 7),
    _TwitchKeyframe(0.75, -7, -2),
    _TwitchKeyframe(0.80, -7, -8),
    _TwitchKeyframe(0.85, 9, 3),
    _TwitchKeyframe(0.90, -3, -2),
    _TwitchKeyframe(0.95, -10, 2),
    _TwitchKeyframe(1, -2, -6),
  ];

  // CSS ease = cubic-bezier(0.25, 0.1, 0.25, 1.0)
  static const Curve _twitchCurve = Cubic(0.25, 0.1, 0.25, 1);

  Offset _resolveOffset(double t) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final start = _keyframes[i];
      final end = _keyframes[i + 1];

      if (t >= start.t && t <= end.t) {
        final localT = (t - start.t) / (end.t - start.t);
        return Offset(
          start.x + (end.x - start.x) * localT,
          start.y + (end.y - start.y) * localT,
        );
      }
    }

    final last = _keyframes.last;
    return Offset(last.x, last.y);
  }

  @override
  Widget build(BuildContext context) {
    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      curve: _twitchCurve,
      child: child,
      builder: (context, child, controller, progress) {
        final offset = _resolveOffset(progress.value);
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
    );
  }
}
