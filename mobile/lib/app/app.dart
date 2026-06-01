import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/theme/payspin_theme.dart';
import '../core/security/app_lock_controller.dart';
import '../core/security/app_lock_service.dart';
import '../presentation/security/lock_screen.dart';
import 'di/injection.dart';
import 'router.dart';

class PayspinApp extends StatelessWidget {
  PayspinApp({super.key, GoRouter? router}) : router = router ?? createRouter();

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Payspin',
      theme: PayspinTheme.dark(),
      darkTheme: PayspinTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) =>
          _AppLockGate(router: router, child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Paints the [LockScreen] above all app content whenever the lock is engaged.
/// Lives above the router so it covers every route, including deep links.
class _AppLockGate extends StatefulWidget {
  const _AppLockGate({required this.child, required this.router});

  final Widget child;
  final GoRouter router;

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate> {
  final AppLockController _controller = sl<AppLockController>();
  final AppLockService _service = sl<AppLockService>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _forgot() async {
    // No way to recover the passcode locally: sign out and clear the lock so
    // the user re-authenticates from /welcome.
    await _service.disableLock();
    _controller.markDisabled();
    widget.router.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isLocked)
          LockScreen(
            service: _service,
            onUnlocked: _controller.unlock,
            onForgot: _forgot,
          ),
      ],
    );
  }
}
