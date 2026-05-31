import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/config/remote_config_service.dart';
import 'core/design_system/tokens/payspin_tokens.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/phone_auth_service.dart';
import 'core/network/api_config.dart';
import 'core/notifications/push_service.dart';

/// Shared app startup for [main] and [main_driver].
Future<void> bootstrap({bool enableDriver = false}) async {
  if (enableDriver) {
    enableFlutterDriverExtension();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  // Refuse to start a release build pointed at a local dev API.
  ApiConfig.assertValidForRelease();
  await configureDependencies();

  // Firebase is best-effort: when un-provisioned these all no-op so the app
  // still boots. Push token registration + phone sync run only with a session.
  await FirebaseBootstrap.ensureInitialized();
  await sl<RemoteConfigService>().init();
  await sl<PushService>().init();
  await sl<PhoneAuthService>().syncVerifiedPhone();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: PayspinTokens.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(PayspinApp());
}
