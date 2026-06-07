/// Mobile release version — synced with `pubspec.yaml` (`version: semver+buildNumber`).
///
/// Pre-1.0 builds use `0.x.y` semver. [buildNumber] increments on every store/APK
/// upload and maps to iOS `CFBundleVersion` / Android `versionCode`.
abstract final class AppVersion {
  static const String semver = '0.9.0';
  static const int buildNumber = 19;

  /// Filename-safe id for dist artifacts, e.g. `0.9.0-build19`.
  static String get releaseId => '$semver-build$buildNumber';

  /// User-facing label in Settings → Version.
  static String get label => isPreRelease ? 'Beta $semver ($buildNumber)' : '$semver ($buildNumber)';

  /// Store-facing version string (TestFlight / Play Console display).
  static String get storeVersion => semver;

  static bool get isPreRelease {
    final parts = semver.split('.');
    return parts.isNotEmpty && parts[0] == '0';
  }
}
