import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/theme/payspin_theme.dart';
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
    );
  }
}
