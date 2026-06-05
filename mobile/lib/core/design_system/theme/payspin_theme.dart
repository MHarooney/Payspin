import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/payspin_tokens.dart';
import 'payspin_semantic_colors.dart';

/// Global Material theme — dark prototype (`screens.jsx` / `PS` tokens) plus a
/// light variant. Both register [PayspinSemanticColors] so screens can read
/// `context.psColors` and adapt to the active [ThemeMode].
///
/// Uses system fonts at build time so the first frame is not blocked on font CDN.
abstract final class PayspinTheme {
  static ThemeData dark() => _build(Brightness.dark, PayspinSemanticColors.dark);

  static ThemeData light() => _build(Brightness.light, PayspinSemanticColors.light);

  static ThemeData _build(Brightness brightness, PayspinSemanticColors colors) {
    const fontFamily = '.AppleSystemUIFont';
    final isDark = brightness == Brightness.dark;
    final body = TextStyle(fontFamily: fontFamily, color: colors.textBody);
    final headline = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w800,
      color: colors.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: PayspinTokens.pink,
        onPrimary: PayspinTokens.onBrand,
        secondary: PayspinTokens.mint,
        onSecondary: PayspinTokens.onBrand,
        error: PayspinTokens.error,
        onError: PayspinTokens.onBrand,
        surface: colors.bgElevated,
        onSurface: colors.textPrimary,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      dividerColor: colors.border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: PayspinTokens.pink),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.bgElevated,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        displayLarge: headline,
        displayMedium: headline,
        displaySmall: headline,
        headlineLarge: headline,
        headlineMedium: headline.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: headline.copyWith(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, color: colors.textPrimary),
        titleMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: colors.textPrimary),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: colors.textBody),
        bodyMedium: TextStyle(fontFamily: fontFamily, color: colors.textBody),
        bodySmall: TextStyle(fontFamily: fontFamily, color: colors.textMuted),
        labelLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: colors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.glassFill,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(PayspinTokens.radiusInput)),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(PayspinTokens.radiusInput)),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(PayspinTokens.radiusInput)),
          borderSide: BorderSide(color: colors.borderActive),
        ),
        hintStyle: TextStyle(color: colors.textHint),
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: PayspinTokens.mint),
      ),
    );
  }
}
