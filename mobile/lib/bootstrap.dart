import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/design_system/tokens/payspin_tokens.dart';

/// Shared app startup for [main] and [main_driver].
Future<void> bootstrap({bool enableDriver = false}) async {
  if (enableDriver) {
    enableFlutterDriverExtension();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
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
