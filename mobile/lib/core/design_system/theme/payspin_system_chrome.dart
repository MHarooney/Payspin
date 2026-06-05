import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'payspin_semantic_colors.dart';

/// Keeps status bar and navigation bar colors in sync with [ThemeMode].
///
/// [bootstrap] sets an initial style; this widget updates whenever the user
/// changes appearance or the OS switches light/dark while in system mode.
class PayspinSystemChrome extends StatefulWidget {
  const PayspinSystemChrome({
    super.key,
    required this.themeMode,
    required this.child,
  });

  final ThemeMode themeMode;
  final Widget child;

  @override
  State<PayspinSystemChrome> createState() => _PayspinSystemChromeState();
}

class _PayspinSystemChromeState extends State<PayspinSystemChrome>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _apply();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apply();
  }

  @override
  void didUpdateWidget(PayspinSystemChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) _apply();
  }

  void _apply() {
    final platformIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = switch (widget.themeMode) {
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
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
