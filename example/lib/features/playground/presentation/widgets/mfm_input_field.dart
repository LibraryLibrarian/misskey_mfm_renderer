import 'package:flutter/material.dart';

/// MFM入力フィールド
class MfmInputField extends StatelessWidget {
  const MfmInputField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 5,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        hintText: r'''MFMを入力してください...

例:
**太字** *斜体* ~~打ち消し~~
$[x2 大きな文字]
$[fg.color=ff0000 赤い文字]''',
        alignLabelWithHint: true,
      ),
      onChanged: onChanged,
    );
  }
}
