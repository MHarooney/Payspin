import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Compile-time override via `--dart-define=API_URL=...`.
  static const String _fromEnv = String.fromEnvironment('API_URL');

  /// Production VM (Hetzner). Used as the debug default so simulator runs work
  /// without passing dart-define on every launch.
  static const String productionUrl = 'http://178.105.118.225/v1';

  static const String _localUrl = 'http://localhost:3001/v1';

  /// Resolved API base. Prefer an explicit `API_URL` dart-define; otherwise
  /// debug builds talk to [productionUrl] and tests can override via dart-define.
  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kDebugMode) return productionUrl;
    return _localUrl;
  }

  /// True when [baseUrl] points at a developer-only loopback host that can
  /// never be reachable from a shipped app.
  static bool get isLocalHost =>
      baseUrl.contains('localhost') ||
      baseUrl.contains('127.0.0.1') ||
      baseUrl.contains('10.0.2.2');

  /// Fail fast if a release build was compiled without a real `API_URL`, so we
  /// never ship a binary that silently talks to a local dev server.
  static void assertValidForRelease() {
    if (kReleaseMode && isLocalHost) {
      throw StateError(
        'API_URL is "$baseUrl", which is a local dev host and cannot work in a '
        'release build. Pass --dart-define=API_URL=$productionUrl.',
      );
    }
  }
}
