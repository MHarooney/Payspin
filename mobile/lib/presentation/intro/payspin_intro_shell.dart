import 'package:flutter/material.dart';

import '../../core/design_system/motion/payspin_motion_scope.dart';
import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';

/// Scene-indexed aurora blooms for the intro carousel.
class PayspinIntroBackdrop extends StatelessWidget {
  const PayspinIntroBackdrop({
    super.key,
    required this.sceneIndex,
    required this.child,
  });

  final int sceneIndex;
  final Widget child;

  static Color _tintFor(int i) => switch (i) {
        0 => PayspinTokens.pink,
        1 => PayspinTokens.mint,
        2 => PayspinTokens.mint,
        3 => PayspinTokens.blue,
        _ => PayspinTokens.mustard,
      };

  @override
  Widget build(BuildContext context) {
    final tint = _tintFor(sceneIndex);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return PayspinAmbientBackground(
      intensity: 0.85,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            top: sceneIndex.isEven ? -120 : -80,
            left: sceneIndex < 3 ? -100 : -60,
            child: _bloom(tint.withValues(alpha: 0.22), 360),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            bottom: sceneIndex.isEven ? -140 : -100,
            right: sceneIndex < 3 ? -80 : -120,
            child: _bloom(PayspinTokens.mint.withValues(alpha: 0.16), 400),
          ),
          Positioned.fill(
            child: PayspinRadialGlow(
              size: 420,
              animate: !PayspinMotion.reduced(context),
              centered: true,
            ),
          ),
          Positioned.fill(
            child: PayspinParallax(
              dx: 14,
              dy: 10,
              child: PayspinFinanceParticles(intensity: isLight ? 0.75 : 0.55),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _bloom(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
