import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';

/// Wraps a widget with Payspin localizations for widget tests (defaults to en).
Widget l10nTestApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? PayspinTheme.light(),
    locale: const Locale('en'),
    supportedLocales: LocaleController.supportedLocales,
    localizationsDelegates: const [
      PayspinLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}
