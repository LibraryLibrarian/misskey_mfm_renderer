import 'package:flutter/widgets.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import 'builder/mfm_node_builder.dart';
import 'config/mfm_inherited_config.dart';
import 'config/mfm_render_config.dart';

/// MFMテキストをレンダリングするウィジェット
class MfmText extends StatelessWidget {
  const MfmText({
    super.key,
    this.text,
    this.parsedNodes,
    this.config = const MfmRenderConfig(),
    this.simple = false,
  }) : assert(
         text != null || parsedNodes != null,
         'Either text or parsedNodes must be provided',
       );

  /// MFMテキスト（パース前）
  /// textまたはparsedNodesのいずれかを指定する必要がある
  final String? text;

  /// パース済みノード（直接渡す場合）
  /// textまたはparsedNodesのいずれかを指定する必要がある
  final List<MfmNode>? parsedNodes;

  /// レンダリング設定
  final MfmRenderConfig config;

  /// シンプルパーサーを使用するか
  /// trueの場合、テキスト・Unicode絵文字・カスタム絵文字のみパース
  final bool simple;

  @override
  Widget build(BuildContext context) {
    // ノードを取得（パース済みがあればそれを使用、なければパース）
    final nodes = parsedNodes ?? _parseText();

    // InheritedWidgetから設定を取得（なければnull）
    final inheritedConfig = MfmConfig.maybeOf(context);
    final mergedConfig = _mergeConfigs(inheritedConfig, config);

    // brightnessを判定
    final brightness = MediaQuery.platformBrightnessOf(context);

    // baseTextStyleとbrightnessを設定
    final effectiveConfig =
        mergedConfig.baseTextStyle == null || mergedConfig.brightness == null
            ? mergedConfig.copyWith(
                baseTextStyle:
                    mergedConfig.baseTextStyle ??
                    DefaultTextStyle.of(context).style,
                brightness: mergedConfig.brightness ?? brightness,
              )
            : mergedConfig;

    // ビルダーを作成
    final builder = MfmNodeBuilder(config: effectiveConfig);

    // ノードをスパンに変換
    final spans = builder.buildNodes(nodes);

    // RichTextでレンダリング
    return RichText(
      text: TextSpan(
        style: effectiveConfig.baseTextStyle,
        children: spans,
      ),
    );
  }

  /// テキストをパースしてノードリストを取得
  List<MfmNode> _parseText() {
    final source = text;
    if (source == null || source.isEmpty) {
      return [];
    }

    final parser = simple ? MfmParser().buildSimple() : MfmParser().build();
    final result = parser.parse(source);
    try {
      return result.value;
    } on FormatException {
      // パース失敗時はプレーンテキストとして返す
      return [TextNode(source)];
    }
  }
}

MfmRenderConfig _mergeConfigs(
  MfmRenderConfig? inherited,
  MfmRenderConfig explicit,
) {
  if (inherited == null) {
    return explicit;
  }
  if (_isDefaultConfig(explicit)) {
    return inherited;
  }

  const defaults = MfmRenderConfig();
  return MfmRenderConfig(
    baseTextStyle: explicit.baseTextStyle ?? inherited.baseTextStyle,
    enableAdvancedMfm:
        explicit.enableAdvancedMfm != defaults.enableAdvancedMfm
            ? explicit.enableAdvancedMfm
            : inherited.enableAdvancedMfm,
    enableAnimation:
        explicit.enableAnimation != defaults.enableAnimation
            ? explicit.enableAnimation
            : inherited.enableAnimation,
    enableNyaize:
        explicit.enableNyaize != defaults.enableNyaize
            ? explicit.enableNyaize
            : inherited.enableNyaize,
    emojiBuilder: explicit.emojiBuilder ?? inherited.emojiBuilder,
    unicodeEmojiBuilder:
        explicit.unicodeEmojiBuilder ?? inherited.unicodeEmojiBuilder,
    onLinkTap: explicit.onLinkTap ?? inherited.onLinkTap,
    onMentionTap: explicit.onMentionTap ?? inherited.onMentionTap,
    onHashtagTap: explicit.onHashtagTap ?? inherited.onHashtagTap,
    onSearchTap: explicit.onSearchTap ?? inherited.onSearchTap,
    onClickableEvent: explicit.onClickableEvent ?? inherited.onClickableEvent,
    fontFamilyResolver:
        explicit.fontFamilyResolver ?? inherited.fontFamilyResolver,
    codeTheme: explicit.codeTheme ?? inherited.codeTheme,
    codeDarkTheme: explicit.codeDarkTheme ?? inherited.codeDarkTheme,
    brightness: explicit.brightness ?? inherited.brightness,
    showCodeBlockCopyButton:
        explicit.showCodeBlockCopyButton ??
        inherited.showCodeBlockCopyButton,
    inlineCodeBgColorLight:
        explicit.inlineCodeBgColorLight ?? inherited.inlineCodeBgColorLight,
    inlineCodeBgColorDark:
        explicit.inlineCodeBgColorDark ?? inherited.inlineCodeBgColorDark,
  );
}

bool _isDefaultConfig(MfmRenderConfig config) {
  const defaults = MfmRenderConfig();
  return config.baseTextStyle == defaults.baseTextStyle &&
      config.enableAdvancedMfm == defaults.enableAdvancedMfm &&
      config.enableAnimation == defaults.enableAnimation &&
      config.enableNyaize == defaults.enableNyaize &&
      config.emojiBuilder == defaults.emojiBuilder &&
      config.unicodeEmojiBuilder == defaults.unicodeEmojiBuilder &&
      config.onLinkTap == defaults.onLinkTap &&
      config.onMentionTap == defaults.onMentionTap &&
      config.onHashtagTap == defaults.onHashtagTap &&
      config.onSearchTap == defaults.onSearchTap &&
      config.onClickableEvent == defaults.onClickableEvent &&
      config.fontFamilyResolver == defaults.fontFamilyResolver &&
      config.codeTheme == defaults.codeTheme &&
      config.codeDarkTheme == defaults.codeDarkTheme &&
      config.brightness == defaults.brightness &&
      config.showCodeBlockCopyButton == defaults.showCodeBlockCopyButton &&
      config.inlineCodeBgColorLight == defaults.inlineCodeBgColorLight &&
      config.inlineCodeBgColorDark == defaults.inlineCodeBgColorDark;
}
