import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_logo.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';

/// Welcome / marketing screen — static layout (no intro fade) so the first
/// frame is always visible on the dark background.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PayspinRadialGlow(size: 420, animate: false)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const PayspinLogo(size: 110),
                  const SizedBox(height: 28),
                  const PayspinGradientText(
                    'Payspin',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Send and request money.\nYour money, your community, your peace of mind.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: PayspinTokens.textBody,
                        ),
                  ),
                  const Spacer(flex: 3),
                  PayspinGradientPillButton(
                    key: const Key('welcome_get_started'),
                    label: 'Get started',
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
                        children: const [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Log in',
                            style: TextStyle(color: PayspinTokens.mint, fontWeight: FontWeight.w600),
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
