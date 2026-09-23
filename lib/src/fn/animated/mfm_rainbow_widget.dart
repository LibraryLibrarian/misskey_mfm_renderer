import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'mfm_animated_wrapper.dart';
import 'mfm_rainbow_text.dart';

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
  const MfmStaticRainbowWidget({
    super.key,
    required this.child,
    this.scope,
  });

  final Widget child;
  final MfmRainbowScope? scope;

  @override
  Widget build(BuildContext context) {
    final scope = this.scope ?? MfmRainbowScope();
    var content = child;
    // MfmRainbowWidgetを直接使う場合も、画像等をマスクせず文字だけを着色する。
    if (this.scope == null && child is Text) {
      content = MfmRainbowText(scope: scope, text: child as Text);
    }
    return MfmRainbowViewport(scope: scope, child: content);
  }
}
