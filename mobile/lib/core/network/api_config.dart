import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001/v1',
  );

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
        'release build. Pass --dart-define=API_URL=https://api.payspin.app/v1.',
      );
    }
  }
}
