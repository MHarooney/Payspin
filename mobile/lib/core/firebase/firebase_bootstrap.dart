import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase exactly once, tolerating an un-provisioned environment.
///
/// Until `flutterfire configure` generates `firebase_options.dart` and the
/// native config files (`google-services.json` / `GoogleService-Info.plist`)
/// are in place, `Firebase.initializeApp()` throws. We swallow that so the app
/// still boots; push, SMS OTP and Remote Config simply stay disabled and
/// activate automatically once the project is wired.
abstract final class FirebaseBootstrap {
  static bool _available = false;
  static bool _attempted = false;

  /// True when Firebase initialized successfully on this launch.
  static bool get available => _available;

  static Future<void> ensureInitialized() async {
    if (_attempted) return;
    _attempted = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('Firebase not configured — push/SMS/remote-config disabled ($e)');
    }
  }
}
