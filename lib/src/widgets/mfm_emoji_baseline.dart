// Internal shared widget; keep the extracted render-object API unchanged.
// ignore_for_file: use_key_in_widget_constructors
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Baseline shifts its child to an existing baseline; it does not assign an
// image a baseline above its bottom. Report a baseline without moving or
// resizing the box, so the paragraph reserves the descent as well as ascent.
class MfmEmojiBaseline extends SingleChildRenderObjectWidget {
  const MfmEmojiBaseline({
    required this.offset,
    this.useNaturalBaseline,
    required super.child,
  });

  final double offset;
  final ValueListenable<bool>? useNaturalBaseline;

  @override
  _RenderEmojiBaseline createRenderObject(BuildContext context) =>
      _RenderEmojiBaseline(offset, useNaturalBaseline);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEmojiBaseline renderObject,
  ) {
    renderObject
      ..offset = offset
      ..useNaturalBaseline = useNaturalBaseline;
  }
}

class _RenderEmojiBaseline extends RenderProxyBox {
  _RenderEmojiBaseline(this._offset, this._useNaturalBaseline);

  double _offset;
  ValueListenable<bool>? _useNaturalBaseline;

  ValueListenable<bool>? get useNaturalBaseline => _useNaturalBaseline;

  set useNaturalBaseline(ValueListenable<bool>? value) {
    if (identical(_useNaturalBaseline, value)) return;
    if (attached) _useNaturalBaseline?.removeListener(markNeedsLayout);
    _useNaturalBaseline = value;
    if (attached) _useNaturalBaseline?.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _useNaturalBaseline?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _useNaturalBaseline?.removeListener(markNeedsLayout);
    super.detach();
  }

  double get offset => _offset;

  set offset(double value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsLayout();
  }

  late double _baseline;

  @override
  void performLayout() {
    super.performLayout();
    _baseline = size.height - _offset;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _useNaturalBaseline?.value ?? false
      ? super.computeDistanceToActualBaseline(baseline)
      : _baseline;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _useNaturalBaseline?.value ?? false
      ? super.computeDryBaseline(constraints, baseline)
      : getDryLayout(constraints).height - _offset;
}
