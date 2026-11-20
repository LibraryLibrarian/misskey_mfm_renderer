import 'package:flutter/gestures.dart';

/// Separates targets handled by different callbacks and node presentations.
enum MfmTapRecognizerKind { url, link, mention, hashtag }

/// Owns recognizers for the synchronously built spans of one MfmText State.
class MfmTapRecognizerPool {
  final _recognizers =
      <(MfmTapRecognizerKind, String, int), TapGestureRecognizer>{};
  final _callbacks =
      <(MfmTapRecognizerKind, String, int), GestureTapCallback>{};
  final _occurrences = <(MfmTapRecognizerKind, String), int>{};
  final _used = <(MfmTapRecognizerKind, String, int)>{};

  void beginBuild() {
    _occurrences.clear();
    _used.clear();
  }

  TapGestureRecognizer acquire(
    MfmTapRecognizerKind kind,
    String target,
    GestureTapCallback onTap,
  ) {
    final identity = (kind, target);
    final occurrence = _occurrences[identity] ?? 0;
    _occurrences[identity] = occurrence + 1;
    final key = (kind, target, occurrence);
    _used.add(key);
    _callbacks[key] = onTap;
    // A new target must not inherit an in-flight tap from the old target.
    return _recognizers.putIfAbsent(
      key,
      // Semantics may retain onTap across builds; keep this forwarder stable.
      () => TapGestureRecognizer()..onTap = () => _callbacks[key]?.call(),
    );
  }

  void endBuild() {
    _recognizers.removeWhere((key, recognizer) {
      if (_used.contains(key)) return false;
      recognizer.dispose();
      _callbacks.remove(key);
      return true;
    });
  }

  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    _callbacks.clear();
    _occurrences.clear();
    _used.clear();
  }
}
