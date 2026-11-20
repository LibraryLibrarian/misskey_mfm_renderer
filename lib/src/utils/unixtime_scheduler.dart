import 'dart:async';

import 'package:flutter/widgets.dart';

/// mountedな日時ラベルだけが共有する低頻度の時計。
class UnixtimeScheduler with WidgetsBindingObserver {
  UnixtimeScheduler._();

  static final instance = UnixtimeScheduler._();
  final _listeners = <void Function(DateTime)>{};
  Timer? _timer;
  bool _active = false;

  void subscribe(void Function(DateTime) listener) {
    if (_listeners.isEmpty) {
      final binding = WidgetsBinding.instance;
      // observer登録後の現在状態を初回購読にも適用する。
      // ignore: cascade_invocations
      binding.addObserver(this);
      _active = _isActive(binding.lifecycleState);
    }
    _listeners.add(listener);
    _start();
  }

  void unsubscribe(void Function(DateTime) listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _timer?.cancel();
      _timer = null;
      WidgetsBinding.instance.removeObserver(this);
      _active = false;
    }
  }

  bool _isActive(AppLifecycleState? state) =>
      state != AppLifecycleState.hidden &&
      state != AppLifecycleState.paused &&
      state != AppLifecycleState.detached;

  void _start() {
    if (_active && _listeners.isNotEmpty && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) => _broadcast());
    }
  }

  void _broadcast() {
    final now = DateTime.now();
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener(now);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = _isActive(state);
    if (_active == active) return;
    _active = active;
    if (!active) {
      _timer?.cancel();
      _timer = null;
    } else {
      _broadcast();
      _start();
    }
  }
}
