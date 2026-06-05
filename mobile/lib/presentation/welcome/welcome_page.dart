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
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';

/// Welcome / marketing screen — animated brand mark matches splash motion.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: context.psColors.bg,
      body: PayspinAmbientBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: PayspinRadialGlow(size: 420, animate: false)),
            Positioned.fill(
              child: PayspinFinanceParticles(intensity: isLight ? 1.0 : 0.7),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: PayspinQuickSettings(),
                      ),
                    ),
                    const Spacer(flex: 2),
                    PayspinParallax(
                      dx: 18,
                      dy: 12,
                      child: PayspinBrandMark.hero(tagline: l10n.tagline),
                    ),
                    const Spacer(flex: 3),
                    PayspinGradientPillButton(
                      key: const Key('welcome_get_started'),
                      label: l10n.getStarted,
                      shimmer: true,
                      icon: const Icon(Icons.arrow_forward, color: PayspinTokens.onBrand, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go('/onboarding/name');
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
                          children: [
                            TextSpan(text: l10n.alreadyHaveAccount),
                            TextSpan(
                              text: l10n.logIn,
                              style: const TextStyle(color: PayspinTokens.mint, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
