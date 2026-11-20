import 'package:flutter/foundation.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

int _debugParseCount = 0;

/// Counts actual parser invocations in debug builds, without a public export.
@visibleForTesting
int get debugMfmTextParseCount => _debugParseCount;

List<MfmNode> parseMfmText(String? source, {required bool simple}) {
  if (source == null || source.isEmpty) return [];

  assert(() {
    _debugParseCount++;
    return true;
  }());
  final parser = simple ? MfmParser().buildSimple() : MfmParser().build();
  final result = parser.parse(source);
  try {
    return result.value;
  } on FormatException {
    return [TextNode(source)];
  }
}
