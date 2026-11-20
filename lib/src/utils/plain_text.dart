import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

import 'nyaize.dart';

final _carriageReturns = RegExp(r'\r\n?');

/// Flattens a depth-limited subtree without recursing or adding MFM syntax.
String mfmPlainText(
  List<MfmNode> nodes, {
  required bool plain,
  required bool shouldNyaize,
}) {
  final buffer = StringBuffer();
  final stack = nodes.reversed.toList();
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    final children = switch (node) {
      BoldNode(:final children) ||
      ItalicNode(:final children) ||
      StrikeNode(:final children) ||
      SmallNode(:final children) ||
      QuoteNode(:final children) ||
      CenterNode(:final children) ||
      LinkNode(:final children) ||
      PlainNode(:final children) ||
      FnNode(:final children) => children,
      _ => null,
    };
    if (children != null) {
      stack.addAll(children.reversed);
      continue;
    }
    buffer.write(switch (node) {
      TextNode(:final text) => _text(text, plain, shouldNyaize),
      EmojiCodeNode(:final name) => ':$name:',
      UnicodeEmojiNode(:final emoji) => emoji,
      UrlNode(:final url) => url,
      MentionNode(:final acct) => acct,
      HashtagNode(:final hashtag) => '#$hashtag',
      InlineCodeNode(:final code) || CodeBlockNode(:final code) => code,
      MathInlineNode(:final formula) ||
      MathBlockNode(:final formula) => formula,
      SearchNode(:final query) => query,
      _ => '',
    });
  }
  return buffer.toString();
}

String _text(String text, bool plain, bool shouldNyaize) {
  final normalized = text.replaceAll(_carriageReturns, '\n');
  final nyaized = shouldNyaize ? nyaize(normalized) : normalized;
  return plain ? nyaized.replaceAll('\n', ' ') : nyaized;
}
