import 'package:flutter/material.dart';

import '../../../core/widgets/example_setup_panel.dart';
import '../application/playground_controller.dart';
import 'widgets/mfm_input_field.dart';
import 'widgets/mfm_preview_panel.dart';

/// プレイグラウンドタブ
class PlaygroundTab extends StatelessWidget {
  const PlaygroundTab({
    super.key,
    required this.controller,
    required this.onClear,
  });

  final PlaygroundController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final example = controller.example;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (example != null) ...[
                        Text(
                          '選択中: ${example.name}',
                          style: theme.textTheme.titleMedium,
                        ),
                        ExampleSetupPanel(
                          key: ValueKey(controller.loadRevision),
                          summary: example.setupSummary,
                          code: example.setupCode,
                        ),
                        if (example.hasOverrides)
                          const Text(
                            '個別設定を優先し、未指定の項目は共通設定を継承します。'
                            'plain / nowrapも個別指定が優先します。',
                          ),
                      ] else
                        const Text('共通設定で表示しています'),
                      const SizedBox(height: 12),
                      MfmInputField(controller: controller.editor),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          if (example != null)
                            TextButton.icon(
                              key: const Key('releaseOverrides'),
                              onPressed: controller.releaseOverrides,
                              icon: const Icon(Icons.settings_backup_restore),
                              label: const Text('個別設定を解除'),
                            ),
                          TextButton.icon(
                            key: const Key('clearPlaygroundText'),
                            onPressed: onClear,
                            icon: const Icon(Icons.clear),
                            label: const Text('本文をクリア'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: theme.colorScheme.primaryContainer,
                child: Text(
                  'プレビュー',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              MfmPreviewPanel(
                key: ValueKey(controller.loadRevision),
                mfmText: controller.text,
                config: example?.config,
                plain: example?.plain,
                nowrap: example?.nowrap,
              ),
            ],
          ),
        );
      },
    );
  }
}
