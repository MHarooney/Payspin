import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_emblem_vector.dart';
import '../../../core/design_system/widgets/payspin_glass_surface.dart';
import '../intro_narrative.dart';
import '../intro_scene_lifecycle.dart';

/// Scene 1 — bill stamped PAID → payment-link chips fly up + emblem draw.
class IntroScene1 extends StatefulWidget {
  const IntroScene1({super.key, this.sceneIndex = 0});

  final int sceneIndex;

  @override
  State<IntroScene1> createState() => _IntroScene1State();
}

class _IntroScene1State extends State<IntroScene1>
    with SingleTickerProviderStateMixin, IntroSceneLifecycle {
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
    bindIntroLoop(controller: _c, sceneIndex: widget.sceneIndex);
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
    final stamp = Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
    final lift = Curves.easeInOut.transform(((t - 0.3) / 0.55).clamp(0.0, 1.0));
    final emblem = ((t - 0.45) / 0.5).clamp(0.0, 1.0);
    final stampFlash = stamp > 0.85 && stamp < 1 && lift < 0.1;

    return Center(
      child: SizedBox(
        width: 260,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (stampFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: PayspinTokens.pink.withValues(alpha: 0.25), blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              ),
            Transform.scale(
              scale: 1 - lift * 0.12,
              child: Opacity(
                opacity: (1 - lift * 0.5).clamp(0.0, 1.0),
                child: _bill(colors),
              ),
            ),
            for (var i = 0; i < 3; i++) ...[
              _chipTrail(colors, i, lift),
              _chip(colors, i, lift),
            ],
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
            Opacity(
              opacity: emblem,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (emblem > 0.9)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PayspinTokens.mint.withValues(alpha: 0.2 * emblem),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  PayspinEmblemVector(
                    size: 84,
                    progress: emblem,
                    style: PayspinEmblemStyle.gradient,
                    glow: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bill(PayspinSemanticColors colors) {
    return PayspinGlassSurface(
      tier: PayspinGlassTier.raised,
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        width: 180,
        height: 194,
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

  Widget _chipTrail(PayspinSemanticColors colors, int i, double lift) {
    if (lift < 0.2) return const SizedBox.shrink();
    final angle = (i - 1) * 0.5;
    final trailLift = lift * 0.7;
    return Transform.translate(
      offset: Offset(math.sin(angle) * 90 * trailLift, -150 * trailLift - i * 14.0),
      child: Opacity(
        opacity: (0.25 * (1 - trailLift)).clamp(0.0, 0.25),
        child: _chipBody(i, 0.95),
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
        child: Transform.rotate(angle: angle * 0.4, child: _chipBody(i, 1)),
      ),
    );
  }

  Widget _chipBody(int i, double scale) {
    final label = i == 0 ? IntroNarrative.demoChipLabel : 'Link ${i + 1}';
    return Transform.scale(
      scale: scale,
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.flat,
        gradientBorder: true,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_rounded, color: PayspinTokens.mint, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: PayspinTokens.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
