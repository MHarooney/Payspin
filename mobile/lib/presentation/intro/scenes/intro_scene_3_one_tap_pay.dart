import 'package:flutter/material.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';

/// Scene 3 — a phone shows a Payspin pay link; a single tap flips it to a
/// success state.
class IntroScene3 extends StatefulWidget {
  const IntroScene3({super.key});

  @override
  State<IntroScene3> createState() => _IntroScene3State();
}

class _IntroScene3State extends State<IntroScene3>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PayspinMotion.reduced(context)) {
      return const _Phone(t: 0.75);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => _Phone(t: _c.value),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    // Tap happens at ~0.45, success holds afterwards.
    final tap = ((t - 0.4) / 0.1).clamp(0.0, 1.0);
    final paid = ((t - 0.5) / 0.2).clamp(0.0, 1.0);
    final pressed = tap > 0 && tap < 1;

    return Center(
      child: Container(
        width: 200,
        height: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: colors.glassBorder, width: 2),
          boxShadow: PayspinTokens.fabShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: colors.bg,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text('€24,50',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text('Dinner • via Payspin',
                    style: TextStyle(color: colors.textMuted, fontSize: 12)),
                const Spacer(),
                if (paid < 0.5)
                  Transform.scale(
                    scale: pressed ? 0.95 : 1.0,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: PayspinTokens.gradientPink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Pay',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ),
                  )
                else
                  _success(paid),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _success(double p) {
    final scale = Curves.easeOutBack.transform(p.clamp(0.0, 1.0));
    return Column(
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: PayspinTokens.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: p,
          child: const Text('Paid',
              style: TextStyle(
                  color: PayspinTokens.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ),
      ],
    );
  }
}
