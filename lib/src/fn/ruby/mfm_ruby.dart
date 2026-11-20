import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import '../../builder/mfm_node_builder.dart';
import '../../utils/nyaize.dart';

/// ベースの装飾とインラインウィジェットを保ち、その上にルビを配置する。
InlineSpan buildMfmRuby(FnNode node, MfmNodeBuilder builder) {
  if (node.children.isEmpty) {
    return TextSpan(children: builder.buildNodes(node.children));
  }

  final InlineSpan baseSpan;
  final String rubyText;
  final lastChild = node.children.last;
  if (node.children.length == 1 && lastChild is TextNode) {
    // 全文をnyaizeしてから半角空白で分割し、2番目だけをルビにする。
    // 空白依存の変換があるため、分割前に適用する。
    final raw = builder.shouldNyaize ? nyaize(lastChild.text) : lastChild.text;
    final parts = raw.split(' ');
    if (parts.length < 2 || parts[1].isEmpty) {
      return TextSpan(children: builder.buildNodes(node.children));
    }
    baseSpan = TextSpan(text: parts[0]);
    rubyText = parts[1];
  } else {
    // 最後のテキストをルビ、それ以外の子をベースにする。
    // 末尾が非テキストか空白のみの場合は、従来どおり全子をそのまま表示する。
    if (lastChild is! TextNode || lastChild.text.trim().isEmpty) {
      return TextSpan(children: builder.buildNodes(node.children));
    }
    baseSpan = TextSpan(
      children: builder.buildNodes(
        node.children.sublist(0, node.children.length - 1),
      ),
    );
    // ベース側はbuildNodes経由で変換し、ルビ側はトリム前にnyaizeする。
    rubyText = (builder.shouldNyaize ? nyaize(lastChild.text) : lastChild.text)
        .trim();
  }

  final rubyBuilder = builder.withStyle(
    TextStyle(fontSize: builder.effectiveStyle.fontSize! * 0.5, height: 1),
  );
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    // 内部リンクの有無によらず、ベース、ルビの順で読み上げる。
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      child: _MfmRubyLayout(
        // 各子の階層を分け、RichTextのSemantics用キーの重複も避ける。
        base: Semantics(
          container: true,
          sortKey: const OrdinalSortKey(0),
          child: builder.buildInlineRichText([baseSpan]),
        ),
        ruby: Semantics(
          container: true,
          sortKey: const OrdinalSortKey(1),
          child: rubyBuilder.buildInlineRichText(
            [TextSpan(text: rubyText)],
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

enum _RubySlot { base, ruby }

class _MfmRubyLayout
    extends SlottedMultiChildRenderObjectWidget<_RubySlot, RenderBox> {
  const _MfmRubyLayout({required this.base, required this.ruby});

  final Widget base;
  final Widget ruby;

  @override
  Iterable<_RubySlot> get slots => _RubySlot.values;

  @override
  Widget? childForSlot(_RubySlot slot) => switch (slot) {
    _RubySlot.base => base,
    _RubySlot.ruby => ruby,
  };

  @override
  _RenderMfmRuby createRenderObject(BuildContext context) => _RenderMfmRuby();
}

/// ルビを上段に置き、下段のベースのbaselineを親段落へ返す。
class _RenderMfmRuby extends RenderBox
    with SlottedContainerRenderObjectMixin<_RubySlot, RenderBox> {
  RenderBox get base => childForSlot(_RubySlot.base)!;
  RenderBox get ruby => childForSlot(_RubySlot.ruby)!;

  @override
  Iterable<RenderBox> get children =>
      // attach時は子がまだ揃っていない場合がある。
      _RubySlot.values.map(childForSlot).whereType<RenderBox>();

  BoxConstraints _constraintsForChildren(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: constraints.maxWidth);

  Size _computeSize(BoxConstraints constraints, Size baseSize, Size rubySize) =>
      constraints.constrain(
        Size(
          math.max(baseSize.width, rubySize.width),
          baseSize.height + rubySize.height,
        ),
      );

  @override
  void performLayout() {
    final childConstraints = _constraintsForChildren(constraints);
    base.layout(childConstraints, parentUsesSize: true);
    ruby.layout(childConstraints, parentUsesSize: true);
    size = _computeSize(constraints, base.size, ruby.size);
    // BoxParentDataのoffsetをpaint、hit test、既定のapplyPaintTransformで共有する。
    (base.parentData! as BoxParentData).offset = Offset(
      (size.width - base.size.width) / 2,
      ruby.size.height,
    );
    (ruby.parentData! as BoxParentData).offset = Offset(
      (size.width - ruby.size.width) / 2,
      0,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childConstraints = _constraintsForChildren(constraints);
    return _computeSize(
      constraints,
      base.getDryLayout(childConstraints),
      ruby.getDryLayout(childConstraints),
    );
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    // 親段落のdry計測では、実際の子のsizeやoffsetを変更しない。
    final childConstraints = _constraintsForChildren(constraints);
    final baseBaseline = base.getDryBaseline(childConstraints, baseline);
    return baseBaseline == null
        ? null
        : ruby.getDryLayout(childConstraints).height + baseBaseline;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final baseBaseline = base.getDistanceToActualBaseline(baseline);
    // 祖先のlayout中にも呼ばれるため、子のsizeではなく保存済みの配置を参照する。
    return baseBaseline == null
        ? null
        : (base.parentData! as BoxParentData).offset.dy + baseBaseline;
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    base.getMinIntrinsicWidth(double.infinity),
    ruby.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    base.getMaxIntrinsicWidth(double.infinity),
    ruby.getMaxIntrinsicWidth(double.infinity),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      base.getMinIntrinsicHeight(width) + ruby.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      base.getMaxIntrinsicHeight(width) + ruby.getMaxIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // 描画順と逆に調べ、ベース内のリンクなどのhit testを子へ委譲する。
    for (final child in [ruby, base]) {
      if (result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, position) =>
            child.hitTest(result, position: position),
      )) {
        return true;
      }
    }
    return false;
  }
}
