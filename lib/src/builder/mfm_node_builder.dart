import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import '../config/mfm_render_config.dart';
import '../fn/mfm_fn_handler.dart';
import '../utils/nyaize.dart';
import '../widgets/mfm_code_block.dart';

/// MfmNodeをWidgetに変換するビルダー
class MfmNodeBuilder {
  MfmNodeBuilder({
    required this.config,
    required this.effectiveStyle,
    this.scale = 1.0,
    this.sizeDepth = 0,
    this.opacity = 1.0,
    this.disableNyaize = false,
    this.plain = false,
    this.isNote = true,
  });

  /// リンク・URL・メンション・ハッシュタグに共通のリンク色
  static const _linkColor = Color(0xFF0066CC);

  /// レンダリング設定
  final MfmRenderConfig config;

  /// 祖先ノードの差分スタイルを反映した現在の実効スタイル
  final TextStyle effectiveStyle;

  /// 現在のスケール（ネストしたscale fnで使用）
  final double scale;

  /// x2/x3/x4に共通のネスト深さ（他のノードでは増やさない）
  final int sizeDepth;

  /// smallの累積不透明度。実効スタイルの色が届かない描画にのみ適用する
  final double opacity;

  /// 現在のサブツリーで nyaize 変換を抑止するか
  /// link / quote / plain など、原文を保ちたいノード配下では true となる
  final bool disableNyaize;

  /// 本家MkMfmのplain表示を使うか。
  final bool plain;

  /// ハッシュタグをノート用の遷移先へ向けるか。
  final bool isNote;

  MfmNodeBuilder _copyWith({
    TextStyle? effectiveStyle,
    double? scale,
    int? sizeDepth,
    double? opacity,
    bool? disableNyaize,
    bool? plain,
    bool? isNote,
  }) {
    return MfmNodeBuilder(
      config: config,
      effectiveStyle: effectiveStyle ?? this.effectiveStyle,
      scale: scale ?? this.scale,
      sizeDepth: sizeDepth ?? this.sizeDepth,
      opacity: opacity ?? this.opacity,
      disableNyaize: disableNyaize ?? this.disableNyaize,
      plain: plain ?? this.plain,
      isNote: isNote ?? this.isNote,
    );
  }

  /// 新しいスケールでビルダーをコピー
  MfmNodeBuilder withScale(double newScale) {
    return _copyWith(scale: newScale);
  }

  /// サイズ関数のネスト深さを更新したビルダーを返す
  MfmNodeBuilder withSizeDepth(int newSizeDepth) {
    return _copyWith(sizeDepth: newSizeDepth);
  }

  /// 差分スタイル（inherit: true）を実効スタイルに反映したビルダーを返す
  MfmNodeBuilder withStyle(TextStyle patch) {
    return _copyWith(effectiveStyle: effectiveStyle.merge(patch));
  }

  /// nyaize 変換を抑止したサブツリー用ビルダーを返す
  MfmNodeBuilder _withDisableNyaize() {
    if (disableNyaize) return this;
    return _copyWith(disableNyaize: true);
  }

  /// 差分スタイルをTextSpanに設定し、同じ差分を実効スタイルに反映した
  /// ビルダーで子ノードを構築する
  TextSpan buildStyledSpan(
    TextStyle patch,
    List<MfmNode> nodes, {
    GestureRecognizer? recognizer,
  }) {
    return TextSpan(
      style: patch,
      children: withStyle(patch).buildNodes(nodes),
      recognizer: recognizer,
    );
  }

  /// 実効スタイルの色が届かないウィジェットだけを減光する
  Widget wrapOpacity(Widget child) {
    return opacity < 1.0 ? Opacity(opacity: opacity, child: child) : child;
  }

  /// 継承色を使わず固定色を指定する描画に、累積不透明度を反映する
  /// 本家CSSのopacityはスタッキングコンテキストを作るため、
  /// 子孫の色指定でも減光を上書きできない
  Color applyOpacity(Color color) {
    if (opacity >= 1.0) return color;
    return color.withValues(alpha: color.a * opacity);
  }

  /// WidgetSpan内で子ノードを描画するRichTextを、現在の実効スタイルで組む
  /// 色のalphaにsmallを反映済みなので、全体をwrapOpacityで二重に減光しない
  Widget buildInlineRichText(
    List<InlineSpan> children, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(style: effectiveStyle, children: children),
    );
  }

  /// 現在の文脈で nyaize 変換を適用すべきか
  bool get shouldNyaize {
    final mode =
        config.nyaizeMode ??
        (config.enableNyaize ? MfmNyaizeMode.enabled : MfmNyaizeMode.disabled);
    return !disableNyaize &&
        switch (mode) {
          MfmNyaizeMode.disabled => false,
          MfmNyaizeMode.enabled => true,
          MfmNyaizeMode.respectAuthor => config.author?.isCat == true,
        };
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
    final normalized = plain
        ? node.text.replaceAll(RegExp(r'\r\n|\r|\n'), '\n')
        : node.text;
    final nyaized = shouldNyaize ? nyaize(normalized) : normalized;
    return TextSpan(text: plain ? nyaized.replaceAll('\n', ' ') : nyaized);
  }

  InlineSpan _buildBold(BoldNode node) {
    return buildStyledSpan(
      const TextStyle(fontWeight: FontWeight.bold),
      node.children,
    );
  }

  InlineSpan _buildItalic(ItalicNode node) {
    return buildStyledSpan(
      const TextStyle(fontStyle: FontStyle.italic),
      node.children,
    );
  }

  InlineSpan _buildStrike(StrikeNode node) {
    return buildStyledSpan(
      const TextStyle(decoration: TextDecoration.lineThrough),
      node.children,
    );
  }

  InlineSpan _buildSmall(SmallNode node) {
    final color = effectiveStyle.color;

    return _copyWith(opacity: opacity * 0.7).buildStyledSpan(
      TextStyle(
        fontSize: effectiveStyle.fontSize! * 0.8,
        color: color?.withValues(alpha: color.a * 0.7),
      ),
      node.children,
    );
  }

  InlineSpan _buildQuote(QuoteNode node) {
    final baseColor = config.baseTextStyle?.color;
    // 本家のQUOTE_STYLEもopacity: 0.7を要素全体に掛けるため、
    // 累積不透明度を0.7倍して配下のウィジェットまで減光する。
    final quoted = _withDisableNyaize()._copyWith(opacity: opacity * 0.7);
    // 引用は独自の色で上書きするため、累積不透明度を色のalphaに反映し直す。
    // Container全体を減光すると内側の文字や絵文字が二重に薄くなる。
    final quoteBuilder = quoted.withStyle(
      TextStyle(
        color: baseColor?.withValues(alpha: baseColor.a * quoted.opacity),
      ),
    );
    final children = quoteBuilder.buildNodes(node.children);

    return WidgetSpan(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: quoteBuilder.applyOpacity(const Color(0xFF888888)),
              width: 3,
            ),
          ),
        ),
        child: quoteBuilder.buildInlineRichText(children),
      ),
    );
  }

  InlineSpan _buildCenter(CenterNode node) {
    final children = buildNodes(node.children);
    return WidgetSpan(
      child: SizedBox(
        width: double.infinity,
        child: buildInlineRichText(children, textAlign: TextAlign.center),
      ),
    );
  }

  InlineSpan _buildBlockCode(CodeBlockNode node) {
    return WidgetSpan(
      child: wrapOpacity(
        MfmCodeBlock(
          code: node.code,
          language: node.language,
          theme: _getCodeTheme(),
          showCopyButton: config.showCodeBlockCopyButton ?? true,
          onCodeCopied: config.onCodeCopied,
          copyTooltip: config.codeCopyTooltip,
          copiedMessage: config.codeCopiedMessage,
          fontSize: config.baseTextStyle?.fontSize,
        ),
      ),
    );
  }

  InlineSpan _buildInlineCode(InlineCodeNode node) {
    final fontSize = effectiveStyle.fontSize!;

    // 背景色を取得（Misskey本家に準拠した色をデフォルトとして使用）
    final backgroundColor = config.brightness == Brightness.dark
        ? (config.inlineCodeBgColorDark ?? const Color(0xFF121212))
        : (config.inlineCodeBgColorLight ?? const Color(0xFFF5F5F5));

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        padding: EdgeInsets.all(fontSize * 0.1),
        decoration: BoxDecoration(
          // 文字は実効色で減光済みなので、背景だけにsmallの累積不透明度を反映する。
          color: backgroundColor.withValues(alpha: backgroundColor.a * opacity),
          borderRadius: BorderRadius.circular(fontSize * 0.3),
        ),
        child: Text(
          node.code,
          style: effectiveStyle.copyWith(
            fontFamily: 'Consolas',
            fontFamilyFallback: const [
              'Monaco',
              'Andale Mono',
              'Ubuntu Mono',
              'monospace',
            ],
          ),
        ),
      ),
    );
  }

  InlineSpan _buildMathBlock(MathBlockNode node) {
    // 本家と同じ素のcode表示。ブロック化せず、前後のTextNodeの改行に任せる。
    return TextSpan(
      text: node.formula,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: [
          'Consolas',
          'Monaco',
          'Andale Mono',
          'Ubuntu Mono',
          'monospace',
        ],
      ),
    );
  }

  InlineSpan _buildMathInline(MathInlineNode node) {
    return TextSpan(
      text: node.formula,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: [
          'Consolas',
          'Monaco',
          'Andale Mono',
          'Ubuntu Mono',
          'monospace',
        ],
      ),
    );
  }

  InlineSpan _buildUrl(UrlNode node) {
    final onLinkTap = config.onLinkTap;
    return TextSpan(
      text: node.url,
      style: TextStyle(
        color: applyOpacity(_linkColor),
        decoration: TextDecoration.underline,
      ),
      recognizer: onLinkTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onLinkTap(node.url)),
    );
  }

  InlineSpan _buildLink(LinkNode node) {
    final onLinkTap = config.onLinkTap;
    return _withDisableNyaize().buildStyledSpan(
      TextStyle(
        color: applyOpacity(_linkColor),
        decoration: TextDecoration.underline,
      ),
      node.children,
      recognizer: onLinkTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onLinkTap(node.url)),
    );
  }

  InlineSpan _buildMention(MentionNode node) {
    final onMentionTap = config.onMentionTap;
    final resolvedAcct = _resolveMentionAcct(node);
    return TextSpan(
      text: node.acct,
      style: TextStyle(
        color: applyOpacity(_linkColor),
      ),
      recognizer: onMentionTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onMentionTap(resolvedAcct)),
    );
  }

  String _resolveMentionAcct(MentionNode node) {
    if (_nonEmptyHost(node.host) != null) {
      return node.acct;
    }

    final host =
        _nonEmptyHost(config.author?.host) ?? _nonEmptyHost(config.localHost);
    if (host == null) {
      return node.acct;
    }
    return '@${node.username}@$host';
  }

  String? _nonEmptyHost(String? host) {
    if (host == null || host.isEmpty) {
      return null;
    }
    return host;
  }

  InlineSpan _buildHashtag(HashtagNode node) {
    final onHashtagTap = config.onHashtagTap;
    final onHashtagTapDetails = config.onHashtagTapDetails;
    return TextSpan(
      text: '#${node.hashtag}',
      style: TextStyle(
        color: applyOpacity(_linkColor),
      ),
      recognizer: onHashtagTapDetails == null && onHashtagTap == null
          ? null
          : (TapGestureRecognizer()
              ..onTap = () {
                if (onHashtagTapDetails != null) {
                  final pathPrefix = isNote ? '/tags/' : '/user-tags/';
                  onHashtagTapDetails(
                    MfmHashtagTapDetails(
                      tag: node.hashtag,
                      isNote: isNote,
                      path: '$pathPrefix${Uri.encodeComponent(node.hashtag)}',
                    ),
                  );
                } else {
                  onHashtagTap!(node.hashtag);
                }
              }),
    );
  }

  InlineSpan _buildSearch(SearchNode node) {
    final baseStyle = config.baseTextStyle ?? const TextStyle(fontSize: 14);

    return WidgetSpan(
      child: wrapOpacity(
        Container(
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
                  child: Text(node.query, style: baseStyle),
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
                  child: Text(
                    config.searchButtonLabel ?? 'Search',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InlineSpan _buildEmojiCode(EmojiCodeNode node) {
    final emojiBuilder = config.emojiBuilder;
    final authorHost = config.author?.host;
    final host = authorHost == null || authorHost.isEmpty ? null : authorHost;
    final emojiUrls = config.emojiUrls;
    if (emojiBuilder == null ||
        (host != null &&
            emojiUrls != null &&
            !emojiUrls.containsKey(node.name))) {
      return TextSpan(text: ':${node.name}:');
    }

    // ローカル投稿はURL辞書を見ない。空URLは本家のtruthy判定と同じく未指定。
    final rawUrl = host == null ? null : emojiUrls?[node.name];
    final url = rawUrl == null || rawUrl.isEmpty ? null : Uri.tryParse(rawUrl);
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: wrapOpacity(
        emojiBuilder(
          node.name,
          MfmEmojiContext(
            fontSize: effectiveStyle.fontSize!,
            scale: scale,
            normal: plain,
            host: host,
            url: url,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildUnicodeEmoji(UnicodeEmojiNode node) {
    final unicodeEmojiBuilder = config.unicodeEmojiBuilder;
    if (unicodeEmojiBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: wrapOpacity(
          unicodeEmojiBuilder(
            node.emoji,
            MfmEmojiContext(
              fontSize: effectiveStyle.fontSize!,
              scale: scale,
            ),
          ),
        ),
      );
    }
    return TextSpan(text: node.emoji);
  }

  InlineSpan _buildPlain(PlainNode node) {
    final children = _withDisableNyaize().buildNodes(node.children);
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
