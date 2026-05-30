import 'package:flutter/material.dart';

/// Design tokens — mirrors `PS` in screens.jsx + colors_and_type.css.
abstract final class PayspinTokens {
  static const Color bg = Color(0xFF0B0B12);
  static const Color bgElevated = Color(0xFF15141F);
  static const Color glass = Color(0x0FFFFFFF);
  static const Color border = Color(0x14FFFFFF);
  static const Color borderActive = Color(0x73FC00FF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xD9FFFFFF);
  static const Color textMuted = Color(0x8CFFFFFF);
  static const Color textHint = Color(0x59FFFFFF);

  static const Color mint = Color(0xFF07D8DD);
  static const Color pink = Color(0xFFFC00FF);
  static const Color purple = Color(0xFF8E0FF2);
  static const Color blue = Color(0xFF5C7AEA);
  static const Color mustard = Color(0xFFFFC408);
  static const Color error = Color(0xFFFC00FF);

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double radiusInput = 10;
  static const double radiusCard = 16;
  static const double radiusPill = 100;
  static const double btnHeightLg = 56;

  static const LinearGradient gradientPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, mint],
  );

  static const LinearGradient gradientTri = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint, blue, pink],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFFD94DF8), Color(0xFF6B96EA), Color(0xFF48ADE5), mint],
  );

  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: pink.withValues(alpha: 0.32),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: mint.withValues(alpha: 0.18),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
