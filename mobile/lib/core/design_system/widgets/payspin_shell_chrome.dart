import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/payspin_motion.dart';

/// Drives hide/show of shell chrome (bottom nav + FAB) from scroll gestures.
class ShellChromeController extends ChangeNotifier {
  bool _visible = true;
  double _scrollAccumulator = 0;

  static const double hideScrollThreshold = 14;
  static const double minPixelsToHide = 56;

  bool get visible => _visible;

  void reset() => _setVisible(true);

  /// Returns false so notifications keep bubbling to other listeners (e.g. peel).
  bool handleScrollNotification(ScrollNotification notification, {bool reduced = false}) {
    if (reduced) {
      if (!_visible) reset();
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) return false;
      _scrollAccumulator += delta;
      final pixels = notification.metrics.pixels;

      if (_scrollAccumulator > hideScrollThreshold && pixels > minPixelsToHide) {
        _setVisible(false);
        _scrollAccumulator = 0;
      } else if (_scrollAccumulator < -hideScrollThreshold) {
        _setVisible(true);
        _scrollAccumulator = 0;
      }
    } else if (notification is ScrollEndNotification) {
      _scrollAccumulator = 0;
      if (notification.metrics.pixels <= notification.metrics.minScrollExtent + 2) {
        _setVisible(true);
      }
    }

    return false;
  }

  void _setVisible(bool value) {
    if (_visible == value) return;
    _visible = value;
    notifyListeners();
  }
}

/// Forwards descendant [ScrollNotification]s to [ShellChromeController].
class PayspinShellScrollListener extends StatelessWidget {
  const PayspinShellScrollListener({
    super.key,
    required this.controller,
    required this.child,
  });

  final ShellChromeController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => controller.handleScrollNotification(n, reduced: reduced),
      child: child,
    );
  }
}

/// Slides chrome off-screen when [controller.visible] is false.
class PayspinShellChromeSlide extends StatelessWidget {
  const PayspinShellChromeSlide({
    super.key,
    required this.controller,
    required this.child,
    this.ignorePointerWhenHidden = true,
  });

  final ShellChromeController controller;
  final Widget child;
  final bool ignorePointerWhenHidden;

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visible = controller.visible;
        final slide = visible ? Offset.zero : const Offset(0, 1.15);
        Widget chrome = child;
        if (ignorePointerWhenHidden && !visible) {
          chrome = IgnorePointer(child: chrome);
        }
        if (reduced) return chrome;
        return AnimatedSlide(
          offset: slide,
          duration: PayspinMotion.medium,
          curve: visible ? PayspinMotion.easeEnter : PayspinMotion.easeExit,
          child: chrome,
        );
      },
    );
  }
}

/// Resets chrome visibility when the shell route changes (tab switch).
mixin ShellChromeRouteMixin<T extends StatefulWidget> on State<T> {
  ShellChromeController get shellChromeController;

  String? _lastShellPath;

  void syncShellChromeRoute(String path) {
    if (_lastShellPath == path) return;
    _lastShellPath = path;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) shellChromeController.reset();
    });
  }
}
