import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';
import '../state/links_refresh_notifier.dart';
import '../state/notifications_refresh_notifier.dart';
import '../../data/datasources/payspin_api_client.dart';

/// Background isolate handler. Must be a top-level function. The OS renders the
/// `notification` block automatically; nothing else is required here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: in-app inbox is the source of truth and is refetched on resume.
}

/// Bridges FCM to the app: registers the device token with the backend, refreshes
/// the inbox/home on foreground pushes, and surfaces "open link" requests for the
/// shell to navigate. All operations no-op when Firebase is not configured.
class PushService {
  PushService(this._api, this._notificationsRefresh, this._linksRefresh);

  final PayspinApiClient _api;
  final NotificationsRefreshNotifier _notificationsRefresh;
  final LinksRefreshNotifier _linksRefresh;

  /// Emits a payment-link id when a push should open that link's detail screen.
  final ValueNotifier<String?> openLinkRequests = ValueNotifier<String?>(null);

  bool _initialized = false;

  /// Call after a successful login/session restore. Idempotent.
  Future<void> init() async {
    if (_initialized || !FirebaseBootstrap.available) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      await _registerToken(await messaging.getToken());
      messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen((message) {
        // Foreground: a new event arrived → refetch inbox + links so the badge
        // and home update without the user doing anything (React-Query-on-push).
        _notificationsRefresh.bump();
        _linksRefresh.bump();
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleOpen(initial);
    } catch (e) {
      debugPrint('PushService init failed: $e');
    }
  }

  Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _api.registerDeviceToken(
        fcmToken: token,
        platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown'),
      );
    } catch (e) {
      debugPrint('registerDeviceToken failed: $e');
    }
  }

  void _handleOpen(RemoteMessage message) {
    final linkId = message.data['linkId'] as String?;
    if (linkId != null && linkId.isNotEmpty) {
      openLinkRequests.value = linkId;
    }
    _notificationsRefresh.bump();
    _linksRefresh.bump();
  }
}
