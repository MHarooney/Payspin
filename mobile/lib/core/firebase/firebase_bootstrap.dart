import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase exactly once, tolerating an un-provisioned environment.
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
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('Firebase not configured — push/SMS/remote-config disabled ($e)');
    }
  }
}
