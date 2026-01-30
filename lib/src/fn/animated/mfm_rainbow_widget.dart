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

  static const _rainbowBaseColors = <Color>[
    Color(0xFFFF0000),
    Color(0xFFFFA500),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
  ];

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

  static const _animatedStops = <double>[
    0,
    0.14,
    0.28,
    0.43,
    0.57,
    0.71,
    0.86,
    1,
  ];

  List<Color> _buildShiftedColors(double progress) {
    final normalized = progress % 1.0;
    final colorCount = _rainbowBaseColors.length;
    final scaled = normalized * colorCount;
    final baseIndex = scaled.floor();
    final localT = scaled - baseIndex;
    final colors = <Color>[];

    for (var i = 0; i <= colorCount; i++) {
      final index = (baseIndex + i) % colorCount;
      final nextIndex = (index + 1) % colorCount;
      final color = Color.lerp(
        _rainbowBaseColors[index],
        _rainbowBaseColors[nextIndex],
        localT,
      )!;
      colors.add(color);
    }

    return colors;
  }

  Widget _buildShaderMask(
    Widget child,
    List<Color> colors,
    List<double> stops,
  ) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: colors,
          stops: stops,
        ).createShader(bounds);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _buildShaderMask(child, _rainbowColors, _staticStops);
    }

    return MfmAnimatedWrapper(
      duration: duration,
      delay: delay,
      enabled: enabled,
      child: child,
      builder: (context, child, controller, progress) {
        final colors = _buildShiftedColors(progress.value);
        return _buildShaderMask(child, colors, _animatedStops);
      },
    );
  }
}
