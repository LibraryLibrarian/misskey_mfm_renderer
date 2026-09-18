import 'release_project.dart';

/// Release settings for this repository.
///
/// `release_project.dart` is shared verbatim across the packages that use this
/// tool. Everything specific to this repository belongs here instead.
const releaseConfig = ReleaseConfig(
  versionReferencePaths: <String>['README.md', 'README.ja.md'],
  // Each README shows the constraint twice. The count is not fixed here so
  // that adding or removing an installation example stays a documentation
  // change rather than a release-tool change.
  referenceCount: VersionReferenceCount.atLeastOne(),
  // The bundled example depends on this package through a path dependency, so
  // its lock file pins the version as well.
  exampleLockPath: 'example/pubspec.lock',
);
