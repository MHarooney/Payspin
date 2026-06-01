import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/config/remote_config_service.dart';
import 'core/design_system/tokens/payspin_tokens.dart';
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
  await appLock.evaluateStartupLock();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: PayspinTokens.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  debugPrint('Payspin: runApp');
  runApp(PayspinApp());

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
