import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/motion/payspin_motion_scope.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_brand_mark.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';

/// Welcome / marketing screen — animated brand mark matches splash motion.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isDark = !isLight;
    return Scaffold(
      backgroundColor: context.psColors.bg,
      body: PayspinAmbientBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: PayspinFinanceParticles(intensity: isLight ? 1.0 : 0.7),
            ),
            Center(
              child: PayspinParallax(
                dx: 18,
                dy: 12,
                child: PayspinBrandMark.hero(
                  tagline: l10n.tagline,
                  emblemStyle: isDark ? PayspinEmblemStyle.gradient : null,
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: PayspinGradientPillButton(
                    key: const Key('welcome_get_started'),
                    label: l10n.getStarted,
                    shimmer: true,
                    icon: const Icon(Icons.arrow_forward, color: PayspinTokens.onBrand, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go('/onboarding/name');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
