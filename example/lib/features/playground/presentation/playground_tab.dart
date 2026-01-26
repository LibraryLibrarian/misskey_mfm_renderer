import 'package:flutter/material.dart';

import 'widgets/mfm_input_field.dart';
import 'widgets/mfm_preview_panel.dart';

/// プレイグラウンドタブ
class PlaygroundTab extends StatefulWidget {
  const PlaygroundTab({super.key});

  @override
  State<PlaygroundTab> createState() => _PlaygroundTabState();
}

class _PlaygroundTabState extends State<PlaygroundTab>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  String _mfmText = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.text = '''こんにちは！ 😊

**太字**や*斜体*も使えます。

\$[x2 大きな文字]

\$[fg.color=ff0000 赤い文字]

\$[rotate.deg=10 傾いたテキスト]''';
    _mfmText = _controller.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            children: [
              MfmInputField(
                controller: _controller,
                onChanged: (value) {
                  setState(() {
                    _mfmText = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearInput,
                  icon: const Icon(Icons.clear),
                  label: const Text('クリア'),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.primaryContainer,
          child: Text(
            'プレビュー',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        Expanded(
          child: MfmPreviewPanel(
            mfmText: _mfmText,
          ),
        ),
      ],
    );
  }

  void _clearInput() {
    _controller.clear();
    setState(() {
      _mfmText = '';
    });
  }
}
