/// Support categories shown as chips when starting a new request. Values match
/// the backend `SupportCategory` (PAYMENT | ACCOUNT | CIRCLE | OTHER).
enum SupportCategory { payment, account, circle, other }

extension SupportCategoryX on SupportCategory {
  String get wire => switch (this) {
        SupportCategory.payment => 'PAYMENT',
        SupportCategory.account => 'ACCOUNT',
        SupportCategory.circle => 'CIRCLE',
        SupportCategory.other => 'OTHER',
      };

  static SupportCategory? fromWire(String? value) => switch (value) {
        'PAYMENT' => SupportCategory.payment,
        'ACCOUNT' => SupportCategory.account,
        'CIRCLE' => SupportCategory.circle,
        'OTHER' => SupportCategory.other,
        _ => null,
      };
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.direction,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });

  final String id;

  /// `IN` = the user's own message, `OUT` = a Support reply.
  final String direction;
  final String body;
  final String authorName;
  final String createdAt;

  bool get isFromUser => direction == 'IN';

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'] as String,
        direction: json['direction'] as String? ?? 'IN',
        body: json['body'] as String? ?? '',
        authorName: json['authorName'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  String get timeLabel => _relative(createdAt);
}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.subject,
    required this.category,
    required this.contextRef,
    required this.status,
    required this.userUnread,
    required this.preview,
    required this.lastMessageAt,
  });

  final String id;
  final String subject;
  final SupportCategory? category;
  final String? contextRef;
  final String status;
  final bool userUnread;
  final String preview;
  final String lastMessageAt;

  bool get isResolved => status == 'RESOLVED';
  String get timeLabel => _relative(lastMessageAt);

  factory SupportThread.fromJson(Map<String, dynamic> json) => SupportThread(
        id: json['id'] as String,
        subject: json['subject'] as String? ?? 'Support request',
        category: SupportCategoryX.fromWire(json['category'] as String?),
        contextRef: json['contextRef'] as String?,
        status: json['status'] as String? ?? 'OPEN',
        userUnread: json['userUnread'] as bool? ?? false,
        preview: json['preview'] as String? ?? '',
        lastMessageAt: json['lastMessageAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class SupportThreadDetail extends SupportThread {
  const SupportThreadDetail({
    required super.id,
    required super.subject,
    required super.category,
    required super.contextRef,
    required super.status,
    required super.userUnread,
    required super.preview,
    required super.lastMessageAt,
    required this.messages,
  });

  final List<SupportMessage> messages;

  factory SupportThreadDetail.fromJson(Map<String, dynamic> json) {
    final base = SupportThread.fromJson(json);
    final messages = (json['messages'] as List<dynamic>? ?? [])
        .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return SupportThreadDetail(
      id: base.id,
      subject: base.subject,
      category: base.category,
      contextRef: base.contextRef,
      status: base.status,
      userUnread: base.userUnread,
      preview: base.preview,
      lastMessageAt: base.lastMessageAt,
      messages: messages,
    );
  }
}

String _relative(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return '${d.day} ${months[d.month - 1]}';
  } catch (_) {
    return '';
  }
}
