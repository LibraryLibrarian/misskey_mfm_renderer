import 'package:flutter/material.dart';

import '../../../../core/widgets/mfm_preview_card.dart';
import '../../data/catalog_navigation.dart';
import '../../data/mfm_examples.dart';

class CatalogMenuList extends StatelessWidget {
  const CatalogMenuList({
    super.key,
    required this.menu,
    required this.onSelect,
  });

  final CatalogMenu menu;
  final ValueChanged<CatalogNode> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: PageStorageKey('catalog-scroll:${menu.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menu.children.length,
      itemBuilder: (context, index) {
        final node = menu.children[index];
        return ListTile(
          key: ValueKey('catalog-node:${node.id}'),
          title: Text(node.title),
          subtitle: Text(node.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(node),
        );
      },
    );
  }
}

class CatalogDetailList extends StatelessWidget {
  const CatalogDetailList({
    super.key,
    required this.page,
    required this.onTryExample,
  });

  final CatalogExamplePage page;
  final ValueChanged<MfmExample> onTryExample;

  @override
  Widget build(BuildContext context) {
    // データだけを平坦化し、見出しもカードも必要になった時に構築する。
    final rows = <({MfmFeatureGroup group, MfmExample? example})>[
      for (final group in page.groups) ...[
        (group: group, example: null),
        for (final example in group.examples) (group: group, example: example),
      ],
    ];
    return ListView.builder(
      key: PageStorageKey('catalog-scroll:${page.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final group = row.group;
        final example = row.example;
        if (example == null) {
          return Semantics(
            key: ValueKey('catalog-section:${group.id}'),
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (group.id == 'animation.timing') ...[
                    const SizedBox(height: 4),
                    const Text('共通の動作設定：Spinの遅延とTwitch / Shakeのeasing比較'),
                  ],
                ],
              ),
            ),
          );
        }
        return MfmPreviewCard(
          key: ValueKey(example.name),
          name: example.name,
          onTry: () => onTryExample(example),
          setupSummary: example.setupSummary,
          setupCode: example.setupCode,
          setupStorageKey: PageStorageKey(
            'catalog-setup:${page.id}/${group.id}/${example.name}',
          ),
          syntax: example.syntax,
          mfm: example.mfm,
          description: example.description,
          config: example.config,
          plain: example.plain,
          nowrap: example.nowrap,
        );
      },
    );
  }
}
