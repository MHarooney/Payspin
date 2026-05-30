import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

abstract final class PayspinTheme {
  static ThemeData dark() {
    final inter = GoogleFonts.interTextTheme();
    final raleway = GoogleFonts.ralewayTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PayspinTokens.bg,
      colorScheme: const ColorScheme.dark(
        primary: PayspinTokens.pink,
        secondary: PayspinTokens.mint,
        surface: PayspinTokens.bgElevated,
        error: PayspinTokens.error,
        onPrimary: Colors.white,
        onSurface: PayspinTokens.textPrimary,
      ),
      textTheme: raleway.copyWith(
        bodyMedium: inter.bodyMedium?.copyWith(color: PayspinTokens.textBody),
        bodySmall: inter.bodySmall?.copyWith(color: PayspinTokens.textMuted),
        labelLarge: inter.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: PayspinTokens.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PayspinTokens.bg,
        foregroundColor: PayspinTokens.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: PayspinTokens.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PayspinTokens.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
          borderSide: const BorderSide(color: PayspinTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
          borderSide: const BorderSide(color: PayspinTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
          borderSide: const BorderSide(color: PayspinTokens.borderActive),
        ),
        hintStyle: GoogleFonts.inter(color: PayspinTokens.textHint),
        labelStyle: GoogleFonts.inter(color: PayspinTokens.textMuted, fontSize: 12),
      ),
    );
  }
}
