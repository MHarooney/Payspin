class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;

  bool get isUnread => readAt == null;

  /// Payment link id carried in the notification payload, when present.
  String? get linkId => data['linkId'] as String?;

  String get timeLabel {
    try {
      final d = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.nextCursor,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final String? nextCursor;
}
