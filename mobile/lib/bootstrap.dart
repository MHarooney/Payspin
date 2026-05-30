import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/design_system/tokens/payspin_tokens.dart';
import 'core/network/api_config.dart';

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
