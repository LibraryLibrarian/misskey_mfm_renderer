import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../builder/mfm_node_builder.dart';
import '../utils/color_parser.dart';
import 'animated/mfm_animated_wrapper.dart';
import 'animated/mfm_bounce_widget.dart';
import 'animated/mfm_jump_widget.dart';
import 'animated/mfm_spin_widget.dart';

/// fn関数のハンドラー
class MfmFnHandler {
  MfmFnHandler._();

  /// FnNodeをInlineSpanに変換
  static InlineSpan build(FnNode node, MfmNodeBuilder builder) {
    switch (node.name) {
      // サイズ系
      case 'x2':
      case 'x3':
      case 'x4':
        return _buildSize(node, builder);

      // 変換系
      case 'flip':
        return _buildFlip(node, builder);
      case 'rotate':
        return _buildRotate(node, builder);
      case 'scale':
        return _buildScale(node, builder);
      case 'position':
        return _buildPosition(node, builder);

      // スタイル系
      case 'fg':
        return _buildFg(node, builder);
      case 'bg':
        return _buildBg(node, builder);
      case 'border':
        return _buildBorder(node, builder);
      case 'font':
        return _buildFont(node, builder);

      // 特殊
      case 'blur':
        return _buildBlur(node, builder);
      case 'ruby':
        return _buildRuby(node, builder);
      case 'unixtime':
        return _buildUnixtime(node, builder);

      // アニメーション系（将来実装）
      case 'tada':
      case 'jelly':
      case 'twitch':
      case 'shake':
      case 'spin':
        return _buildSpin(node, builder);
      case 'jump':
        return _buildJump(node, builder);
      case 'bounce':
        return _buildBounce(node, builder);
      case 'rainbow':
      case 'sparkle':
        return _buildAnimatedPlaceholder(node, builder);

      default:
        // 未知のfn関数は子要素をそのまま表示
        return TextSpan(children: builder.buildNodes(node.children));
    }
  }

  // 各fn関数の実装（初期はプレースホルダー、後続タスクで実装）

  static InlineSpan _buildSize(FnNode node, MfmNodeBuilder builder) {
    double sizeMultiplier;
    switch (node.name) {
      case 'x2':
        sizeMultiplier = 2.0;
      case 'x3':
        sizeMultiplier = 3.0;
      case 'x4':
        sizeMultiplier = 4.0;
      default:
        sizeMultiplier = 1.0;
    }

    final effectiveMultiplier =
        1.0 + (sizeMultiplier - 1.0) * (1.0 / builder.scale);
    final newScale = builder.scale * effectiveMultiplier;

    final scaledBuilder = builder.withScale(newScale);
    final children = scaledBuilder.buildNodes(node.children);

    final baseSize = builder.config.baseTextStyle?.fontSize ?? 14.0;

    return TextSpan(
      style: TextStyle(fontSize: baseSize * effectiveMultiplier),
      children: children,
    );
  }

  static InlineSpan _buildFlip(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final flipH = args.containsKey('h') || args.containsKey('');
    final flipV = args.containsKey('v');

    final scaleX = flipH ? -1.0 : 1.0;
    final scaleY = flipV ? -1.0 : 1.0;

    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildRotate(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;

    // deg引数を取得（デフォルト: 90度）
    var degrees = 90.0;
    if (args.containsKey('deg')) {
      final degValue = args['deg'];
      if (degValue is num) {
        degrees = degValue.toDouble();
      } else if (degValue is String) {
        degrees = double.tryParse(degValue) ?? 90.0;
      }
    }

    final radians = degrees * math.pi / 180.0;
    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      child: Transform.rotate(
        angle: radians,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildSpin(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.enableAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;

    final axis = args.containsKey('x')
        ? MfmSpinAxis.x
        : args.containsKey('y')
        ? MfmSpinAxis.y
        : MfmSpinAxis.z;

    final direction = args.containsKey('left')
        ? MfmSpinDirection.reverse
        : args.containsKey('alternate')
        ? MfmSpinDirection.alternate
        : MfmSpinDirection.normal;

    final duration =
        MfmAnimatedWrapper.parseTime(args['speed']) ??
        const Duration(milliseconds: 1500);
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      child: MfmSpinWidget(
        axis: axis,
        direction: direction,
        duration: duration,
        delay: delay,
        enabled: builder.config.enableAnimation,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildJump(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.enableAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration =
        MfmAnimatedWrapper.parseTime(args['speed']) ??
        const Duration(milliseconds: 750);
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      child: MfmJumpWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.enableAnimation,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildBounce(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.enableAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration =
        MfmAnimatedWrapper.parseTime(args['speed']) ??
        const Duration(milliseconds: 750);
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      child: MfmBounceWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.enableAnimation,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildScale(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;

    // x, y引数を取得（デフォルト: 1.0）
    var scaleX = 1.0;
    var scaleY = 1.0;

    if (args.containsKey('x')) {
      final xValue = args['x'];
      if (xValue is num) {
        scaleX = xValue.toDouble().clamp(-5.0, 5.0);
      } else if (xValue is String) {
        scaleX = (double.tryParse(xValue) ?? 1.0).clamp(-5.0, 5.0);
      }
    }

    if (args.containsKey('y')) {
      final yValue = args['y'];
      if (yValue is num) {
        scaleY = yValue.toDouble().clamp(-5.0, 5.0);
      } else if (yValue is String) {
        scaleY = (double.tryParse(yValue) ?? 1.0).clamp(-5.0, 5.0);
      }
    }

    // スケールを伝播
    final newScale = builder.scale * ((scaleX.abs() + scaleY.abs()) / 2);
    final scaledBuilder = builder.withScale(newScale);
    final children = scaledBuilder.buildNodes(node.children);

    return WidgetSpan(
      child: Transform.scale(
        scaleX: scaleX,
        scaleY: scaleY,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildPosition(FnNode node, MfmNodeBuilder builder) {
    // advancedMfmが無効な場合は子要素をそのまま表示
    if (!builder.config.enableAdvancedMfm) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;

    // x, y引数を取得（em単位）
    var x = 0.0;
    var y = 0.0;

    if (args.containsKey('x')) {
      final xValue = args['x'];
      if (xValue is num) {
        x = xValue.toDouble();
      } else if (xValue is String) {
        x = double.tryParse(xValue) ?? 0.0;
      }
    }

    if (args.containsKey('y')) {
      final yValue = args['y'];
      if (yValue is num) {
        y = yValue.toDouble();
      } else if (yValue is String) {
        y = double.tryParse(yValue) ?? 0.0;
      }
    }

    final children = builder.buildNodes(node.children);

    // emをピクセルに変換（ベースフォントサイズを使用）
    final baseSize = builder.config.baseTextStyle?.fontSize ?? 14.0;
    final offsetX = x * baseSize;
    final offsetY = y * baseSize;

    return WidgetSpan(
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static Color? _parseColorArg(Map<String, dynamic> args) {
    final colorValue = args['color'];
    if (colorValue is String) {
      final parsed = ColorParser.parse(colorValue);
      if (parsed != null) {
        return parsed;
      }
    }

    for (final entry in args.entries) {
      final value = entry.value;
      if (value == true || value == null) {
        final parsed = ColorParser.parse(entry.key);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static InlineSpan _buildFg(FnNode node, MfmNodeBuilder builder) {
    final color = _parseColorArg(node.args);
    final children = builder.buildNodes(node.children);

    if (color == null) {
      return TextSpan(children: children);
    }

    return TextSpan(
      style: TextStyle(color: color),
      children: children,
    );
  }

  static InlineSpan _buildBg(FnNode node, MfmNodeBuilder builder) {
    final color = _parseColorArg(node.args);
    final children = builder.buildNodes(node.children);

    if (color == null) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      child: ColoredBox(
        color: color,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildBorder(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final children = builder.buildNodes(node.children);

    var width = 1.0;
    var style = BorderStyle.solid;
    var color = const Color(0xFF000000);
    var radius = 0.0;
    final noclip = args.containsKey('noclip');

    if (args.containsKey('width')) {
      final widthValue = args['width'];
      if (widthValue is num) {
        width = widthValue.toDouble();
      } else if (widthValue is String) {
        width = double.tryParse(widthValue) ?? 1.0;
      }
    }

    if (args.containsKey('style')) {
      final styleValue = args['style'];
      if (styleValue == 'dotted' || styleValue == 'dashed') {
        // Flutterはdotted/dashedをネイティブサポートしていないため、solidで代替
        style = BorderStyle.solid;
      }
    }

    if (args.containsKey('color')) {
      final colorValue = args['color'];
      if (colorValue is String) {
        color = ColorParser.parse(colorValue) ?? color;
      }
    }

    if (args.containsKey('radius')) {
      final radiusValue = args['radius'];
      if (radiusValue is num) {
        radius = radiusValue.toDouble();
      } else if (radiusValue is String) {
        radius = double.tryParse(radiusValue) ?? 0.0;
      }
    }

    return WidgetSpan(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: width,
            style: style,
          ),
          borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
        ),
        clipBehavior: noclip ? Clip.none : Clip.antiAlias,
        child: RichText(
          text: TextSpan(
            style: builder.config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  static InlineSpan _buildFont(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final children = builder.buildNodes(node.children);

    // フォントタイプを特定
    String? fontType;
    if (args.containsKey('serif')) {
      fontType = 'serif';
    } else if (args.containsKey('monospace')) {
      fontType = 'monospace';
    } else if (args.containsKey('cursive')) {
      fontType = 'cursive';
    } else if (args.containsKey('fantasy')) {
      fontType = 'fantasy';
    } else if (args.containsKey('emoji')) {
      fontType = 'emoji';
    } else if (args.containsKey('math')) {
      fontType = 'math';
    }

    if (fontType == null) {
      return TextSpan(children: children);
    }

    // カスタムリゾルバーがあればそれを使用
    final customFont = builder.config.fontFamilyResolver?.call(fontType);
    if (customFont != null) {
      return TextSpan(
        style: TextStyle(fontFamily: customFont),
        children: children,
      );
    }

    // デフォルトのプラットフォーム固有フォント
    final TextStyle style;
    switch (fontType) {
      case 'serif':
        style = const TextStyle(
          fontFamily: 'Georgia',
          fontFamilyFallback: ['Times New Roman', 'serif'],
        );
      case 'monospace':
        style = const TextStyle(
          fontFamily: 'Courier',
          fontFamilyFallback: ['Courier New', 'monospace'],
        );
      case 'cursive':
        style = const TextStyle(
          fontFamilyFallback: ['cursive'],
        );
      case 'fantasy':
        style = const TextStyle(
          fontFamilyFallback: ['fantasy'],
        );
      default:
        // emoji, mathはデフォルトフォント
        return TextSpan(children: children);
    }

    return TextSpan(style: style, children: children);
  }

  static InlineSpan _buildBlur(FnNode node, MfmNodeBuilder builder) {
    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _MfmBlurWidget(
        children: children,
        baseTextStyle: builder.config.baseTextStyle,
      ),
    );
  }

  static InlineSpan _buildRuby(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final children = builder.buildNodes(node.children);

    // 引数からルビテキストを取得（値なし引数を優先）
    String? rubyText;
    for (final entry in args.entries) {
      final value = entry.value;
      if (value == true || value == null) {
        rubyText = entry.key;
        break;
      }
    }

    if (rubyText == null) {
      return TextSpan(children: children);
    }

    final baseStyle = builder.config.baseTextStyle;
    final baseFontSize = baseStyle?.fontSize ?? 14.0;
    final rubyStyle = (baseStyle ?? const TextStyle()).copyWith(
      fontSize: baseFontSize * 0.5,
      height: 1,
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rubyText,
            style: rubyStyle,
          ),
          RichText(
            text: TextSpan(
              style: baseStyle,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  static InlineSpan _buildUnixtime(FnNode node, MfmNodeBuilder builder) {
    int? timestamp;
    for (final child in node.children) {
      if (child is TextNode) {
        timestamp = int.tryParse(child.text.trim());
        if (timestamp != null) {
          break;
        }
      }
    }

    if (timestamp == null) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedTime = _formatUnixTime(dateTime);

    final baseStyle = builder.config.baseTextStyle;
    final fontSize = (baseStyle?.fontSize ?? 14.0) * 0.9;
    final textStyle = (baseStyle ?? const TextStyle()).copyWith(
      fontSize: fontSize,
    );
    final borderColor = (baseStyle?.color ?? const Color(0xFF000000))
        .withValues(alpha: 0.2);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              const IconData(0xe8b5, fontFamily: 'MaterialIcons'),
              size: fontSize,
              color: textStyle.color,
            ),
            const SizedBox(width: 4),
            Text(formattedTime, style: textStyle),
          ],
        ),
      ),
    );
  }

  /// Unix時間を人間が読める形式にフォーマット
  ///
  /// timeagoパッケージを使用して相対時間表示を行う
  /// ロケールはアプリ側で設定されたデフォルトロケールを使用
  ///
  /// 使用例（アプリ側での初期化）:
  /// ```dart
  /// import 'package:timeago/timeago.dart' as timeago;
  ///
  /// void main() {
  ///   // 日本語ロケールを設定
  ///   timeago.setLocaleMessages('ja', timeago.JaMessages());
  ///   timeago.setDefaultLocale('ja');
  ///   runApp(MyApp());
  /// }
  /// ```
  static String _formatUnixTime(DateTime dateTime) {
    // timeagoを使用して相対時間表示
    return timeago.format(dateTime);
  }

  static InlineSpan _buildAnimatedPlaceholder(
    FnNode node,
    MfmNodeBuilder builder,
  ) {
    // アニメーションfn関数は将来実装
    // 現時点では子要素をそのまま表示
    return TextSpan(children: builder.buildNodes(node.children));
  }
}

class _MfmBlurWidget extends StatefulWidget {
  const _MfmBlurWidget({
    required this.children,
    this.baseTextStyle,
  });

  final List<InlineSpan> children;
  final TextStyle? baseTextStyle;

  @override
  State<_MfmBlurWidget> createState() => _MfmBlurWidgetState();
}

class _MfmBlurWidgetState extends State<_MfmBlurWidget> {
  var _isBlurred = true;

  void _toggleBlur() {
    setState(() {
      _isBlurred = !_isBlurred;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBlur,
      child: ImageFiltered(
        enabled: _isBlurred,
        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: RichText(
          text: TextSpan(
            style: widget.baseTextStyle,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
