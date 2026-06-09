import 'package:flutter/foundation.dart';

/// Broadcasts "support changed" so the inbox, thread, and Profile badge refetch
/// after a push arrives or a message is sent/read. Mirrors
/// [NotificationsRefreshNotifier] — a bumped counter, not a state framework.
class SupportRefreshNotifier extends ValueNotifier<int> {
  SupportRefreshNotifier() : super(0);

  void bump() => value++;
}
