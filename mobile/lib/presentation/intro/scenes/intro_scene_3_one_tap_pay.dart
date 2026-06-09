import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_glass_surface.dart';
import '../intro_mini_confetti.dart';
import '../intro_narrative.dart';
import '../intro_scene_lifecycle.dart';

/// Scene 3 — phone pay link; one tap → success + mini confetti.
class IntroScene3 extends StatefulWidget {
  const IntroScene3({super.key, this.sceneIndex = 2});

  final int sceneIndex;

  @override
  State<IntroScene3> createState() => _IntroScene3State();
}

class _IntroScene3State extends State<IntroScene3>
    with SingleTickerProviderStateMixin, IntroSceneLifecycle {
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
      return const _Phone(t: 0.55);
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
    final tap = ((t - 0.4) / 0.1).clamp(0.0, 1.0);
    final paid = ((t - 0.5) / 0.2).clamp(0.0, 1.0);
    final pressed = tap > 0 && tap < 1;
    final confetti = paid > 0.3 ? ((paid - 0.3) / 0.7).clamp(0.0, 1.0) : 0.0;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 188,
          height: 248,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (confetti > 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: IntroMiniConfetti(progress: confetti),
                ),
              PayspinGlassSurface(
                tier: PayspinGlassTier.raised,
                glow: true,
                gradientBorder: true,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.glassBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      IntroNarrative.demoAmount,
                      style: GoogleFonts.raleway(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${IntroNarrative.demoLabel} • ${IntroNarrative.demoVia}',
                      style: GoogleFonts.inter(
                        color: colors.textMuted,
                        fontSize: 11,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (paid < 0.5)
                      Transform.scale(
                        scale: pressed ? 0.94 : 1.0,
                        child: Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: PayspinTokens.gradientPink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Pay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      _success(paid),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _success(double p) {
    final scale = Curves.easeOutBack.transform(p.clamp(0.0, 1.0));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: PayspinTokens.gradientPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: p,
          child: const Text(
            'Paid',
            style: TextStyle(color: PayspinTokens.green, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
