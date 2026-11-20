import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class _SparkleParticle {
  const _SparkleParticle({
    required this.position,
    required this.size,
    required this.duration,
    required this.color,
    required this.startTime,
  });

  final Offset position;
  final double size;
  final Duration duration;
  final Color color;
  final Duration startTime;

  Duration get removalTime =>
      startTime + duration - const Duration(milliseconds: 100);

  double progressAt(Duration now) =>
      ((now - startTime).inMicroseconds / duration.inMicroseconds).clamp(
        0.0,
        1.0,
      );
}

class MfmSparkleWidget extends StatefulWidget {
  const MfmSparkleWidget({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @visibleForTesting
  static ({double size, Duration duration}) debugParticleMetrics(
    double sizeFactor,
  ) => _particleMetrics(sizeFactor);

  @visibleForTesting
  static Path debugStarPath() => _SparklePainter._createStarPath();

  /// 描画時点の粒子を変更不能なスナップショットとして取得する。
  @visibleForTesting
  static List<({Duration startTime, Duration duration, double progress})>
  debugParticleFrames(CustomPainter painter) {
    final sparkle = painter as _SparklePainter;
    return List.unmodifiable([
      for (final particle in sparkle.particles)
        (
          startTime: particle.startTime,
          duration: particle.duration,
          progress: particle.progressAt(sparkle.now),
        ),
    ]);
  }

  static ({double size, Duration duration}) _particleMetrics(
    double sizeFactor,
  ) {
    assert(sizeFactor >= 0 && sizeFactor <= 1);
    return (
      size: 0.2 + (sizeFactor / 10) * 3,
      duration: Duration(
        microseconds:
            ((1000 + sizeFactor * 1000) * Duration.microsecondsPerMillisecond)
                .round(),
      ),
    );
  }

  @override
  State<MfmSparkleWidget> createState() => _MfmSparkleWidgetState();
}

class _MfmSparkleWidgetState extends State<MfmSparkleWidget>
    with SingleTickerProviderStateMixin {
  static const _paintPadding = 32.0;

  final _particles = <_SparkleParticle>[];
  final _random = math.Random();
  late final Ticker _ticker;
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  Duration _nextSpawn = Duration.zero;
  Size _paintBounds = Size.zero;
  final GlobalKey<State<StatefulWidget>> _childKey = GlobalKey();

  static const _colors = <Color>[
    Color(0xFFFF1493),
    Color(0xFF00FFFF),
    Color(0xFFFFE202),
    Color(0xFFFFE202),
    Color(0xFFFFE202),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.enabled) {
      _scheduleStart();
    }
  }

  @override
  void didUpdateWidget(covariant MfmSparkleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) {
      return;
    }

    if (widget.enabled) {
      _scheduleStart();
    } else {
      _ticker.stop();
      _particles.clear();
      _elapsed.value = Duration.zero;
    }
  }

  void _scheduleStart() {
    // レンダリング後にサイズを取得し、最新の enabled を確認して開始する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled || _ticker.isActive) return;
      _updatePaintBounds();
      _particles.clear();
      _elapsed.value = Duration.zero;
      _nextSpawn = _randomInterval();
      _ticker.start();
    });
  }

  Duration _randomInterval() =>
      Duration(milliseconds: 500 + _random.nextInt(500));

  void _onTick(Duration elapsed) {
    _particles.removeWhere((particle) => elapsed >= particle.removalTime);
    if (elapsed >= _nextSpawn) {
      // mute やフレーム停止からの復帰でも、追いつき生成は最大1回にする。
      _addParticle(elapsed);
      _nextSpawn = elapsed + _randomInterval();
    }
    // 子全体の setState は行わず、粒子の描画部分だけを更新する。
    _elapsed.value = elapsed;
  }

  void _addParticle(Duration elapsed) {
    // 最新のサイズを取得
    _updatePaintBounds();

    if (_paintBounds.width <= 0 || _paintBounds.height <= 0) {
      return;
    }

    final usableWidth = math.max(0, _paintBounds.width - _paintPadding * 2);
    final usableHeight = math.max(0, _paintBounds.height - _paintPadding * 2);
    final sizeFactor = _random.nextDouble();
    final metrics = MfmSparkleWidget._particleMetrics(sizeFactor);
    final particle = _SparkleParticle(
      position: Offset(
        _paintPadding + _random.nextDouble() * usableWidth,
        _paintPadding + _random.nextDouble() * usableHeight,
      ),
      size: metrics.size,
      duration: metrics.duration,
      color: _colors[_random.nextInt(_colors.length)],
      startTime: elapsed,
    );

    _particles.add(particle);
  }

  void _updatePaintBounds() {
    final renderBox =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final childSize = renderBox.size;
      _paintBounds = Size(
        childSize.width + _paintPadding * 2,
        childSize.height + _paintPadding * 2,
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 子要素にGlobalKeyを割り当てる
        Container(key: _childKey, child: widget.child),
        Positioned(
          left: -_paintPadding,
          top: -_paintPadding,
          right: -_paintPadding,
          bottom: -_paintPadding,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _elapsed,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SparklePainter(
                    particles: List.unmodifiable(_particles),
                    now: _elapsed.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.particles, required this.now});

  final List<_SparkleParticle> particles;
  final Duration now;

  static final Path _starPath = _createStarPath();

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress = particle.progressAt(now);
      if (progress <= 0) {
        continue;
      }

      final scale = progress < 0.5
          ? particle.size * (progress * 2)
          : particle.size * (1 - (progress - 0.5) * 2);
      if (scale <= 0) {
        continue;
      }

      final rotation = progress * 2 * math.pi;

      canvas
        ..save()
        ..translate(particle.position.dx, particle.position.dy)
        ..rotate(rotation)
        ..scale(scale, scale)
        ..drawPath(
          _starPath,
          Paint()
            ..color = particle.color
            ..style = PaintingStyle.fill,
        )
        ..restore();
    }
  }

  static Path _createStarPath() {
    final path = Path()
      // MkSparkle.vue の 64x64 SVG path を中心原点へ平行移動する。
      ..moveTo(-2.573, -29.989)
      ..cubicTo(-2.279, -31.17, -1.218, -32, 0, -32)
      ..cubicTo(1.218, -32, 2.279, -31.17, 2.573, -29.989)
      ..lineTo(7.455, -10.354)
      ..cubicTo(7.629, -9.653, 7.991, -9.013, 8.502, -8.502)
      ..cubicTo(9.013, -7.991, 9.653, -7.629, 10.354, -7.455)
      ..lineTo(29.989, -2.573)
      ..cubicTo(31.17, -2.279, 32, -1.218, 32, 0)
      ..cubicTo(32, 1.218, 31.17, 2.279, 29.989, 2.573)
      ..lineTo(10.354, 7.455)
      ..cubicTo(9.653, 7.629, 9.013, 7.991, 8.502, 8.502)
      ..cubicTo(7.991, 9.013, 7.629, 9.653, 7.455, 10.354)
      ..lineTo(2.573, 29.989)
      ..cubicTo(2.279, 31.17, 1.218, 32, 0, 32)
      ..cubicTo(-1.218, 32, -2.279, 31.17, -2.573, 29.989)
      ..lineTo(-7.455, 10.354)
      ..cubicTo(-7.629, 9.653, -7.991, 9.013, -8.502, 8.502)
      ..cubicTo(-9.013, 7.991, -9.653, 7.629, -10.354, 7.455)
      ..lineTo(-29.989, 2.573)
      ..cubicTo(-31.17, 2.279, -32, 1.218, -32, 0)
      ..cubicTo(-32, -1.218, -31.17, -2.279, -29.989, -2.573)
      ..lineTo(-10.354, -7.455)
      ..cubicTo(-9.653, -7.629, -9.013, -7.991, -8.502, -8.502)
      ..cubicTo(-7.991, -9.013, -7.629, -9.653, -7.455, -10.354)
      ..lineTo(-2.573, -29.989)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return true;
  }
}
