import 'package:flutter/widgets.dart';

import '../../catalog/data/mfm_examples.dart';

class PlaygroundController extends ChangeNotifier {
  PlaygroundController() {
    editor.addListener(_onEditorChanged);
  }

  static const _initialText = r'''こんにちは！ 😊

@user #tag https://example.org/path?q=1#frag

$[clickable.ev=hello タップ]

**太字**や*斜体*も使えます。

$[x2 大きな文字]

$[fg.color=ff0000 赤い文字]

$[rotate.deg=10 傾いたテキスト]''';

  final editor = TextEditingController(text: _initialText);
  MfmExample? _example;
  String _baseline = _initialText;
  // 選択範囲やIME composingだけの変更ではプレビューを更新しない。
  String _lastNotifiedText = _initialText;
  int _loadRevision = 0;

  MfmExample? get example => _example;
  String get text => editor.text;
  int get loadRevision => _loadRevision;
  bool get needsDiscardConfirmation => text.isNotEmpty && text != _baseline;

  void load(MfmExample example) {
    _example = example;
    _loadRevision++;
    _replaceText(example.mfm);
  }

  void clearText() => _replaceText('');

  void releaseOverrides() {
    if (_example == null) return;
    _example = null;
    notifyListeners();
  }

  void _replaceText(String text) {
    _baseline = text;
    _lastNotifiedText = text;
    editor.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    notifyListeners();
  }

  void _onEditorChanged() {
    if (text == _lastNotifiedText) return;
    _lastNotifiedText = text;
    notifyListeners();
  }

  @override
  void dispose() {
    editor
      ..removeListener(_onEditorChanged)
      ..dispose();
    super.dispose();
  }
}
