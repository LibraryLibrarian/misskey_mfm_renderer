import 'package:flutter/material.dart';

import '../../../../core/widgets/mfm_preview_card.dart';
import '../../data/mfm_examples.dart';

/// カタログセクション
class CatalogSection extends StatelessWidget {
  const CatalogSection({
    super.key,
    required this.category,
    required this.onTryExample,
  });

  final MfmCategory category;
  final ValueChanged<MfmExample> onTryExample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            category.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // サンプルカード一覧
        ...category.examples.map(
          (example) => MfmPreviewCard(
            key: ValueKey(example.name),
            name: example.name,
            onTry: () => onTryExample(example),
            setupSummary: example.setupSummary,
            setupCode: example.setupCode,
            syntax: example.syntax,
            mfm: example.mfm,
            description: example.description,
            config: example.config,
            plain: example.plain,
            nowrap: example.nowrap,
          ),
        ),
      ],
    );
  }
}
