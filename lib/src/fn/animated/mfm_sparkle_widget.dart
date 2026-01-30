import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class _SparkleParticle {
  const _SparkleParticle({
    required this.id,
    required this.position,
    required this.size,
    required this.duration,
    required this.color,
    required this.startTime,
  });

  final String id;
  final Offset position;
  final double size;
  final Duration duration;
  final Color color;
  final DateTime startTime;
}

class MfmSparkleWidget extends StatefulWidget {
  const MfmSparkleWidget({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<MfmSparkleWidget> createState() => _MfmSparkleWidgetState();
}

class _MfmSparkleWidgetState extends State<MfmSparkleWidget>
    with TickerProviderStateMixin {
  static const _paintPadding = 32.0;
  static const _minDurationMs = 1000;
  static const _maxDurationMs = 2000;

  final _particles = <_SparkleParticle>[];
  final _random = math.Random();
  Timer? _spawnTimer;
  late final AnimationController _ticker;
  Size _paintBounds = Size.zero;

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
    _ticker = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );
    if (widget.enabled) {
      _startTicker();
      _scheduleNextParticle();
    }
  }

  @override
  void didUpdateWidget(covariant MfmSparkleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) {
      return;
    }

    if (widget.enabled) {
      _startTicker();
      _scheduleNextParticle();
    } else {
      _stopTicker();
      _clearParticles();
    }
  }

  void _startTicker() {
    if (!_ticker.isAnimating) {
      _ticker.repeat();
    }
  }

  void _stopTicker() {
    _spawnTimer?.cancel();
    if (_ticker.isAnimating) {
      _ticker.stop();
    }
  }

  void _clearParticles() {
    if (_particles.isEmpty) {
      return;
    }
    setState(_particles.clear);
  }

  void _scheduleNextParticle() {
    _spawnTimer?.cancel();
    final delayMs = 500 + _random.nextInt(500);
    _spawnTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !widget.enabled) {
        return;
      }
      _addParticle();
      _scheduleNextParticle();
    });
  }

  void _addParticle() {
    if (_paintBounds.width <= 0 || _paintBounds.height <= 0) {
      return;
    }

    final usableWidth = math.max(0, _paintBounds.width - _paintPadding * 2);
    final usableHeight = math.max(0, _paintBounds.height - _paintPadding * 2);
    final size = 0.2 + _random.nextDouble() * 0.3;
    final durationMs =
        _minDurationMs + _random.nextInt(_maxDurationMs - _minDurationMs + 1);
    final particle = _SparkleParticle(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      position: Offset(
        _paintPadding + _random.nextDouble() * usableWidth,
        _paintPadding + _random.nextDouble() * usableHeight,
      ),
      size: size,
      duration: Duration(milliseconds: durationMs),
      color: _colors[_random.nextInt(_colors.length)],
      startTime: DateTime.now(),
    );

    setState(() {
      _particles.add(particle);
    });

    Timer(particle.duration - const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _particles.removeWhere((item) => item.id == particle.id);
      });
    });
  }

  void _updatePaintBounds(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
    final height = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
    _paintBounds = Size(
      width + _paintPadding * 2,
      height + _paintPadding * 2,
    );
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _updatePaintBounds(constraints);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              left: -_paintPadding,
              top: -_paintPadding,
              right: -_paintPadding,
              bottom: -_paintPadding,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _ticker,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SparklePainter(
                        particles: _particles,
                        now: DateTime.now(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.particles,
    required this.now,
  });

  final List<_SparkleParticle> particles;
  final DateTime now;

  static final Path _starPath = _createStarPath();

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final elapsedMs = now.difference(particle.startTime).inMilliseconds;
      final progress = (elapsedMs / particle.duration.inMilliseconds).clamp(
        0.0,
        1.0,
      );
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
    const size = 32.0;
    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.2, -size * 0.2, size, 0)
      ..quadraticBezierTo(size * 0.2, size * 0.2, 0, size)
      ..quadraticBezierTo(-size * 0.2, size * 0.2, -size, 0)
      ..quadraticBezierTo(-size * 0.2, -size * 0.2, 0, -size)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return true;
  }
}
