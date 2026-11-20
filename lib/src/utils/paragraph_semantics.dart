import 'package:flutter/widgets.dart';

/// Flutter 3.38でsemantic boundaryが変化した段落を古いqueueに残さない。
/// 通常のstyle・callback更新では同じ段落と子widgetを維持する。
Key paragraphSemanticsKey(InlineSpan text) => ValueKey<bool>(
  text.getSemanticsInformation().any(
    (info) => info.recognizer != null || info.semanticsIdentifier != null,
  ),
);
