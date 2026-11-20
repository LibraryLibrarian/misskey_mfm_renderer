import 'mfm_examples.dart';

/// 例の定義とは独立した、カタログの画面構成。
sealed class CatalogNode {
  const CatalogNode({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

class CatalogMenu extends CatalogNode {
  const CatalogMenu({
    required super.id,
    required super.title,
    required super.description,
    required this.children,
  });

  final List<CatalogNode> children;
}

class CatalogExamplePage extends CatalogNode {
  const CatalogExamplePage({
    required super.id,
    required super.title,
    required super.description,
    required this.groups,
  });

  final List<MfmFeatureGroup> groups;
}

class CatalogNavigation {
  CatalogNavigation._();

  static final root = CatalogMenu(
    id: 'catalog',
    title: 'MFM Renderer',
    description: '',
    children: [
      _category('text'),
      _category('blocks'),
      _category('links'),
      _category('emoji'),
      CatalogMenu(
        id: 'fn',
        title: 'fn関数',
        description: 'サイズ・変換・スタイル・特殊・アニメーション',
        children: [
          _category('size', title: 'サイズ'),
          _category('transform', title: '変換'),
          _category('style', title: 'スタイル'),
          _category('special', title: '特殊'),
          CatalogMenu(
            id: 'animation',
            title: 'アニメーション',
            description: '回転・跳躍、揺れ・伸縮、色・きらめき',
            children: [
              CatalogExamplePage(
                id: 'animation.rotation',
                title: '回転・跳躍',
                description: 'Spin / Jump / Bounce',
                groups: _groups([
                  'animation.spin',
                  'animation.jump',
                  'animation.bounce',
                ]),
              ),
              CatalogExamplePage(
                id: 'animation.motion',
                title: '揺れ・伸縮・動作設定',
                description: 'Shake / Twitch / Jelly / Tada / 遅延・easing',
                groups: _groups([
                  'animation.shake',
                  'animation.twitch',
                  'animation.jelly',
                  'animation.tada',
                  'animation.timing',
                ]),
              ),
              CatalogExamplePage(
                id: 'animation.color',
                title: '色・きらめき',
                description: 'Rainbow / Sparkle',
                groups: _groups(['animation.rainbow', 'animation.sparkle']),
              ),
            ],
          ),
        ],
      ),
      _category('combinations'),
      _category('mentions'),
    ],
  );

  static CatalogExamplePage _category(String id, {String? title}) {
    final category = MfmExamples.categories.singleWhere((c) => c.id == id);
    return CatalogExamplePage(
      id: category.id,
      title: title ?? category.title,
      description: category.description,
      groups: category.groups,
    );
  }

  static List<MfmFeatureGroup> _groups(List<String> ids) {
    final groups = MfmExamples.categories.expand((c) => c.groups);
    return [for (final id in ids) groups.singleWhere((g) => g.id == id)];
  }
}
