import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 静的rainbow全体で共有する描画範囲。WidgetSpan内でも色の位置を揃える。
class MfmRainbowScope {
  RenderBox? _box;

  /// 独自TextPainterを使うrubyも、同じ範囲で文字だけを着色する。
  InlineSpan colorize(
    InlineSpan text,
    RenderBox target, {
    Offset origin = Offset.zero,
  }) {
    final box = _box!;
    final transform = Matrix4.translationValues(-origin.dx, -origin.dy, 0)
      ..multiply(
        Matrix4.tryInvert(target.getTransformTo(box)) ?? Matrix4.identity(),
      );
    return _withRainbowPaint(text, Offset.zero & box.size, transform);
  }
}

/// 継承色を静的rainbowで置き換えるTextSpan。明示色の子は対象外。
class MfmRainbowSpan extends TextSpan {
  const MfmRainbowSpan({
    required this.opacity,
    super.text,
    super.children,
    super.style,
    super.recognizer,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.locale,
    super.spellOut,
  });

  final double opacity;

  @override
  RenderComparison compareTo(InlineSpan other) {
    final comparison = super.compareTo(other);
    if (other is MfmRainbowSpan &&
        opacity != other.opacity &&
        comparison.index < RenderComparison.paint.index) {
      return RenderComparison.paint;
    }
    return comparison;
  }

  @override
  bool operator ==(Object other) =>
      other is MfmRainbowSpan && super == other && opacity == other.opacity;

  @override
  int get hashCode => Object.hash(super.hashCode, opacity);
}

class MfmRainbowViewport extends SingleChildRenderObjectWidget {
  const MfmRainbowViewport({
    super.key,
    required this.scope,
    required super.child,
  });

  final MfmRainbowScope scope;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final box = RenderProxyBox();
    scope._box = box;
    return box;
  }

  @override
  void updateRenderObject(BuildContext context, RenderProxyBox renderObject) {
    scope._box = renderObject;
  }
}

/// Textの継承設定を解決してから、文字のforegroundだけを置き換える。
class MfmRainbowText extends StatelessWidget {
  const MfmRainbowText({
    super.key,
    required this.scope,
    required this.text,
    this.rainbowForeground = true,
  });

  final MfmRainbowScope scope;
  final Text text;
  final bool rainbowForeground;

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    var style = defaults.style.merge(text.style);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    // Textと同じく、未移行の呼び出し側の倍率指定も尊重する。
    // ignore: deprecated_member_use
    final scaleFactor = text.textScaleFactor;
    final scaler =
        text.textScaler ??
        (scaleFactor == null
            ? MediaQuery.textScalerOf(context)
            : TextScaler.linear(scaleFactor));
    final children = text.textSpan == null ? null : [text.textSpan!];
    final span = rainbowForeground
        ? MfmRainbowSpan(
            opacity: style.foreground?.color.a ?? style.color?.a ?? 1,
            text: text.data,
            style: style,
            locale: text.locale,
            children: children,
          )
        : TextSpan(
            text: text.data,
            style: style,
            locale: text.locale,
            children: children,
          );
    Widget result = MfmRainbowRichText(
      scope: scope,
      text: span,
      textAlign: text.textAlign ?? defaults.textAlign ?? TextAlign.start,
      textDirection: text.textDirection,
      softWrap: text.softWrap ?? defaults.softWrap,
      overflow: text.overflow ?? style.overflow ?? defaults.overflow,
      textScaler: scaler,
      maxLines: text.maxLines ?? defaults.maxLines,
      locale: text.locale,
      strutStyle: text.strutStyle,
      textWidthBasis: text.textWidthBasis ?? defaults.textWidthBasis,
      textHeightBehavior:
          text.textHeightBehavior ??
          defaults.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
    );
    if (text.semanticsLabel != null || text.semanticsIdentifier != null) {
      result = Semantics(
        textDirection: text.textDirection,
        label: text.semanticsLabel,
        identifier: text.semanticsIdentifier,
        child: ExcludeSemantics(
          excluding: text.semanticsLabel != null,
          child: result,
        ),
      );
    }
    return result;
  }
}

/// 文字のforegroundだけにshaderを設定する。画像・背景・罫線は再着色しない。
class MfmRainbowRichText extends RichText {
  MfmRainbowRichText({
    super.key,
    required this.scope,
    required super.text,
    super.textAlign,
    super.textDirection,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis,
    super.textHeightBehavior,
  });

  final MfmRainbowScope scope;

  @override
  RenderParagraph createRenderObject(BuildContext context) {
    return _RenderRainbowParagraph(
      text,
      scope: scope,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    (renderObject as _RenderRainbowParagraph).scope = scope;
    super.updateRenderObject(context, renderObject);
  }
}

class _RenderRainbowParagraph extends RenderParagraph {
  _RenderRainbowParagraph(
    super.text, {
    required MfmRainbowScope scope,
    required super.textDirection,
    super.textAlign,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis,
    super.textHeightBehavior,
  }) : _scope = scope;

  MfmRainbowScope _scope;
  final _painter = TextPainter();
  InlineSpan? _lastSource;
  Rect? _lastBounds;
  Matrix4? _lastTransform;

  MfmRainbowScope get scope => _scope;
  set scope(MfmRainbowScope value) {
    if (identical(value, _scope)) return;
    _scope = value;
    _lastBounds = null;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    _painter.markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final box = _scope._box!;
    final bounds = Offset.zero & box.size;
    final transform =
        Matrix4.tryInvert(getTransformTo(box)) ?? Matrix4.identity();
    if (!identical(_lastSource, text) ||
        _lastBounds != bounds ||
        _lastTransform != transform) {
      _lastSource = text;
      _lastBounds = bounds;
      _lastTransform = transform;
      _painter.text = _withRainbowPaint(text, bounds, transform);
    }
    // 計測・hit test・semanticsはRenderParagraphに任せ、文字の描画だけを差し替える。
    // paint中にRenderParagraph.textを更新すると再レイアウトが必要になるため、
    // 同じ設定とplaceholder寸法の描画専用TextPainterを使用する。
    _painter
      ..textDirection = textDirection
      ..textAlign = textAlign
      ..textScaler = textScaler
      ..maxLines = maxLines
      ..ellipsis = overflow == TextOverflow.ellipsis ? '…' : null
      ..locale = locale
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior
      ..setPlaceholderDimensions(
        layoutInlineChildren(
          constraints.maxWidth,
          (child, constraints) => child.size,
          (child, constraints, baseline) =>
              child.getDistanceToBaseline(baseline),
        ),
      )
      ..layout(
        minWidth: constraints.minWidth,
        maxWidth: softWrap || overflow == TextOverflow.ellipsis
            ? constraints.maxWidth
            : double.infinity,
      );
    final overflows =
        _painter.width > size.width ||
        _painter.height > size.height ||
        _painter.didExceedMaxLines;
    if (overflows && overflow != TextOverflow.visible) {
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        overflow == TextOverflow.fade ? _paintFadedContents : _paintContents,
      );
    } else {
      _paintContents(context, offset);
    }
  }

  void _paintFadedContents(PaintingContext context, Offset offset) {
    // RenderParagraphと同じ省略文字寸法を使い、横または縦の末端を減光する。
    final ellipsis = TextPainter(
      text: TextSpan(style: text.style, text: '…'),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )..layout();
    final Offset start;
    final Offset end;
    if (_painter.width > size.width) {
      start = Offset(
        textDirection == TextDirection.rtl
            ? ellipsis.width
            : size.width - ellipsis.width,
        0,
      );
      end = Offset(textDirection == TextDirection.rtl ? 0 : size.width, 0);
    } else {
      start = Offset(0, size.height - ellipsis.height / 2);
      end = Offset(0, size.height);
    }
    ellipsis.dispose();
    final shader = ui.Gradient.linear(start, end, const [
      Color(0xFFFFFFFF),
      Color(0x00FFFFFF),
    ]);
    context.canvas.saveLayer(offset & size, Paint());
    _paintContents(context, offset);
    context.canvas
      ..translate(offset.dx, offset.dy)
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.modulate
          ..shader = shader,
      )
      ..restore();
  }

  void _paintContents(PaintingContext context, Offset offset) {
    // foreground shaderはcanvas座標を使うため、paragraphの原点に揃える。
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
    paintInlineChildren(context, offset);
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }
}

InlineSpan _withRainbowPaint(
  InlineSpan span,
  Rect bounds,
  Matrix4 transform, [
  double? inheritedOpacity,
]) {
  if (span is! TextSpan) return span;

  var opacity = inheritedOpacity;
  final originalStyle = span.style;
  if (span is MfmRainbowSpan) {
    opacity = span.opacity;
  } else if (originalStyle != null &&
      (!originalStyle.inherit ||
          originalStyle.color != null ||
          originalStyle.foreground != null)) {
    opacity = null;
  }

  var style = originalStyle;
  if (opacity != null) {
    style = (style ?? const TextStyle()).copyWith(
      foreground: Paint()
        ..shader = LinearGradient(
          colors: [
            for (final color in _colors) color.withValues(alpha: opacity),
          ],
          stops: _stops,
          transform: _RainbowTransform(transform),
        ).createShader(bounds),
    );
  } else if (inheritedOpacity != null && originalStyle?.color != null) {
    // 親のforeground shaderを子のcolor指定で確実に上書きする。
    style = originalStyle!.copyWith(
      foreground: Paint()..color = originalStyle.color!,
    );
  }

  final children = span.children
      ?.map((child) => _withRainbowPaint(child, bounds, transform, opacity))
      .toList();
  return TextSpan(
    text: span.text,
    children: children,
    style: style,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

// 本家の_mfm_rainbow_fallback_と同じ色と停止位置。
const _colors = <Color>[
  Color(0xFFFF0000),
  Color(0xFFFFA500),
  Color(0xFFFFFF00),
  Color(0xFF00FF00),
  Color(0xFF00FFFF),
  Color(0xFF0000FF),
  Color(0xFFFF00FF),
];
const _stops = <double>[0, 0.17, 0.33, 0.5, 0.67, 0.83, 1];

class _RainbowTransform extends GradientTransform {
  const _RainbowTransform(this.matrix);

  final Matrix4 matrix;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => matrix;
}
