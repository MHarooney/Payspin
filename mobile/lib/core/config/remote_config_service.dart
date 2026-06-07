import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';

/// Firebase Remote Config wrapper with safe defaults. Behaves as a constant
/// provider (defaults only) when Firebase is not configured, so callers can read
/// values unconditionally.
class RemoteConfigService {
  static const _defaults = <String, dynamic>{
    'min_app_version': '0.9.0',
    'min_shorebird_patch': 0,
    'payer_poll_interval_ms': 3500,
    'feature_circles_enabled': false,
    'notification_empty_copy': 'No notifications yet',
  };

  FirebaseRemoteConfig? _rc;

  Future<void> init() async {
    if (!FirebaseBootstrap.available) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await rc.setDefaults(_defaults.map((k, v) => MapEntry(k, v as Object)));
      await rc.fetchAndActivate();
      _rc = rc;
    } catch (e) {
      debugPrint('RemoteConfig init failed, using defaults: $e');
    }
  }

  String getString(String key) =>
      _rc?.getString(key) ?? _defaults[key]?.toString() ?? '';

  int getInt(String key) =>
      _rc?.getInt(key) ?? (_defaults[key] as int? ?? 0);

  bool getBool(String key) =>
      _rc?.getBool(key) ?? (_defaults[key] as bool? ?? false);

  String get minAppVersion => getString('min_app_version');
  int get payerPollIntervalMs => getInt('payer_poll_interval_ms');
  String get notificationEmptyCopy => getString('notification_empty_copy');
}
