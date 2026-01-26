import 'package:flutter/material.dart';

import '../data/mfm_examples.dart';
import 'widgets/catalog_section.dart';

/// カタログタブ
class CatalogTab extends StatelessWidget {
  const CatalogTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: MfmExamples.categories.length,
      itemBuilder: (context, index) {
        return CatalogSection(
          category: MfmExamples.categories[index],
        );
      },
    );
  }
}
