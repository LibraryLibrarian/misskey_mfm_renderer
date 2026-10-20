import 'release_project.dart';

/// Release settings for this repository.
///
/// `release_project.dart` is shared verbatim across the packages that use this
/// tool. Everything specific to this repository belongs here instead.
const releaseConfig = ReleaseConfig(
  versionReferencePaths: <String>[
    'README.md',
    'README.ja.md',
    'docs/docs/getting-started.md',
    'docs/i18n/ja/docusaurus-plugin-content-docs/current/getting-started.md',
    'docs/i18n/zh-Hans/docusaurus-plugin-content-docs/current/getting-started.md',
    'docs/i18n/de/docusaurus-plugin-content-docs/current/getting-started.md',
    'docs/i18n/fr/docusaurus-plugin-content-docs/current/getting-started.md',
    'docs/i18n/ko/docusaurus-plugin-content-docs/current/getting-started.md',
  ],
  // Each entry point includes an installation example. The count is not fixed
  // so adding or removing an example stays a documentation change rather
  // than a release-tool change.
  referenceCount: VersionReferenceCount.atLeastOne(),
  // The bundled example depends on this package through a path dependency, so
  // its lock file pins the version as well.
  exampleLockPath: 'example/pubspec.lock',
);
