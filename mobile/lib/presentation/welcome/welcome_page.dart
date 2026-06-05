import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_logo.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';

/// Welcome / marketing screen — static layout (no intro fade) so the first
/// frame is always visible on the dark background.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.psColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PayspinRadialGlow(size: 420, animate: false)),
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
                  const PayspinLogo(size: 110),
                  const SizedBox(height: 28),
                  const PayspinGradientText(
                    'Payspin',
                    solidWordmark: true,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: context.psColors.textBody,
                        ),
                  ),
                  const Spacer(flex: 3),
                  PayspinGradientPillButton(
                    key: const Key('welcome_get_started'),
                    label: l10n.getStarted,
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
    );
  }
}
