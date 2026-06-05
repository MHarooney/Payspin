import 'package:flutter/material.dart';

/// Which official Payspin emblem asset to render.
enum PayspinEmblemStyle { auto, white, gradient }

/// Semantic colors for light and dark themes — use via [Theme.of(context).extension].
///
/// Prefer these over raw [PayspinTokens] in UI code so screens adapt to theme mode.
@immutable
class PayspinSemanticColors extends ThemeExtension<PayspinSemanticColors> {
  const PayspinSemanticColors({
    required this.bg,
    required this.bgElevated,
    required this.surfaceRaised,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassShadow,
    required this.border,
    required this.borderActive,
    required this.textPrimary,
    required this.textBody,
    required this.textMuted,
    required this.textHint,
    required this.navBarScrim,
    required this.pageGlowPink,
    required this.pageGlowMint,
    required this.emblemStyle,
  });

  final Color bg;
  final Color bgElevated;
  final Color surfaceRaised;

  /// Base translucent fill for `glass.raised` / `glass.flat` tiers.
  final Color glassFill;

  /// Denser fill for `glass.overlay` surfaces (sheets, nav bar, dialogs) where
  /// content must stay legible over busy backdrops.
  final Color glassFillStrong;

  final Color glassBorder;

  /// Top-edge inner reflection that sells real glass (brighter at the top).
  final Color glassHighlight;

  /// Soft drop shadow under glass panels — deep + neutral in dark, soft +
  /// slightly cool in light.
  final Color glassShadow;

  final Color border;
  final Color borderActive;
  final Color textPrimary;
  final Color textBody;
  final Color textMuted;
  final Color textHint;
  final Color navBarScrim;
  final Color pageGlowPink;
  final Color pageGlowMint;
  final PayspinEmblemStyle emblemStyle;

  static const PayspinSemanticColors dark = PayspinSemanticColors(
    bg: Color(0xFF0B0B12),
    bgElevated: Color(0xFF15141F),
    surfaceRaised: Color(0x0AFFFFFF),
    glassFill: Color(0x0FFFFFFF),
    glassFillStrong: Color(0xB815141F),
    glassBorder: Color(0x24FFFFFF),
    glassHighlight: Color(0x3DFFFFFF),
    glassShadow: Color(0x66050509),
    border: Color(0x14FFFFFF),
    borderActive: Color(0x73FC00FF),
    textPrimary: Color(0xFFFFFFFF),
    textBody: Color(0xFFF5F5F7),
    textMuted: Color(0xB8FFFFFF),
    textHint: Color(0x80FFFFFF),
    navBarScrim: Color(0xD90B0B12),
    pageGlowPink: Color(0x29FC00FF),
    pageGlowMint: Color(0x1F07D8DD),
    emblemStyle: PayspinEmblemStyle.white,
  );

  static const PayspinSemanticColors light = PayspinSemanticColors(
    bg: Color(0xFFF9F9F9),
    bgElevated: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF5F5F5),
    glassFill: Color(0x80FFFFFF),
    glassFillStrong: Color(0xCCFFFFFF),
    glassBorder: Color(0x660A0D13),
    glassHighlight: Color(0xB3FFFFFF),
    glassShadow: Color(0x1F2A2440),
    border: Color(0x140A0D13),
    borderActive: Color(0xCCFC00FF),
    textPrimary: Color(0xFF0A0D13),
    textBody: Color(0xDE0A0D13),
    textMuted: Color(0x996C7278),
    textHint: Color(0x736C7278),
    navBarScrim: Color(0xE6FFFFFF),
    pageGlowPink: Color(0x1FFC00FF),
    pageGlowMint: Color(0x1407D8DD),
    emblemStyle: PayspinEmblemStyle.gradient,
  );

  @override
  PayspinSemanticColors copyWith({
    Color? bg,
    Color? bgElevated,
    Color? surfaceRaised,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassHighlight,
    Color? glassShadow,
    Color? border,
    Color? borderActive,
    Color? textPrimary,
    Color? textBody,
    Color? textMuted,
    Color? textHint,
    Color? navBarScrim,
    Color? pageGlowPink,
    Color? pageGlowMint,
    PayspinEmblemStyle? emblemStyle,
  }) {
    return PayspinSemanticColors(
      bg: bg ?? this.bg,
      bgElevated: bgElevated ?? this.bgElevated,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassShadow: glassShadow ?? this.glassShadow,
      border: border ?? this.border,
      borderActive: borderActive ?? this.borderActive,
      textPrimary: textPrimary ?? this.textPrimary,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      navBarScrim: navBarScrim ?? this.navBarScrim,
      pageGlowPink: pageGlowPink ?? this.pageGlowPink,
      pageGlowMint: pageGlowMint ?? this.pageGlowMint,
      emblemStyle: emblemStyle ?? this.emblemStyle,
    );
  }

  @override
  PayspinSemanticColors lerp(PayspinSemanticColors? other, double t) {
    if (other == null) return this;
    return PayspinSemanticColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      navBarScrim: Color.lerp(navBarScrim, other.navBarScrim, t)!,
      pageGlowPink: Color.lerp(pageGlowPink, other.pageGlowPink, t)!,
      pageGlowMint: Color.lerp(pageGlowMint, other.pageGlowMint, t)!,
      emblemStyle: t < 0.5 ? emblemStyle : other.emblemStyle,
    );
  }
}

extension PayspinSemanticColorsX on BuildContext {
  PayspinSemanticColors get psColors {
    final ext = Theme.of(this).extension<PayspinSemanticColors>();
    if (ext != null) return ext;
    return Theme.of(this).brightness == Brightness.dark
        ? PayspinSemanticColors.dark
        : PayspinSemanticColors.light;
  }
}
