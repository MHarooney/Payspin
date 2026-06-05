import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';

enum PayspinLogoVariant { mark, wordmark }

/// Official Payspin emblem — static bitmap for QR and legacy surfaces.
///
/// Prefer [PayspinBrandMark] on branded screens (welcome, login, splash) for the
/// animated vector emblem that matches splash motion.
class PayspinLogo extends StatelessWidget {
  const PayspinLogo({
    super.key,
    this.variant = PayspinLogoVariant.mark,
    this.style = PayspinEmblemStyle.auto,
    this.size = 48,
    this.glow = false,
  });

  final PayspinLogoVariant variant;
  final PayspinEmblemStyle style;
  final double size;
  final bool glow;

  static const _emblemWhite = 'assets/images/payspin_emblem_white.png';
  static const _emblemGradient = 'assets/images/payspin_emblem_gradient.png';
  static const _legacyWordmark = 'assets/images/payspin_ic_white.png';

  String _resolveAsset(BuildContext context) {
    if (variant == PayspinLogoVariant.wordmark) {
      return _legacyWordmark;
    }
    final resolved = switch (style) {
      PayspinEmblemStyle.white => PayspinEmblemStyle.white,
      PayspinEmblemStyle.gradient => PayspinEmblemStyle.gradient,
      PayspinEmblemStyle.auto => context.psColors.emblemStyle,
    };
    return switch (resolved) {
      PayspinEmblemStyle.white => _emblemWhite,
      PayspinEmblemStyle.gradient => _emblemGradient,
      PayspinEmblemStyle.auto => _emblemWhite,
    };
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _resolveAsset(context),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!glow) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.psColors.pageGlowPink,
            blurRadius: size * 0.35,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: image,
    );
  }

  /// Gradient emblem on circular safe plate for QR centre (~28% of QR side).
  static const String qrCenterAsset = 'assets/images/payspin_emblem_qr_center.png';
}
