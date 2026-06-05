import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/config/remote_config_service.dart';
import 'core/design_system/theme/payspin_semantic_colors.dart';
import 'core/design_system/theme/theme_mode_controller.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/phone_auth_service.dart';
import 'core/network/api_config.dart';
import 'core/notifications/push_service.dart';
import 'core/security/app_lock_controller.dart';

/// Shared app startup for [main]. Use [main_driver.dart] for Flutter Driver / MCP.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Payspin: bootstrap start');

  ApiConfig.assertValidForRelease();
  await configureDependencies();

  // Engage the lock before the first frame so secured content never flashes.
  final appLock = sl<AppLockController>()..attach();
  try {
    await appLock.evaluateStartupLock().timeout(const Duration(seconds: 3));
  } on TimeoutException {
    debugPrint('Payspin: startup lock check timed out — continuing unlocked');
    appLock.markDisabled();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  final mode = sl<ThemeModeController>().mode;
  final platformIsDark =
      WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  final isDark = switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => platformIsDark,
  };
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? PayspinSemanticColors.dark.bg : PayspinSemanticColors.light.bg,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ),
  );

  debugPrint('Payspin: runApp');
  runApp(PayspinApp());

  // Firebase + push after first frame so a slow network/keychain never blocks UI.
  unawaited(_deferredStartup());
}

Future<void> _deferredStartup() async {
  try {
    await FirebaseBootstrap.ensureInitialized().timeout(const Duration(seconds: 8));
    await sl<RemoteConfigService>().init();
    await sl<PushService>().init();
    await sl<PhoneAuthService>().syncVerifiedPhone();
    debugPrint('Payspin: deferred startup done');
  } on TimeoutException {
    debugPrint('Payspin: deferred startup timed out');
  } catch (e, st) {
    debugPrint('Payspin: deferred startup failed: $e\n$st');
  }
}
