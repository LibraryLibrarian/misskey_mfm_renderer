import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../../../../core/settings/example_settings.dart';

/// MFMプレビューパネル
class MfmPreviewPanel extends StatelessWidget {
  const MfmPreviewPanel({
    super.key,
    required this.mfmText,
    this.config,
  });

  final String mfmText;
  final MfmRenderConfig? config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ExampleSettingsScope.of(context);

    if (mfmText.isEmpty) {
      return Center(
        child: Text(
          'プレビューがここに表示されます',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MfmText(
        text: mfmText,
        config: config ?? const MfmRenderConfig(),
        plain: settings.plain,
        nowrap: settings.nowrap,
        rootScale: settings.rootScale,
        isNote: settings.isNote,
      ),
    );
  }
}
