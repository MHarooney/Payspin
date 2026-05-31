import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../../core/design_system/widgets/payspin_radial_glow.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  final List<_Confetti> _confetti = List.generate(28, (i) {
    final rnd = math.Random(i * 7 + 3);
    return _Confetti(
      x: rnd.nextDouble(),
      delay: rnd.nextDouble() * 0.3,
      size: 5 + rnd.nextDouble() * 5,
      rotation: rnd.nextDouble() * math.pi,
      color: [PayspinTokens.mint, PayspinTokens.pink, PayspinTokens.mustard, PayspinTokens.blue][i % 4],
    );
  });

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final badge = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.8, curve: Curves.easeOut));

    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PayspinRadialGlow(size: 420)),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                children: [
                  for (final p in _confetti)
                    Positioned(
                      left: p.x * size.width,
                      top: _confettiTop(p, size.height),
                      child: Transform.rotate(
                        angle: p.rotation + _c.value * 6,
                        child: Opacity(
                          opacity: (1 - _c.value).clamp(0.0, 1.0),
                          child: Container(
                            width: p.size,
                            height: p.size * 0.6,
                            decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: badge,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: PayspinTokens.gradientPink,
                      boxShadow: PayspinTokens.fabShadow,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: text,
                  child: Column(
                    children: [
                      Text('Nice!', style: GoogleFonts.raleway(fontSize: 56, fontWeight: FontWeight.w900, color: PayspinTokens.textPrimary)),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'You can now use ', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w700, color: PayspinTokens.textBody)),
                            const WidgetSpan(child: PayspinGradientText('Payspin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: PayspinGradientPillButton(
                    label: 'Go to Home',
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go('/home');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _confettiTop(_Confetti p, double height) {
    final t = ((_c.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
    return -20 + t * height * 0.7;
  }
}

class _Confetti {
  const _Confetti({
    required this.x,
    required this.delay,
    required this.size,
    required this.rotation,
    required this.color,
  });

  final double x;
  final double delay;
  final double size;
  final double rotation;
  final Color color;
}
