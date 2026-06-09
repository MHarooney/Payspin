import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/motion/payspin_motion_scope.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_brand_mark.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/design_system/widgets/payspin_staggered_entrance.dart';

/// Welcome / marketing screen — animated brand mark matches splash motion.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.psColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isDark = !isLight;

    return Scaffold(
      backgroundColor: colors.bg,
      body: PayspinAmbientBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: PayspinFinanceParticles(intensity: isLight ? 1.0 : 0.7),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: const PayspinQuickSettings(),
                ),
              ),
            ),
            Center(
              child: PayspinParallax(
                dx: 18,
                dy: 12,
                child: PayspinBrandMark.hero(
                  tagline: l10n.tagline,
                  emblemStyle: isDark ? PayspinEmblemStyle.gradient : null,
                  glowAnimate: true,
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PayspinStaggeredEntrance(
                        index: 0,
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
                      const SizedBox(height: 14),
                      PayspinStaggeredEntrance(
                        index: 1,
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text.rich(
                            TextSpan(
                              style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
                              children: [
                                TextSpan(text: '${l10n.alreadyHaveAccount} '),
                                TextSpan(
                                  text: l10n.logIn,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
