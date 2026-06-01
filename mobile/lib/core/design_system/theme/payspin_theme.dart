import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/payspin_tokens.dart';

/// Global Material theme — dark prototype (`screens.jsx` / `PS` tokens).
/// Uses system fonts at build time so the first frame is not blocked on font CDN.
abstract final class PayspinTheme {
  static ThemeData dark() {
    const base = TextStyle(fontFamily: '.AppleSystemUIFont');
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PayspinTokens.bg,
      colorScheme: const ColorScheme.dark(
        primary: PayspinTokens.pink,
        secondary: PayspinTokens.mint,
        surface: PayspinTokens.bgElevated,
        error: PayspinTokens.error,
        onPrimary: PayspinTokens.onBrand,
        onSurface: PayspinTokens.textPrimary,
      ),
      iconTheme: const IconThemeData(color: PayspinTokens.textPrimary),
      dividerColor: PayspinTokens.border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: PayspinTokens.pink),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: PayspinTokens.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displayLarge: base,
        displayMedium: base,
        displaySmall: base,
        headlineLarge: base,
        headlineMedium: base,
        headlineSmall: base,
        titleLarge: TextStyle(fontFamily: '.AppleSystemUIFont', fontWeight: FontWeight.w700, color: PayspinTokens.textPrimary),
        titleMedium: TextStyle(fontFamily: '.AppleSystemUIFont', fontWeight: FontWeight.w600, color: PayspinTokens.textPrimary),
        bodyLarge: TextStyle(fontFamily: '.AppleSystemUIFont', color: PayspinTokens.textBody),
        bodyMedium: TextStyle(fontFamily: '.AppleSystemUIFont', color: PayspinTokens.textBody),
        bodySmall: TextStyle(fontFamily: '.AppleSystemUIFont', color: PayspinTokens.textMuted),
        labelLarge: TextStyle(fontFamily: '.AppleSystemUIFont', fontWeight: FontWeight.w600, color: PayspinTokens.textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PayspinTokens.bg,
        foregroundColor: PayspinTokens.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: '.AppleSystemUIFont',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: PayspinTokens.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        filled: true,
        fillColor: PayspinTokens.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(PayspinTokens.radiusInput)),
          borderSide: BorderSide(color: PayspinTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(PayspinTokens.radiusInput)),
          borderSide: BorderSide(color: PayspinTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(PayspinTokens.radiusInput)),
          borderSide: BorderSide(color: PayspinTokens.borderActive),
        ),
        hintStyle: TextStyle(color: PayspinTokens.textHint),
        labelStyle: TextStyle(color: PayspinTokens.textMuted, fontSize: 12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: PayspinTokens.mint),
      ),
    );
  }
}
