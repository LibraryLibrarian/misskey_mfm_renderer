import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/release_project.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync(
      'misskey_mfm_renderer_release_tools_',
    );
    _createProject(root);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  test('bumpVersion updates all version references and CHANGELOG', () {
    final updatedPaths = bumpVersion(
      root,
      '1.0.0-beta.4',
      releaseDate: DateTime.utc(2026, 8, 13),
    );

    expect(_read(root, 'pubspec.yaml'), contains('version: 1.0.0-beta.4'));
    for (final path in versionReferencePaths) {
      expect(
        _read(root, path),
        contains('misskey_mfm_renderer: ^1.0.0-beta.4'),
        reason: path,
      );
    }
    expect(
      _read(root, 'CHANGELOG.md'),
      contains(
        '## [Unreleased]\n\n'
        '## 1.0.0-beta.4 - 2026-08-13\n\n'
        '### Added',
      ),
    );
    expect(
      updatedPaths,
      containsAll(<String>[
        'pubspec.yaml',
        ...versionReferencePaths,
        'CHANGELOG.md',
      ]),
    );
    expect(() => verifyRelease(root, '1.0.0-beta.4'), returnsNormally);
  });

  test('bumpVersion updates multiple references in the same file', () {
    final path = versionReferencePaths.first;
    _write(
      root,
      path,
      'dependencies:\n'
      '  misskey_mfm_renderer: ^1.0.0-beta.3\n\n'
      'dev_dependencies:\n'
      '  misskey_mfm_renderer: ^1.0.0-beta.3\n',
    );

    bumpVersion(
      root,
      '1.0.0-beta.4',
      releaseDate: DateTime.utc(2026, 8, 13),
    );

    final references = RegExp(
      r'misskey_mfm_renderer: \^1\.0\.0-beta\.4',
    ).allMatches(_read(root, path));
    expect(references, hasLength(2));
  });

  test('bumpVersion does not write files when a reference is inconsistent', () {
    _write(
      root,
      versionReferencePaths.first,
      'dependencies:\n  misskey_mfm_renderer: ^1.0.0-beta.2\n',
    );
    final originalPubspec = _read(root, 'pubspec.yaml');
    final originalChangelog = _read(root, 'CHANGELOG.md');

    expect(
      () => bumpVersion(root, '1.0.0-beta.4'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains(versionReferencePaths.first),
        ),
      ),
    );
    expect(_read(root, 'pubspec.yaml'), originalPubspec);
    expect(_read(root, 'CHANGELOG.md'), originalChangelog);
  });

  test('verifyRelease rejects a mismatched documentation version', () {
    _write(
      root,
      versionReferencePaths.last,
      'dependencies:\n  misskey_mfm_renderer: ^1.0.0-beta.2\n',
    );

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains(versionReferencePaths.last),
        ),
      ),
    );
  });

  test('verifyRelease rejects one mismatched reference among multiple', () {
    final path = versionReferencePaths.last;
    _write(
      root,
      path,
      'dependencies:\n'
      '  misskey_mfm_renderer: ^1.0.0-beta.3\n\n'
      'dev_dependencies:\n'
      '  misskey_mfm_renderer: ^1.0.0-beta.2\n',
    );

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          allOf(contains(path), contains('^1.0.0-beta.2')),
        ),
      ),
    );
  });

  test('verifyRelease rejects an invalid CHANGELOG date', () {
    final changelog = _read(
      root,
      'CHANGELOG.md',
    ).replaceFirst('2026-08-05', '2026-02-30');
    _write(root, 'CHANGELOG.md', changelog);

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('invalid release date'),
        ),
      ),
    );
  });

  test('extractReleaseNotes returns only the requested release body', () {
    final notes = extractReleaseNotes(root, '1.0.0-beta.3');

    expect(notes, '### Added\n\n- Released change\n');
    expect(notes, isNot(contains('Pending change')));
    expect(notes, isNot(contains('1.0.0-beta.2')));
  });

  test('extractReleaseNotes rejects a release without notes', () {
    _write(
      root,
      'CHANGELOG.md',
      '# Changelog\n\n'
          '## [Unreleased]\n\n'
          '## 1.0.0-beta.3 - 2026-08-05\n\n'
          '## 1.0.0-beta.2 - 2026-07-01\n\n'
          '### Fixed\n\n'
          '- Older change\n',
    );

    expect(
      () => extractReleaseNotes(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('no release notes'),
        ),
      ),
    );
  });

  test('release tools reject invalid Semantic Versions', () {
    expect(
      () => bumpVersion(root, '1.0'),
      throwsA(isA<ReleaseToolException>()),
    );
    expect(
      () => verifyRelease(root, '1.0.0-01'),
      throwsA(isA<ReleaseToolException>()),
    );
  });
}

void _createProject(Directory root) {
  _write(
    root,
    'pubspec.yaml',
    'name: misskey_mfm_renderer\n'
        'version: 1.0.0-beta.3\n',
  );
  for (final path in versionReferencePaths) {
    _write(
      root,
      path,
      '# Usage\n\n'
      'dependencies:\n'
      '  misskey_mfm_renderer: ^1.0.0-beta.3\n',
    );
  }
  _write(
    root,
    'CHANGELOG.md',
    '# Changelog\n\n'
        '## [Unreleased]\n\n'
        '### Added\n\n'
        '- Pending change\n\n'
        '## 1.0.0-beta.3 - 2026-08-05\n\n'
        '### Added\n\n'
        '- Released change\n\n'
        '## 1.0.0-beta.2 - 2026-07-01\n\n'
        '### Fixed\n\n'
        '- Older change\n',
  );
}

void _write(Directory root, String path, String content) {
  final file = File.fromUri(root.uri.resolve(path));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _read(Directory root, String path) =>
    File.fromUri(root.uri.resolve(path)).readAsStringSync();
