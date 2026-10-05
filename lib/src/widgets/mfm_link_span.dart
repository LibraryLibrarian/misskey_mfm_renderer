import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../fn/animated/mfm_rainbow_text.dart';
import 'mfm_mention_text_span.dart';

/// Adds a link fallback to a fully built label, without entering widget trees.
/// A child's own recognizer takes precedence over the surrounding link.
InlineSpan adaptMfmLinkSpan(InlineSpan span, TapGestureRecognizer recognizer) {
  if (span is WidgetSpan) {
    return WidgetSpan(
      style: span.style,
      alignment: span.alignment,
      baseline: span.baseline,
      child: _MfmLinkBridge(recognizer: recognizer, child: span.child),
    );
  }
  if (span is! TextSpan || span.recognizer != null) return span;
  // Unknown subclasses may customize layout or semantics; do not flatten them.
  if (span.runtimeType != TextSpan &&
      span is! MfmRainbowSpan &&
      span is! MfmMentionTextSpan) {
    return span;
  }
  final children = span.children
      ?.map((child) => adaptMfmLinkSpan(child, recognizer))
      .toList();
  if (span is MfmMentionTextSpan) {
    return MfmMentionTextSpan(children: children, recognizer: recognizer);
  }
  final fallback = span.text?.isNotEmpty == true ? recognizer : null;
  final cursor = fallback == null ? span.mouseCursor : SystemMouseCursors.click;
  if (span is MfmRainbowSpan) {
    return MfmRainbowSpan(
      opacity: span.opacity,
      text: span.text,
      children: children,
      style: span.style,
      recognizer: fallback,
      mouseCursor: cursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      semanticsIdentifier: span.semanticsIdentifier,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
  return TextSpan(
    text: span.text,
    children: children,
    style: span.style,
    recognizer: fallback,
    mouseCursor: cursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

/// The already atomic WidgetSpan rectangle is the fallback hit surface.
/// Descendant gesture recognizers still enter the arena before this listener.
class _MfmLinkBridge extends StatelessWidget {
  const _MfmLinkBridge({required this.recognizer, required this.child});

  final TapGestureRecognizer recognizer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      onTap: recognizer.onTap,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: recognizer.addPointer,
        child: child,
      ),
    );
  }
}
