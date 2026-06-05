import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';

/// Frosted glass panel — blur + translucent fill + hairline border.
///
/// Use for cards, icon buttons, and nav bars instead of flat [Color] fills.
class PayspinGlassSurface extends StatelessWidget {
  const PayspinGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.blur = 20,
    this.glow = false,
    this.border,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final bool glow;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final radius = BorderRadius.circular(borderRadius);

    Widget panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.glassFill,
            borderRadius: radius,
            border: border ?? Border.all(color: colors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );

    if (!glow) return panel;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(color: colors.pageGlowPink, blurRadius: 32, spreadRadius: -4),
                BoxShadow(color: colors.pageGlowMint, blurRadius: 24, spreadRadius: -8),
              ],
            ),
          ),
        ),
        panel,
      ],
    );
  }
}
