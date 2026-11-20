import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// RichTextの型を保ち、1行の省略で消えた行頭WidgetSpanを救済する。
///
/// [enabled]がtrueのとき、子はnowrapの1行省略（softWrap: false、
/// TextOverflow.ellipsis）のRichTextであること。子の省略設定はここで上書きする。
/// falseのときは子をそのままlayoutする。設定によらず常に挟むことで、
/// 省略の有無が変わってもinline widgetのStateを保つ。
///
/// 制限: dry layout・intrinsic・dry baselineは、直前の実layoutで選んだ
/// 設定（省略か切り取り）のまま子に委ねる。行頭のwidgetの後に大きな文字が
/// 続き、直前に切り取りへ切り替えていた場合は、実際の高さと異なりうる。
class MfmNowrapParagraph extends SingleChildRenderObjectWidget {
  const MfmNowrapParagraph({
    super.key,
    required this.enabled,
    required RichText child,
  }) : super(child: child);

  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNowrapProxy(enabled: enabled);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderNowrapProxy).enabled = enabled;
  }
}

class _RenderNowrapProxy extends RenderProxyBox {
  _RenderNowrapProxy({required bool enabled}) : _enabled = enabled;

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsLayout();
  }

  double? _alphabeticBaseline;

  bool _startsWithWidget(InlineSpan text) {
    var offset = 0;
    var startsWithWidget = false;
    text.visitChildren((span) {
      if (span is WidgetSpan) {
        startsWithWidget = offset == 0;
        return false;
      }
      if (span is TextSpan) offset += span.text?.length ?? 0;
      return true;
    });
    // UTF-16の実際の文字offsetを使う。空白やZWSPも取り除かない。
    // 最初のWidgetSpanだけが対象なので、先行するWidgetSpanも飛ばさない。
    return startsWithWidget;
  }

  void _setLayoutMode(RenderParagraph paragraph, {required bool clip}) {
    final wrap = clip;
    final lines = clip ? 1 : null;
    final mode = clip ? TextOverflow.clip : TextOverflow.ellipsis;
    if (paragraph.softWrap == wrap &&
        paragraph.maxLines == lines &&
        paragraph.overflow == mode) {
      return;
    }

    // layout中に子のsetterを呼ぶと、dirty化を禁止するassertに当たる。
    // SDKはassertを緩めるinvokeLayoutCallbackを一般利用非推奨としている。
    // ここではこの段落の設定変更にだけ使用し、子の構成は変えない。
    invokeLayoutCallback<BoxConstraints>((_) {
      paragraph
        ..softWrap = wrap
        ..maxLines = lines
        ..overflow = mode;
    });
  }

  @override
  void performLayout() {
    final paragraph = child! as RenderParagraph;
    if (!_enabled) {
      // RichTextの設定のままlayoutする。
      paragraph.layout(constraints, parentUsesSize: true);
      size = paragraph.size;
      _alphabeticBaseline = null;
      return;
    }
    _setLayoutMode(paragraph, clip: false);
    paragraph.layout(constraints, parentUsesSize: true);
    final inline = paragraph.firstChild;
    if (inline != null &&
        (inline.parentData! as TextParentData).offset == null &&
        _startsWithWidget(paragraph.text)) {
      // 有限幅の1行で切り取り、RTLでも後続テキストを外側に残す。
      _setLayoutMode(paragraph, clip: true);
      paragraph.layout(constraints, parentUsesSize: true);
    }
    size = paragraph.size;
    // baselineへの依存も記録する。RenderBox.markNeedsLayoutはbaselineの
    // cacheがある子の変更を親へ伝えるため、tightな制約で子がrelayout
    // boundaryになっても、この親で省略設定を再判定できる。
    _alphabeticBaseline = paragraph.getDistanceToBaseline(
      TextBaseline.alphabetic,
      onlyReal: true,
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _enabled && baseline == TextBaseline.alphabetic
      ? _alphabeticBaseline
      : super.computeDistanceToActualBaseline(baseline);
}
