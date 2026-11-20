import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// RichTextの型を保ち、1行の省略で消えた行頭WidgetSpanを救済する。
class MfmNowrapParagraph extends SingleChildRenderObjectWidget {
  const MfmNowrapParagraph({super.key, required RichText child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNowrapProxy();
}

class _RenderNowrapProxy extends RenderProxyBox {
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
      baseline == TextBaseline.alphabetic
      ? _alphabeticBaseline
      : super.computeDistanceToActualBaseline(baseline);
}
