import 'package:flutter/widgets.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import 'builder/mfm_node_builder.dart';
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

    // brightnessを判定
    final brightness = MediaQuery.platformBrightnessOf(context);

    // baseTextStyleとbrightnessを設定
    final effectiveConfig =
        config.baseTextStyle == null || config.brightness == null
            ? config.copyWith(
                baseTextStyle:
                    config.baseTextStyle ?? DefaultTextStyle.of(context).style,
                brightness: brightness,
              )
            : config;

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
