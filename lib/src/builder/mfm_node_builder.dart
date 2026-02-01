import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import '../config/mfm_render_config.dart';
import '../fn/mfm_fn_handler.dart';
import '../widgets/mfm_code_block.dart';

/// MfmNodeをWidgetに変換するビルダー
class MfmNodeBuilder {
  MfmNodeBuilder({required this.config, this.scale = 1.0});

  /// レンダリング設定
  final MfmRenderConfig config;

  /// 現在のスケール（ネストしたscale fnで使用）
  final double scale;

  /// 新しいスケールでビルダーをコピー
  MfmNodeBuilder withScale(double newScale) {
    return MfmNodeBuilder(config: config, scale: newScale);
  }

  /// ノードリストをWidgetリストに変換
  List<InlineSpan> buildNodes(List<MfmNode> nodes) {
    return nodes.map(buildNode).toList();
  }

  /// 単一ノードをInlineSpanに変換
  InlineSpan buildNode(MfmNode node) {
    return node.map(
      text: _buildText,
      bold: _buildBold,
      italic: _buildItalic,
      strike: _buildStrike,
      small: _buildSmall,
      quote: _buildQuote,
      center: _buildCenter,
      inlineCode: _buildInlineCode,
      codeBlock: _buildBlockCode,
      mathInline: _buildMathInline,
      mathBlock: _buildMathBlock,
      link: _buildLink,
      url: _buildUrl,
      mention: _buildMention,
      hashtag: _buildHashtag,
      emojiCode: _buildEmojiCode,
      unicodeEmoji: _buildUnicodeEmoji,
      search: _buildSearch,
      plain: _buildPlain,
      fn: _buildFn,
    );
  }

  InlineSpan _buildText(TextNode node) {
    // styleをnullにして親のスタイルを継承
    // ルートのTextSpanでbaseTextStyleが設定されているため、ここで再設定する必要はない
    return TextSpan(text: node.text);
  }

  InlineSpan _buildBold(BoldNode node) {
    final children = buildNodes(node.children);
    return TextSpan(
      style: const TextStyle(fontWeight: FontWeight.bold),
      children: children,
    );
  }

  InlineSpan _buildItalic(ItalicNode node) {
    final children = buildNodes(node.children);
    return TextSpan(
      style: const TextStyle(fontStyle: FontStyle.italic),
      children: children,
    );
  }

  InlineSpan _buildStrike(StrikeNode node) {
    final children = buildNodes(node.children);
    return TextSpan(
      style: const TextStyle(decoration: TextDecoration.lineThrough),
      children: children,
    );
  }

  InlineSpan _buildSmall(SmallNode node) {
    final children = buildNodes(node.children);
    final baseFontSize = config.baseTextStyle?.fontSize ?? 14;
    final baseColor = config.baseTextStyle?.color;

    return TextSpan(
      style: TextStyle(
        fontSize: baseFontSize * 0.8,
        color: baseColor?.withValues(alpha: 0.7),
      ),
      children: children,
    );
  }

  InlineSpan _buildQuote(QuoteNode node) {
    final children = buildNodes(node.children);
    final baseColor = config.baseTextStyle?.color;

    return WidgetSpan(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Color(0xFF888888),
              width: 3,
            ),
          ),
        ),
        child: RichText(
          text: TextSpan(
            // baseTextStyleをベースにしてcolorのみ上書き
            style: config.baseTextStyle?.copyWith(
              color: baseColor?.withValues(alpha: 0.7),
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildCenter(CenterNode node) {
    final children = buildNodes(node.children);
    return WidgetSpan(
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: config.baseTextStyle,
            children: children,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildBlockCode(CodeBlockNode node) {
    return WidgetSpan(
      child: MfmCodeBlock(
        code: node.code,
        language: node.language,
        theme: _getCodeTheme(),
        showCopyButton: config.showCodeBlockCopyButton ?? true,
      ),
    );
  }

  InlineSpan _buildInlineCode(InlineCodeNode node) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          node.code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildMathBlock(MathBlockNode node) {
    return WidgetSpan(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          node.formula,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  InlineSpan _buildMathInline(MathInlineNode node) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          node.formula,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildUrl(UrlNode node) {
    final onLinkTap = config.onLinkTap;
    return TextSpan(
      text: node.url,
      style: const TextStyle(
        color: Color(0xFF0066CC),
        decoration: TextDecoration.underline,
      ),
      recognizer: onLinkTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onLinkTap(node.url)),
    );
  }

  InlineSpan _buildLink(LinkNode node) {
    final children = buildNodes(node.children);
    final onLinkTap = config.onLinkTap;
    return TextSpan(
      style: const TextStyle(
        color: Color(0xFF0066CC),
        decoration: TextDecoration.underline,
      ),
      children: children,
      recognizer: onLinkTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onLinkTap(node.url)),
    );
  }

  InlineSpan _buildMention(MentionNode node) {
    final onMentionTap = config.onMentionTap;
    return TextSpan(
      text: node.acct,
      style: const TextStyle(
        color: Color(0xFF0066CC),
      ),
      recognizer: onMentionTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onMentionTap(node.acct)),
    );
  }

  InlineSpan _buildHashtag(HashtagNode node) {
    return TextSpan(
      text: '#${node.hashtag}',
      style: const TextStyle(
        color: Color(0xFF0066CC),
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          config.onHashtagTap?.call(node.hashtag);
        },
    );
  }

  InlineSpan _buildSearch(SearchNode node) {
    final baseStyle = config.baseTextStyle ?? const TextStyle(fontSize: 14);

    return WidgetSpan(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.query,
                  style: baseStyle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                config.onSearchTap?.call(node.query);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '検索',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InlineSpan _buildEmojiCode(EmojiCodeNode node) {
    final emojiBuilder = config.emojiBuilder;
    if (emojiBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: emojiBuilder(node.name),
      );
    }

    return TextSpan(text: ':${node.name}:');
  }

  InlineSpan _buildUnicodeEmoji(UnicodeEmojiNode node) {
    final unicodeEmojiBuilder = config.unicodeEmojiBuilder;
    if (unicodeEmojiBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: unicodeEmojiBuilder(node.emoji),
      );
    }
    return TextSpan(text: node.emoji);
  }

  InlineSpan _buildPlain(PlainNode node) {
    final children = buildNodes(node.children);
    return TextSpan(children: children);
  }

  InlineSpan _buildFn(FnNode node) {
    return MfmFnHandler.build(node, this);
  }

  /// 現在のテーマモードに応じて適切なコードハイライトテーマを返す
  Map<String, TextStyle> _getCodeTheme() {
    final brightness = config.brightness;

    if (brightness == Brightness.dark) {
      // ダークモード
      return config.codeDarkTheme ?? config.codeTheme ?? atomOneDarkTheme;
    } else {
      // ライトモード
      return config.codeTheme ?? githubTheme;
    }
  }
}
