import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../settings/example_settings.dart';
import 'example_setup_panel.dart';

/// MFMプレビューカード
class MfmPreviewCard extends StatelessWidget {
  const MfmPreviewCard({
    super.key,
    required this.name,
    required this.syntax,
    required this.mfm,
    this.description,
    this.setupSummary,
    this.setupCode,
    this.setupStorageKey,
    this.onTry,
    this.config,
    this.plain,
    this.nowrap,
  });

  final String name;
  final String syntax;
  final String mfm;
  final String? description;
  final String? setupSummary;
  final String? setupCode;
  final PageStorageKey<String>? setupStorageKey;
  final VoidCallback? onTry;
  final MfmRenderConfig? config;
  final bool? plain;
  final bool? nowrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ExampleSettingsScope.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('copy:$name'),
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: 'MFMをコピー',
                ),
                if (onTry != null)
                  IconButton(
                    key: ValueKey('try:$name'),
                    onPressed: onTry,
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'この設定で試す',
                  ),
              ],
            ),
            if (config != null || plain != null || nowrap != null)
              Text(
                'コピーはMFM本文のみです。個別設定は含まれません。',
                style: theme.textTheme.bodySmall,
              ),

            // 構文表示
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                syntax,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // 説明（あれば）
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),

            if (setupSummary != null || setupCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ExampleSetupPanel(
                  summary: setupSummary,
                  code: setupCode,
                  expansionStorageKey: setupStorageKey,
                ),
              ),

            const Divider(height: 24),

            // MFMプレビュー
            MfmText(
              text: mfm,
              config: config ?? const MfmRenderConfig(),
              plain: plain ?? settings.plain,
              nowrap: nowrap ?? settings.nowrap,
              rootScale: settings.rootScale,
              isNote: settings.isNote,
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: mfm));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MFMをコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
