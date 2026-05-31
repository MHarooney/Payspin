import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<NotificationPage> list({String? cursor, int limit});
  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
