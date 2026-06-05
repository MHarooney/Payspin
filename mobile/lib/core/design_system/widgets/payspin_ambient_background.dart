import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';

/// Full-bleed page backdrop: base color + two soft brand blooms (pink top-left,
/// mint bottom-right). Gives glass surfaces a colored field to refract over in
/// both light and dark themes. Static (no animation) for scroll performance.
class PayspinAmbientBackground extends StatelessWidget {
  const PayspinAmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  final Widget child;

  /// Scales bloom opacity (0 = none, 1 = default).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bg),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _bloom(colors.pageGlowPink, 380, intensity),
          ),
          Positioned(
            bottom: -180,
            right: -140,
            child: _bloom(colors.pageGlowMint, 420, intensity),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _bloom(Color color, double size, double intensity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: (color.a) * intensity),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.75],
          ),
        ),
      ),
    );
  }
}
