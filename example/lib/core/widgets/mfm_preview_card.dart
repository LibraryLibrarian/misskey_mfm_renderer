import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../emoji/emoji_service.dart';

/// MFMプレビューカード
class MfmPreviewCard extends StatelessWidget {
  const MfmPreviewCard({
    super.key,
    required this.name,
    required this.syntax,
    required this.mfm,
    this.description,
    this.config,
  });

  final String name;
  final String syntax;
  final String mfm;
  final String? description;
  final MfmRenderConfig? config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: 'MFMをコピー',
                ),
              ],
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

            const Divider(height: 24),

            // MFMプレビュー
            MfmText(
              text: mfm,
              config: (config ?? const MfmRenderConfig()).copyWith(
                emojiBuilder: EmojiService.instance.isInitialized
                    ? (name) => MfmCustomEmoji(
                        name: name,
                        resolver: EmojiService.instance.resolver.call,
                      )
                    : null,
              ),
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
