import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_logo.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Fade + slide a child in over an interval of the intro timeline.
  Widget _staggered(double start, double end, Widget child) {
    final anim = CurvedAnimation(parent: _intro, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PayspinRadialGlow(size: 420)),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _staggered(0.0, 0.45, const PayspinLogo(size: 110)),
                const SizedBox(height: 28),
                _staggered(0.15, 0.6, const PayspinGradientText('Payspin', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900))),
                const SizedBox(height: 14),
                _staggered(
                  0.3,
                  0.75,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Send and request money.\nYour money, your community, your peace of mind.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 15, color: PayspinTokens.textBody, height: 1.55),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                _staggered(
                  0.5,
                  1.0,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PayspinGradientPillButton(
                      label: 'Get started',
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go('/onboarding/name');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _staggered(
                  0.6,
                  1.0,
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          const TextSpan(text: 'Log in', style: TextStyle(color: PayspinTokens.mint, fontWeight: FontWeight.w600)),
                        ],
                      ),
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
