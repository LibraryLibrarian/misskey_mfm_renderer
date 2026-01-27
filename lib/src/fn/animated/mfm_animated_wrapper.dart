import 'dart:async';

import 'package:flutter/widgets.dart';

typedef MfmAnimatedBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      AnimationController controller,
      Animation<double> progress,
    );

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

  /// `value` は num（秒）または "1.5s" の形式を受け付ける
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

    final safeSeconds = seconds < 0 ? 0.0 : seconds;
    return Duration(milliseconds: (safeSeconds * 1000).round());
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _updateProgress();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant MfmAnimatedWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    if (oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve) {
      setState(_updateProgress);
    }

    final shouldRestart =
        oldWidget.enabled != widget.enabled ||
        oldWidget.delay != widget.delay ||
        oldWidget.repeat != widget.repeat ||
        oldWidget.reverse != widget.reverse;

    if (shouldRestart) {
      _stopAnimation();
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!widget.enabled) {
      return;
    }

    if (widget.delay == Duration.zero) {
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
    if (widget.repeat) {
      _controller.repeat(reverse: widget.reverse);
      return;
    }
    _controller.forward();
  }

  void _stopAnimation() {
    _delayTimer?.cancel();
    _controller
      ..stop()
      ..reset();
  }

  void _updateProgress() {
    _progress = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve ?? widget.curve,
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
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
