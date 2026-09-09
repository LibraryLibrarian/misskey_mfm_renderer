import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';

class MfmRainbowWidget extends StatelessWidget {
  const MfmRainbowWidget({
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

  static const _contrastFilter = ColorFilter.matrix(<double>[
    1.5,
    0,
    0,
    0,
    -63.75,
    0,
    1.5,
    0,
    0,
    -63.75,
    0,
    0,
    1.5,
    0,
    -63.75,
    0,
    0,
    0,
    1,
    0,
  ]);

  static const _saturationFilter = ColorFilter.matrix(<double>[
    0.213 + 0.787 * 1.5,
    0.715 - 0.715 * 1.5,
    0.072 - 0.072 * 1.5,
    0,
    0,
    0.213 - 0.213 * 1.5,
    0.715 + 0.285 * 1.5,
    0.072 - 0.072 * 1.5,
    0,
    0,
    0.213 - 0.213 * 1.5,
    0.715 - 0.715 * 1.5,
    0.072 + 0.928 * 1.5,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  static List<double> _hueRotateMatrix(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return <double>[
      0.213 + 0.787 * cos - 0.213 * sin,
      0.715 - 0.715 * cos - 0.715 * sin,
      0.072 - 0.072 * cos + 0.928 * sin,
      0,
      0,
      0.213 - 0.213 * cos + 0.143 * sin,
      0.715 + 0.285 * cos + 0.140 * sin,
      0.072 - 0.072 * cos - 0.283 * sin,
      0,
      0,
      0.213 - 0.213 * cos - 0.787 * sin,
      0.715 - 0.715 * cos + 0.715 * sin,
      0.072 + 0.928 * cos + 0.072 * sin,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return MfmStaticRainbowWidget(child: child);
    }

    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      child: child,
      builder: (context, child, controller, progress) {
        // CSS の fill-mode: none に合わせ、正の delay 待機中は素の子を表示する。
        if (delay > Duration.zero && !controller.isAnimating) {
          return child;
        }

        // CSS は各 filter の出力をクランプするため、単一の合成行列ではなく
        // 内側から hue-rotate → contrast → saturate の3段で適用する。
        return ColorFiltered(
          colorFilter: _saturationFilter,
          child: ColorFiltered(
            colorFilter: _contrastFilter,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(
                _hueRotateMatrix(progress.value * 2 * math.pi),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class MfmStaticRainbowWidget extends StatelessWidget {
  const MfmStaticRainbowWidget({super.key, required this.child});

  final Widget child;

  // 本家の_mfm_rainbow_fallback_と同じ色と停止位置。
  static const _rainbowColors = <Color>[
    Color(0xFFFF0000),
    Color(0xFFFFA500),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  static const _staticStops = <double>[
    0,
    0.17,
    0.33,
    0.5,
    0.67,
    0.83,
    1,
    1,
  ];

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: _rainbowColors,
        stops: _staticStops,
      ).createShader(bounds),
      child: child,
    );
  }
}
