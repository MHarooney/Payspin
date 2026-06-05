import 'package:flutter/material.dart';

import 'payspin_motion.dart';
import 'payspin_semantic_colors.dart';
import 'payspin_theme.dart';
/// Smooth cross-fade when [ThemeMode] changes — animates Material theme data
/// and semantic color extensions so every screen using [context.psColors] lerps.
class PayspinThemeTransition extends StatelessWidget {
  const PayspinThemeTransition({
    super.key,
    required this.themeMode,
    required this.child,
  });

  final ThemeMode themeMode;
  final Widget child;

  ThemeData _resolve(BuildContext context) {
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return switch (themeMode) {
      ThemeMode.light => PayspinTheme.light(),
      ThemeMode.dark => PayspinTheme.dark(),
      ThemeMode.system => platformDark ? PayspinTheme.dark() : PayspinTheme.light(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      duration: PayspinMotion.medium,
      curve: PayspinMotion.easeEnter,
      data: _resolve(context),
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).extension<PayspinSemanticColors>();
          if (colors == null) return child;
          return ColoredBox(
            color: colors.bg,
            child: AnimatedContainer(
              duration: PayspinMotion.medium,
              curve: PayspinMotion.easeEnter,
              color: colors.bg,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
