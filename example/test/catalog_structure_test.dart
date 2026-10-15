import 'dart:convert';
import 'dart:io';

import 'package:example/features/catalog/data/catalog_navigation.dart';
import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('navigation has seven entries and each group appears on one page', () {
    final nodes = <CatalogNode>[];
    void visit(CatalogNode node) {
      nodes.add(node);
      if (node is CatalogMenu) node.children.forEach(visit);
    }

    visit(CatalogNavigation.root);
    expect(nodes.map((node) => node.id).toSet(), hasLength(nodes.length));
    final menus = nodes.whereType<CatalogMenu>().toList();
    expect(menus.map((menu) => menu.id), ['catalog', 'fn', 'animation']);
    expect(menus.map((menu) => menu.children.length), [7, 5, 3]);
    expect(CatalogNavigation.root.children.map((node) => node.id), [
      'text',
      'blocks',
      'links',
      'emoji',
      'fn',
      'combinations',
      'mentions',
    ]);
    final pages = nodes.whereType<CatalogExamplePage>().toList();
    final expected = <String, List<String>>{
      'text': [
        'text.bold',
        'text.italic',
        'text.strike',
        'text.small',
        'text.plain',
        'text.center',
      ],
      'blocks': [
        'blocks.quote',
        'blocks.code-block',
        'blocks.inline-code',
        'blocks.math-block',
        'blocks.math-inline',
        'blocks.search',
      ],
      'links': [
        'links.url',
        'links.link',
        'links.mention-syntax',
        'links.hashtag',
      ],
      'emoji': ['emoji.unicode', 'emoji.twemoji', 'emoji.custom'],
      'size': ['size.x2', 'size.x3', 'size.x4'],
      'transform': [
        'transform.flip',
        'transform.rotate',
        'transform.scale',
        'transform.position',
      ],
      'style': [
        'style.foreground',
        'style.background',
        'style.border',
        'style.font',
      ],
      'special': [
        'special.blur',
        'special.ruby',
        'special.unixtime',
        'special.clickable',
      ],
      'animation.rotation': [
        'animation.spin',
        'animation.jump',
        'animation.bounce',
      ],
      'animation.motion': [
        'animation.shake',
        'animation.twitch',
        'animation.jelly',
        'animation.tada',
        'animation.timing',
      ],
      'animation.color': ['animation.rainbow', 'animation.sparkle'],
      'combinations': ['combinations.combined', 'combinations.settings'],
      'mentions': ['mentions.presentation', 'mentions.display-name'],
    };
    expect(pages, hasLength(13));
    for (final page in pages) {
      expect(page.groups.map((group) => group.id), expected[page.id]);
    }
    expect(pages.map((page) => page.groups.expand((g) => g.examples).length), [
      8,
      15,
      12,
      9,
      4,
      10,
      17,
      13,
      12,
      12,
      7,
      5,
      4,
    ]);
    final groups = pages.expand((page) => page.groups).toList();
    final original = MfmExamples.categories.expand(
      (category) => category.groups,
    );
    expect(groups, hasLength(48));
    expect(groups.toSet(), hasLength(48));
    expect(groups, unorderedEquals(original));
    for (final group in groups) {
      expect(group, same(original.singleWhere((g) => g.id == group.id)));
    }
    final examples = groups.expand((group) => group.examples).toList();
    expect(examples, hasLength(128));
    expect(examples.toSet(), hasLength(128));
    expect(
      examples,
      unorderedEquals(original.expand((group) => group.examples)),
    );
  });

  test('all original examples belong to exactly one explicit feature', () {
    final expectedNames =
        (jsonDecode(
                  File(
                    'test/fixtures/catalog_example_names.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<String>();
    const categories = MfmExamples.categories;
    final groups = categories.expand((category) => category.groups).toList();
    final examples = groups.expand((group) => group.examples).toList();
    expect(categories, hasLength(11));
    expect(categories.map((category) => category.id).toSet(), hasLength(11));
    expect(groups.map((group) => group.id).toSet(), hasLength(groups.length));
    expect(examples, hasLength(128));
    expect(examples.toSet(), hasLength(128));
    expect(
      examples.map((example) => example.name),
      unorderedEquals(expectedNames),
    );
    for (final category in categories) {
      expect(category.description, isNotEmpty);
      expect(category.groups, isNotEmpty);
      expect(
        category.examples,
        orderedEquals(category.groups.expand((group) => group.examples)),
      );
    }
    for (final group in groups) {
      expect(group.id, isNotEmpty);
      expect(group.title, isNotEmpty);
      expect(group.examples, isNotEmpty);
    }
  });

  test('related variants and settings demonstrations have explicit homes', () {
    final groups = {
      for (final category in MfmExamples.categories)
        for (final group in category.groups) group.id: group,
    };
    expect(groups['animation.spin']!.examples, hasLength(8));
    expect(groups['style.border']!.examples, hasLength(7));
    expect(groups['special.unixtime']!.examples, hasLength(9));
    expect(
      groups['transform.position']!.examples.map((example) => example.name),
      ['Position', 'Position (負値)', 'Position (現在の文字サイズ)'],
    );
    expect(
      groups['animation.timing']!.examples.map((example) => example.name),
      ['Twitch / Shake (easing)', 'アニメーション遅延'],
    );
    expect(groups['links.mention-syntax']!.examples, hasLength(2));
    expect(groups['mentions.presentation']!.examples, hasLength(3));
    expect(groups['text.plain']!.examples.single.name, 'Plain');
    expect(
      groups['combinations.settings']!.examples.map((example) => example.name),
      ['Nyaize', 'Plain / Nowrap'],
    );
  });
}
