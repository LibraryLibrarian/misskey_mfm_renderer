import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

import '../../../../core/emoji/emoji_service.dart';
import '../../../../core/widgets/mfm_preview_card.dart';
import '../../data/mfm_examples.dart';

/// カタログセクション
class CatalogSection extends StatelessWidget {
  const CatalogSection({
    super.key,
    required this.category,
  });

  final MfmCategory category;

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
            name: example.name,
            syntax: example.syntax,
            mfm: example.mfm,
            description: example.description,
            config: const MfmRenderConfig().copyWith(
              emojiBuilder: EmojiService.instance.isInitialized
                  ? (name) => MfmCustomEmoji(
                      name: name,
                      resolver: EmojiService.instance.resolver.call,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
