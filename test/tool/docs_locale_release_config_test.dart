import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/release_config.dart';

void main() {
  test('every documentation locale has a release version reference', () {
    final root = _packageRoot();
    final file = File.fromUri(root.uri.resolve('docs/locales.json'));
    final config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final locales = (config['locales'] as List).cast<String>();
    final expected = locales.map(
      (locale) => locale == config['defaultLocale']
          ? 'docs/docs/getting-started.md'
          : 'docs/i18n/$locale/docusaurus-plugin-content-docs/current/getting-started.md',
    );
    final actual = releaseConfig.versionReferencePaths.where(
      (path) => path.startsWith('docs/'),
    );
    expect(actual, unorderedEquals(expected));
  });
}

Directory _packageRoot() {
  var directory = Directory.current.absolute;
  while (true) {
    final pubspec = File.fromUri(directory.uri.resolve('pubspec.yaml'));
    final changelog = File.fromUri(directory.uri.resolve('CHANGELOG.md'));
    if (pubspec.existsSync() && changelog.existsSync()) return directory;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Could not find the package root.');
    }
    directory = parent;
  }
}
