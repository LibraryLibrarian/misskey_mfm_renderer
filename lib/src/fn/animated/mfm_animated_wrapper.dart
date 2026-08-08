import 'dart:async';

import 'package:flutter/widgets.dart';

typedef MfmAnimatedBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      AnimationController controller,
      Animation<double> progress,
    );

class _MfmRepeatingProgressAnimation extends Animation<double> {
  _MfmRepeatingProgressAnimation({
    required this.parent,
    required this.period,
    required this.delay,
    required this.reverse,
    required this.curve,
    required this.reverseCurve,
  });

  final AnimationController parent;
  final Duration period;
  final Duration delay;
  final bool reverse;
  final Curve curve;
  final Curve reverseCurve;

  int get _elapsedMicroseconds {
    final elapsed = parent.lastElapsedDuration?.inMicroseconds ?? 0;
    final skipped = delay.isNegative ? -delay.inMicroseconds : 0;
    return elapsed + skipped;
  }

  bool get _isPlayingReverse {
    if (!reverse || period <= Duration.zero) {
      return false;
    }
    return (_elapsedMicroseconds ~/ period.inMicroseconds).isOdd;
  }

  @override
  double get value {
    if (period <= Duration.zero) {
      return 0;
    }

    final fraction =
        (_elapsedMicroseconds % period.inMicroseconds) / period.inMicroseconds;
    final isPlayingReverse = _isPlayingReverse;
    final directedValue = isPlayingReverse ? 1 - fraction : fraction;
    final activeCurve = isPlayingReverse ? reverseCurve : curve;
    return activeCurve.transform(directedValue);
  }

  @override
  AnimationStatus get status {
    if (!parent.isAnimating) {
      return parent.status;
    }
    return _isPlayingReverse
        ? AnimationStatus.reverse
        : AnimationStatus.forward;
  }

  @override
  void addListener(VoidCallback listener) => parent.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => parent.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) {
    parent.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    parent.removeStatusListener(listener);
  }
}

/// MFMアニメーションの共通ラッパー
///
/// - 有効/無効の制御
/// - delay付きの開始制御
/// - AnimationControllerのライフサイクル管理
/// - speed/delay引数のパース補助
class MfmAnimatedWrapper extends StatefulWidget {
  const MfmAnimatedWrapper({
    super.key,
    required this.child,
    required this.builder,
    required this.duration,
    this.delay = Duration.zero,
    this.enabled = true,
    this.repeat = true,
    this.reverse = false,
    this.curve = Curves.linear,
    this.reverseCurve,
  });

  final Widget child;
  final MfmAnimatedBuilder builder;
  final Duration duration;
  final Duration delay;
  final bool enabled;
  final bool repeat;
  final bool reverse;
  final Curve curve;
  final Curve? reverseCurve;

  /// `value` は num（秒）または "1.5s" の形式を受け付ける。
  ///
  /// 未指定・不正値は null、有限の数値は符号を保った Duration を返す。
  /// 正の極小値を失わないよう、マイクロ秒単位で変換する。
  static Duration? parseTime(Object? value) {
    if (value == null) return null;
    if (value is Duration) return value;

    double? seconds;
    if (value is num) {
      seconds = value.toDouble();
    } else if (value is String) {
      final trimmed = value.trim();
      final match = RegExp(r'^(-?[\d.]+)s$').firstMatch(trimmed);
      if (match != null) {
        seconds = double.tryParse(match.group(1)!);
      } else {
        seconds = double.tryParse(trimmed);
      }
    }

    if (seconds == null || seconds.isNaN || seconds.isInfinite) {
      return null;
    }

    return Duration(microseconds: (seconds * 1000000).round());
  }

  /// `parseTime` の結果が null の場合に `fallback` を返す。
  static Duration parseTimeOrDefault(Object? value, Duration fallback) {
    return parseTime(value) ?? fallback;
  }

  /// Map形式の引数から時間を取り出してパースするヘルパー。
  static Duration parseTimeFromArgs(
    Map<String, Object?> args,
    String key,
    Duration fallback,
  ) {
    return parseTime(args[key]) ?? fallback;
  }

  @override
  State<MfmAnimatedWrapper> createState() => _MfmAnimatedWrapperState();
}

class _MfmAnimatedWrapperState extends State<MfmAnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progress;
  Timer? _delayTimer;

  Duration get _controllerDuration => widget.duration > Duration.zero
      ? widget.duration
      : const Duration(microseconds: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _controllerDuration,
      vsync: this,
    );
    _updateProgress();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant MfmAnimatedWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    final durationChanged = oldWidget.duration != widget.duration;
    if (durationChanged) {
      _controller.duration = _controllerDuration;
    }

    if (oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve ||
        oldWidget.delay != widget.delay ||
        oldWidget.repeat != widget.repeat ||
        oldWidget.reverse != widget.reverse ||
        durationChanged) {
      setState(_updateProgress);
    }

    final shouldRestart =
        oldWidget.enabled != widget.enabled ||
        oldWidget.delay != widget.delay ||
        oldWidget.repeat != widget.repeat ||
        oldWidget.reverse != widget.reverse ||
        durationChanged;

    if (shouldRestart) {
      _stopAnimation();
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!widget.enabled || widget.duration <= Duration.zero) {
      return;
    }

    if (widget.delay <= Duration.zero) {
      _startController();
      return;
    }

    _delayTimer?.cancel();
    _delayTimer = Timer(widget.delay, () {
      if (!mounted || !widget.enabled) {
        return;
      }
      _startController();
    });
  }

  void _startController() {
    if (!widget.enabled || widget.duration <= Duration.zero) {
      return;
    }

    if (widget.repeat) {
      // 負の delay は、CSS と同様にその時間だけ進行済みの位相から
      // 始める。位相計算は _MfmRepeatingProgressAnimation が担う。
      _controller.repeat(
        reverse: widget.reverse && !widget.delay.isNegative,
      );
      return;
    }

    final skippedMicroseconds = widget.delay.isNegative
        ? -widget.delay.inMicroseconds
        : 0;
    final initialValue = (skippedMicroseconds / widget.duration.inMicroseconds)
        .clamp(0.0, 1.0);
    _controller.forward(from: initialValue);
  }

  void _stopAnimation() {
    _delayTimer?.cancel();
    _controller
      ..stop()
      ..reset();
  }

  void _updateProgress() {
    if (widget.repeat && widget.delay.isNegative) {
      _progress = _MfmRepeatingProgressAnimation(
        parent: _controller,
        period: widget.duration,
        delay: widget.delay,
        reverse: widget.reverse,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve ?? widget.curve,
      );
    } else {
      _progress = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve ?? widget.curve,
      );
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.duration <= Duration.zero) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return widget.builder(
          context,
          child ?? const SizedBox.shrink(),
          _controller,
          _progress,
        );
      },
    );
  }
}
