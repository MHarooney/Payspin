import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/motion/payspin_motion_scope.dart';
import '../core/design_system/theme/payspin_system_chrome.dart';
import '../core/design_system/theme/payspin_theme.dart';
import '../core/design_system/theme/payspin_theme_transition.dart';
import '../core/design_system/theme/theme_mode_controller.dart';
import '../core/l10n/locale_controller.dart';
import '../core/l10n/payspin_localizations.dart';
import '../core/security/app_lock_controller.dart';
import '../core/security/app_lock_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../presentation/security/lock_screen.dart';
import 'di/injection.dart';
import 'router.dart';

class PayspinApp extends StatelessWidget {
  PayspinApp({super.key, GoRouter? router}) : router = router ?? createRouter();

  final GoRouter router;
  final ThemeModeController _themeController = sl<ThemeModeController>();
  final LocaleController _localeController = sl<LocaleController>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_themeController, _localeController]),
      builder: (context, _) => MaterialApp.router(
        title: 'Payspin',
        theme: PayspinTheme.light(),
        darkTheme: PayspinTheme.dark(),
        themeMode: _themeController.mode,
        locale: _localeController.locale,
        supportedLocales: LocaleController.supportedLocales,
        localizationsDelegates: const [
          PayspinLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (context, child) => PayspinMotionScope(
          child: PayspinThemeTransition(
            themeMode: _themeController.mode,
            child: PayspinSystemChrome(
              themeMode: _themeController.mode,
              child: _AppLockGate(
                router: router,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
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

  Future<void> _onPasscodeReset() async {
    await _service.disableLock();
    _controller.markDisabled();
    final name = await _service.displayName();
    if (!mounted) return;
    widget.router.go('/security/setup', extra: name);
  }

  Future<void> _onSignOutFallback() async {
    await _service.disableLock();
    _controller.markDisabled();
    await sl<AuthRepository>().signOut();
    if (!mounted) return;
    widget.router.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _controller.recordUserActivity(),
      child: Stack(
        children: [
          widget.child,
          if (_controller.isLocked)
            // Dedicated navigator so forgot-passcode modals paint above the lock
            // overlay instead of behind it on the GoRouter navigator.
            Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => LockScreen(
                  service: _service,
                  onUnlocked: _controller.unlock,
                  onPasscodeReset: _onPasscodeReset,
                  onSignOutFallback: _onSignOutFallback,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
