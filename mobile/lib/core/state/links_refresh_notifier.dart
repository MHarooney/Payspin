import 'package:flutter/foundation.dart';

/// Broadcasts "payment links changed" so screens (e.g. the home list) can
/// reload after a create/cancel happened elsewhere in the navigation stack.
///
/// Intentionally tiny — a bumped counter, not a state framework. Registered as
/// a GetIt singleton and listened to by [ValueListenableBuilder]/[addListener].
class LinksRefreshNotifier extends ValueNotifier<int> {
  LinksRefreshNotifier() : super(0);

  /// Signal that the set of payment links changed.
  void bump() => value++;
}
