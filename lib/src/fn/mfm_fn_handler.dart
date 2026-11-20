import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import '../builder/mfm_node_builder.dart';
import '../config/mfm_unixtime_options.dart';
import '../utils/color_parser.dart';
import '../utils/js_parse_float.dart';
import '../utils/unixtime.dart';
import '../widgets/mfm_border.dart';
import '../widgets/mfm_unixtime_label.dart';
import 'animated/mfm_animated_wrapper.dart';
import 'animated/mfm_bounce_widget.dart';
import 'animated/mfm_jelly_widget.dart';
import 'animated/mfm_jump_widget.dart';
import 'animated/mfm_rainbow_text.dart';
import 'animated/mfm_rainbow_widget.dart';
import 'animated/mfm_shake_widget.dart';
import 'animated/mfm_sparkle_widget.dart';
import 'animated/mfm_spin_widget.dart';
import 'animated/mfm_tada_widget.dart';
import 'animated/mfm_twitch_widget.dart';
import 'mfm_border_options.dart';
import 'ruby/mfm_ruby.dart';

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
        return buildMfmRuby(node, builder);
      case 'unixtime':
        return _buildUnixtime(node, builder);
      case 'clickable':
        return _buildClickable(node, builder);

      // アニメーション系
      case 'tada':
        return _buildTada(node, builder);
      case 'jelly':
        return _buildJelly(node, builder);
      case 'twitch':
        return _buildTwitch(node, builder);
      case 'shake':
        return _buildShake(node, builder);
      case 'spin':
        return _buildSpin(node, builder);
      case 'jump':
        return _buildJump(node, builder);
      case 'bounce':
        return _buildBounce(node, builder);
      case 'rainbow':
        return _buildRainbow(node, builder);
      case 'sparkle':
        return _buildSparkle(node, builder);

      default:
        return _buildLiteral(node, builder);
    }
  }

  /// 効果が決まらなかったfnを本家と同じく `$[name 中身]` のリテラルで表示する
  static InlineSpan _buildLiteral(FnNode node, MfmNodeBuilder builder) {
    return TextSpan(
      children: [
        TextSpan(text: '\$[${node.name} '),
        ...builder.buildNodes(node.children),
        const TextSpan(text: ']'),
      ],
    );
  }

  // 各fn関数の実装（初期はプレースホルダー、後続タスクで実装）

  static InlineSpan _buildSize(FnNode node, MfmNodeBuilder builder) {
    // sizeMultiplierはCSSの--mfm-zoom-size（200/400/600%）、
    // nominalScaleは本家がgenElへ渡すscale（x2:2, x3:3, x4:4）に対応する。
    final double sizeMultiplier;
    final double nominalScale;
    switch (node.name) {
      case 'x2':
        sizeMultiplier = 2.0;
        nominalScale = 2.0;
      case 'x3':
        sizeMultiplier = 4.0;
        nominalScale = 3.0;
      case 'x4':
        sizeMultiplier = 6.0;
        nominalScale = 4.0;
      default:
        sizeMultiplier = 1.0;
        nominalScale = 1.0;
    }

    final depth = builder.sizeDepth;
    // 本家CSSと同じ親相対倍率。3階層目以降は拡大を無効化する。
    final factor = depth == 0
        ? sizeMultiplier
        : depth == 1
        ? sizeMultiplier / 2 + 0.5
        : 1.0;
    // 本家はadvanced MFMの有効状態やネスト深さに関係なく公称倍率でscaleを更新する
    final sizedBuilder = builder
        .withSizeDepth(depth + 1)
        .withScale(builder.scale * nominalScale);
    if (!builder.config.enableAdvancedMfm || factor == 1.0) {
      return TextSpan(children: sizedBuilder.buildNodes(node.children));
    }

    final fontSize = builder.effectiveStyle.fontSize! * factor;
    return sizedBuilder.buildStyledSpan(
      TextStyle(fontSize: fontSize),
      node.children,
    );
  }

  static InlineSpan _buildFlip(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final flipH = args.containsKey('h');
    final flipV = args.containsKey('v');

    final double scaleX;
    final double scaleY;
    if (flipH && flipV) {
      scaleX = -1.0;
      scaleY = -1.0;
    } else if (flipV) {
      scaleX = 1.0;
      scaleY = -1.0;
    } else {
      scaleX = -1.0;
      scaleY = 1.0;
    }

    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildRotate(FnNode node, MfmNodeBuilder builder) {
    // 本家と同じくparseFloatで先頭の数値を読む（`45deg`は45度）。
    final degrees = jsParseFloat(node.args['deg']) ?? 90.0;
    final child = builder.buildInlineRichText(
      builder.buildNodes(node.children),
    );

    // Infinityは本家のCSSでは無効な値になり、回転しない。
    if (!degrees.isFinite) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: child,
      );
    }

    var radians = degrees * math.pi / 180.0;
    if (!radians.isFinite) {
      // 有限でもラジアンへの変換で溢れる巨大な角度は、同じ向きの角度に直す。
      radians = degrees % 360 * math.pi / 180.0;
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.rotate(angle: radians, child: child),
    );
  }

  static InlineSpan _buildSpin(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
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

    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 1500),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    if (duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmSpinWidget(
        axis: axis,
        direction: direction,
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildJump(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 750),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    if (duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmJumpWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildBounce(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 750),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    if (duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmBounceWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildRainbow(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
      final scope = MfmRainbowScope();
      final rainbow = builder.withRainbow(scope);
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: MfmStaticRainbowWidget(
          scope: scope,
          child: rainbow.buildInlineRichText(rainbow.buildNodes(node.children)),
        ),
      );
    }

    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 1000),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;
    final children = builder.buildNodes(node.children);

    // 本家 Misskey ではアニメーション有効時の duration=0 は
    // rainbow の静的フォールバックを適用せず、通常の文字表示になる。
    if (builder.config.useAnimation && duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmRainbowWidget(
        duration: duration,
        delay: delay,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildSparkle(FnNode node, MfmNodeBuilder builder) {
    final children = builder.buildNodes(node.children);
    if (!builder.config.useAnimation) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmSparkleWidget(
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildShake(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 500),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    if (duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmShakeWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildTwitch(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 500),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    if (duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmTwitchWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildTada(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 1000),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    // 150%は描画時のTransformではなく実フォントサイズとしてレイアウトに反映する。
    final sizeStyle = TextStyle(
      fontSize: builder.effectiveStyle.fontSize! * 1.5,
    );
    if (!builder.config.useAnimation) {
      return builder.buildStyledSpan(sizeStyle, node.children);
    }
    final sized = builder.withStyle(sizeStyle);
    final children = sized.buildNodes(node.children);

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmTadaWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation && duration > Duration.zero,
        child: sized.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildJelly(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.useAnimation) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    final args = node.args;
    final duration = MfmAnimatedWrapper.parseSpeed(
      args['speed'],
      fallback: const Duration(milliseconds: 1000),
    );
    final delay = MfmAnimatedWrapper.parseTime(args['delay']) ?? Duration.zero;

    final children = builder.buildNodes(node.children);

    if (duration <= Duration.zero) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmJellyWidget(
        duration: duration,
        delay: delay,
        enabled: builder.config.useAnimation,
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildScale(FnNode node, MfmNodeBuilder builder) {
    if (!builder.config.enableAdvancedMfm) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    // 本家と同じくparseFloatで先頭の数値を読み、上限5倍だけをかける。
    // 下限はないため、負の値は反転したうえで指定どおりに拡大する。
    final scaleX = math.min<double>(jsParseFloat(node.args['x']) ?? 1.0, 5);
    final scaleY = math.min<double>(jsParseFloat(node.args['y']) ?? 1.0, 5);

    // 子へ伝える倍率は本家と同じく符号付きの大きい方を掛ける。
    // 本家は変形がCSSとして無効になる場合も倍率を更新する。
    var newScale = builder.scale * math.max(scaleX, scaleY);
    if (newScale.isNaN) {
      // 0 * -Infinityなど。本家ではNaNになるが、useOriginalSize（>= 2.5）や
      // その後の乗算の結果は0と変わらないため、等値比較できる0に寄せる。
      newScale = 0;
    }
    final scaledBuilder = builder.withScale(newScale);
    final child = scaledBuilder.buildInlineRichText(
      scaledBuilder.buildNodes(node.children),
    );

    // -Infinityは本家のCSSでは無効な値になり、変形しない。
    if (!scaleX.isFinite || !scaleY.isFinite) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: child,
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.scale(
        // 極端な負の値では変形行列の逆行列が非有限になり、hit testなどが
        // 壊れるため、描画にだけライブラリ独自の下限をかける。
        scaleX: math.max(scaleX, _minPaintScale),
        scaleY: math.max(scaleY, _minPaintScale),
        child: child,
      ),
    );
  }

  /// scale fnの描画に使う倍率の下限。本家にはないライブラリ独自の安全制限。
  static const _minPaintScale = -1024.0;

  static InlineSpan _buildPosition(FnNode node, MfmNodeBuilder builder) {
    // advancedMfmが無効な場合はリテラルで表示
    if (!builder.config.enableAdvancedMfm) {
      return _buildLiteral(node, builder);
    }

    // x, y引数を取得（em単位）。本家と同じくparseFloatで先頭の数値を読む。
    final x = jsParseFloat(node.args['x']) ?? 0.0;
    final y = jsParseFloat(node.args['y']) ?? 0.0;

    // emをピクセルに変換（祖先のサイズ変更を含む実効サイズを使用）
    final baseSize = builder.effectiveStyle.fontSize!;
    final offset = Offset(x * baseSize, y * baseSize);
    final child = builder.buildInlineRichText(
      builder.buildNodes(node.children),
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      // Infinityは本家のCSSでは無効な値になり、x, yとも移動しない。
      // px換算で溢れた場合も、座標がNaNにならないよう移動しない。
      child: offset.isFinite
          ? Transform.translate(offset: offset, child: child)
          : child,
    );
  }

  /// 本家のvalidColor相当。nullは「色指定なし」を表す。
  static Color? _resolveFgBgColor(Map<String, dynamic> args) {
    const fallback = Color(0xFFFF0000);
    final value = args['color'];
    // 本家と同じく、#や名前色を含まない3〜6桁の16進文字列だけを受理する。
    if (value is! String ||
        !RegExp(r'^[0-9a-f]{3,6}$', caseSensitive: false).hasMatch(value)) {
      return fallback;
    }

    if (value.length == 4) {
      // CSSの#RGBAをFlutterのARGBに変換し、各桁を2桁に展開する。
      final rgba = int.parse(value, radix: 16);
      return Color.fromARGB(
        (rgba & 0xF) * 0x11,
        ((rgba >> 12) & 0xF) * 0x11,
        ((rgba >> 8) & 0xF) * 0x11,
        ((rgba >> 4) & 0xF) * 0x11,
      );
    }

    // 5桁は本家の正規表現には一致するがCSSでは無効な色として
    // 宣言ごと破棄されるため、本家と同じく色を付けない。
    if (value.length == 5) {
      return null;
    }

    return ColorParser.parse(value) ?? fallback;
  }

  static InlineSpan _buildFg(FnNode node, MfmNodeBuilder builder) {
    final color = _resolveFgBgColor(node.args);

    if (color == null) {
      return TextSpan(children: builder.buildNodes(node.children));
    }

    // 本家のopacityは子孫の色指定では上書きできないため、
    // 前景色にもsmallなどの累積不透明度を反映する。
    return builder.buildStyledSpan(
      TextStyle(color: builder.applyOpacity(color)),
      node.children,
      unattenuatedPatch: TextStyle(color: color),
    );
  }

  static InlineSpan _buildBg(FnNode node, MfmNodeBuilder builder) {
    final color = _resolveFgBgColor(node.args);
    final children = builder.buildNodes(node.children);

    if (color == null) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: ColoredBox(
        // 内側の文字は減光済みなので、背景色だけにsmallを反映する。
        color: builder.applyOpacity(color),
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildBorder(FnNode node, MfmNodeBuilder builder) {
    final options = MfmBorderOptions.resolve(
      node.args,
      builder.colorScheme.accent,
    );
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MfmBorder(
        options: options,
        color: builder.applyOpacity(options.color),
        child: builder.buildInlineRichText(builder.buildNodes(node.children)),
      ),
    );
  }

  static InlineSpan _buildFont(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;

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
      return _buildLiteral(node, builder);
    }

    // カスタムリゾルバーがあればそれを使用
    final customFont = builder.config.fontFamilyResolver?.call(fontType);
    if (customFont != null) {
      return builder.buildStyledSpan(
        TextStyle(fontFamily: customFont),
        node.children,
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
        // emoji, mathは各バックエンドで本家のCSS総称ファミリーと同じ割り当てを
        // 保証できないため、fontFamilyResolverで指定されない限り継承したままにする。
        return TextSpan(children: builder.buildNodes(node.children));
    }

    return builder.buildStyledSpan(style, node.children);
  }

  static InlineSpan _buildBlur(FnNode node, MfmNodeBuilder builder) {
    final children = builder.buildNodes(node.children);

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _MfmBlurWidget(
        child: builder.buildInlineRichText(children),
      ),
    );
  }

  static InlineSpan _buildUnixtime(FnNode node, MfmNodeBuilder builder) {
    final timestamp = parseUnixtime(node.children);

    final fontSize = builder.effectiveStyle.fontSize! * 0.9;
    final timeBuilder = builder.withStyle(TextStyle(fontSize: fontSize));
    final textStyle = timeBuilder.effectiveStyle;
    const clock = IconData(0xe8b5, fontFamily: 'MaterialIcons');
    final Widget icon;
    if (builder.rainbowScope != null && builder.rainbowForeground) {
      // Iconの独立したRichTextにも、本文と同じ静的rainbowを適用する。
      final iconBuilder = timeBuilder.withStyle(
        const TextStyle(
          fontFamily: 'MaterialIcons',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
          decoration: TextDecoration.none,
          height: 1,
        ),
      );
      icon = ExcludeSemantics(
        child: SizedBox.square(
          dimension: fontSize,
          child: Center(
            child: iconBuilder.buildInlineRichText([
              TextSpan(text: String.fromCharCode(clock.codePoint)),
            ]),
          ),
        ),
      );
    } else {
      icon = ExcludeSemantics(
        child: Icon(
          clock,
          size: fontSize,
          color: textStyle.foreground?.color ?? textStyle.color,
        ),
      );
    }

    // 周囲のDefaultTextStyleではなくMFMの実効スタイルを使い、
    // Textのアクセシビリティ倍率・localeの解決は維持する。
    final timeText = MfmUnixtimeLabel(
      timestamp: timestamp,
      options: builder.config.unixtimeOptions ?? const MfmUnixtimeOptions(),
      style: textStyle,
      nowrap: builder.nowrap,
      rainbowScope: builder.rainbowScope,
      rainbowForeground: builder.rainbowForeground,
    );

    // 文字・アイコンは実効スタイルで減光済みなので、枠線だけ別途減光する。
    // 本家はdisplay: inline-blockでvertical-align未指定のため、
    // ピル内テキストのベースラインで周囲と揃う。
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: builder.applyOpacity(builder.colorScheme.divider),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            icon,
            const SizedBox(width: 4),
            Flexible(child: timeText),
          ],
        ),
      ),
    );
  }

  static InlineSpan _buildClickable(FnNode node, MfmNodeBuilder builder) {
    final args = node.args;
    final children = builder.buildNodes(node.children);

    // ev引数を取得（デフォルトは空文字）
    var eventId = '';
    if (args.containsKey('ev')) {
      final evValue = args['ev'];
      if (evValue is String) {
        eventId = evValue;
      }
    }

    final onClickableEvent = builder.config.onClickableEvent;
    if (onClickableEvent == null) {
      return TextSpan(children: children);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () {
          onClickableEvent(eventId);
        },
        behavior: HitTestBehavior.opaque,
        child: builder.buildInlineRichText(children),
      ),
    );
  }
}

class _MfmBlurWidget extends StatefulWidget {
  const _MfmBlurWidget({required this.child});

  final Widget child;

  @override
  State<_MfmBlurWidget> createState() => _MfmBlurWidgetState();
}

class _MfmBlurWidgetState extends State<_MfmBlurWidget> {
  static const _blurSigma = 6.0;
  static const _transitionDuration = Duration(milliseconds: 300);

  var _isBlurred = true;
  var _isHovered = false;
  PointerDeviceKind? _tapDeviceKind;

  void _toggleBlur() {
    setState(() {
      _isBlurred = !_isBlurred;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _tapDeviceKind = details.kind;
  }

  void _handleTap() {
    final deviceKind = _tapDeviceKind;
    _tapDeviceKind = null;
    if (deviceKind == PointerDeviceKind.mouse) {
      return;
    }
    _toggleBlur();
  }

  void _setHovered({required bool isHovered}) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetSigma = _isBlurred && !_isHovered ? _blurSigma : 0.0;

    return MouseRegion(
      onEnter: (_) => _setHovered(isHovered: true),
      onExit: (_) => _setHovered(isHovered: false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapCancel: () => _tapDeviceKind = null,
        onTap: _handleTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: targetSigma),
          duration: _transitionDuration,
          curve: Curves.ease,
          builder: (context, sigma, child) => ImageFiltered(
            enabled: sigma > 0,
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
