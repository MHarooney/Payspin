import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_logo.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.12,
            left: MediaQuery.sizeOf(context).width * 0.5 - 200,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PayspinTokens.pink.withValues(alpha: 0.25),
                    PayspinTokens.mint.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.7],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                const PayspinLogo(size: 110),
                const SizedBox(height: 28),
                const PayspinGradientText('Payspin', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Send and request money.\nYour money, your community, your peace of mind.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, color: PayspinTokens.textBody, height: 1.55),
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PayspinGradientPillButton(
                    label: 'Get started',
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    onPressed: () => context.go('/onboarding/name'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(text: 'Log in', style: TextStyle(color: PayspinTokens.mint, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
