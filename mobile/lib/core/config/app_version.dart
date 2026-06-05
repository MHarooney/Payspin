/// Human-facing release serial for QA builds and APK/IPA filenames.
///
/// Serial format: `V{major}.{minor}{letter}` — e.g. V1.6a, V1.6b, … V1.6z, V1.7a.
/// [buildNumber] increments on every `./scripts/dev/build-android-release.sh` run
/// and stays in sync with pubspec `version: x.y.z+N`.
abstract final class AppVersion {
  static const String serial = 'V1.7g';
  static const String semver = '1.7.0';
  static const int buildNumber = 13;

  /// Full label for About / debug surfaces.
  static String get label => '$serial ($semver+$buildNumber)';
}
