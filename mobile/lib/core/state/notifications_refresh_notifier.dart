import 'package:flutter/foundation.dart';

/// Broadcasts "notifications changed" so the home bell badge and the inbox can
/// refetch after a push arrives or a row is marked read. Mirrors
/// [LinksRefreshNotifier] — a bumped counter, not a state framework.
class NotificationsRefreshNotifier extends ValueNotifier<int> {
  NotificationsRefreshNotifier() : super(0);

  void bump() => value++;
}
