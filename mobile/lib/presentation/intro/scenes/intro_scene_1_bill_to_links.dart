import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_emblem_vector.dart';

/// Scene 1 — a paper bill is stamped PAID, then turns into payment-link cards
/// that fly upward while the emblem draws in the centre.
class IntroScene1 extends StatefulWidget {
  const IntroScene1({super.key});

  @override
  State<IntroScene1> createState() => _IntroScene1State();
}

class _IntroScene1State extends State<IntroScene1>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
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
      return const _Scene1Frame(t: 0.6);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => _Scene1Frame(t: _c.value),
    );
  }
}

class _Scene1Frame extends StatelessWidget {
  const _Scene1Frame({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    // Stamp lands in the first third, then link chips lift off.
    final stamp = Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
    final lift = Curves.easeInOut.transform(((t - 0.3) / 0.55).clamp(0.0, 1.0));
    final emblem = ((t - 0.45) / 0.5).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 260,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Bill card.
            Transform.scale(
              scale: 1 - lift * 0.12,
              child: Opacity(
                opacity: (1 - lift * 0.5).clamp(0.0, 1.0),
                child: _bill(colors),
              ),
            ),
            // Flying link chips.
            for (var i = 0; i < 3; i++) _chip(colors, i, lift),
            // PAID stamp.
            Transform.rotate(
              angle: -0.28,
              child: Transform.scale(
                scale: stamp * (1 - lift * 0.4),
                child: Opacity(
                  opacity: (stamp * (1 - lift)).clamp(0.0, 1.0),
                  child: _paid(),
                ),
              ),
            ),
            // Emblem draws in at the end.
            Opacity(
              opacity: emblem,
              child: PayspinEmblemVector(
                size: 84,
                progress: emblem,
                style: PayspinEmblemStyle.gradient,
                glow: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bill(PayspinSemanticColors colors) {
    return Container(
      width: 180,
      height: 230,
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.glassBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(colors, 0.6, 12),
          const SizedBox(height: 16),
          for (var i = 0; i < 4; i++) ...[
            _line(colors, 0.9, 8),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          _line(colors, 0.45, 16),
        ],
      ),
    );
  }

  Widget _line(PayspinSemanticColors colors, double widthFactor, double height) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _chip(PayspinSemanticColors colors, int i, double lift) {
    final angle = (i - 1) * 0.5;
    final dx = math.sin(angle) * 90 * lift;
    final dy = -150 * lift - i * 14.0;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: (lift * 1.4 - i * 0.2).clamp(0.0, 1.0) * (1 - lift * 0.3),
        child: Transform.rotate(
          angle: angle * 0.4,
          child: Container(
            width: 120,
            height: 40,
            decoration: BoxDecoration(
              gradient: PayspinTokens.gradientPink,
              borderRadius: BorderRadius.circular(12),
              boxShadow: PayspinTokens.fabShadow,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: PayspinTokens.green, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'PAID',
        style: TextStyle(
          color: PayspinTokens.green,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
