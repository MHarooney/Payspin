import '../../core/state/notifications_refresh_notifier.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/payspin_api_client.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._api, this._refresh);

  final PayspinApiClient _api;
  final NotificationsRefreshNotifier _refresh;

  @override
  Future<NotificationPage> list({String? cursor, int limit = 20}) async {
    final json = await _api.listNotifications(cursor: cursor, limit: limit);
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => _map(e as Map<String, dynamic>))
        .toList();
    return NotificationPage(
      items: items,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  Future<int> unreadCount() async {
    final json = await _api.listNotifications(limit: 1);
    return (json['unreadCount'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markRead(String id) async {
    await _api.markNotificationRead(id);
    _refresh.bump();
  }

  @override
  Future<void> markAllRead() async {
    await _api.markAllNotificationsRead();
    _refresh.bump();
  }

  AppNotification _map(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
