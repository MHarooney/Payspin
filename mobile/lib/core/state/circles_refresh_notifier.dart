import 'package:flutter/foundation.dart';

/// Broadcasts circle list changes (create/join/activate/advance).
class CirclesRefreshNotifier extends ValueNotifier<int> {
  CirclesRefreshNotifier() : super(0);

  void bump() => value++;
}
