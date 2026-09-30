import 'package:flutter/widgets.dart';

/// Keep separately styled/tappable account parts as one accessible mention.
class MfmMentionTextSpan extends TextSpan {
  const MfmMentionTextSpan({required super.children, super.recognizer});

  @override
  void computeSemanticsInformation(
    List<InlineSpanSemanticsInformation> collector, {
    Locale? inheritedLocale,
    bool inheritedSpellOut = false,
  }) {
    // Only semantics is combined; glyph hit testing stays on the leaf spans.
    TextSpan(
      text: toPlainText(includeSemanticsLabels: false),
      recognizer: recognizer,
    ).computeSemanticsInformation(
      collector,
      inheritedLocale: inheritedLocale,
      inheritedSpellOut: inheritedSpellOut,
    );
  }
}
