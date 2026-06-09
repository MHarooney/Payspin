import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_morphing_sliver_header.dart';
import '../../../core/l10n/payspin_localizations.dart';
import '../intro_scene_lifecycle.dart';

/// Scene 4 — value constellation: orbiting words around a central gradient orb.
class IntroScene4 extends StatefulWidget {
  const IntroScene4({super.key, this.sceneIndex = 3});

  final int sceneIndex;

  @override
  State<IntroScene4> createState() => _IntroScene4State();
}

class _IntroScene4State extends State<IntroScene4>
    with SingleTickerProviderStateMixin, IntroSceneLifecycle {
  static const _icons = [
    Icons.touch_app_outlined,
    Icons.bolt_outlined,
    Icons.money_off_csred_outlined,
    Icons.public_outlined,
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
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
    final colors = context.psColors;
    final l10n = context.l10n;

    if (PayspinMotion.reduced(context)) {
      return _constellation(colors, l10n, 0, 1, 0);
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pos = _c.value * 4;
        final index = pos.floor() % 4;
        final frac = pos - pos.floor();
        return _constellation(colors, l10n, index, 1 - frac * 0.15, frac);
      },
    );
  }

  Widget _constellation(
    PayspinSemanticColors colors,
    PayspinLocalizations l10n,
    int activeIndex,
    double orbScale,
    double frac,
  ) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 4; i++) _orbitWord(colors, l10n.introValueWord(i), i, activeIndex, frac),
            Transform.scale(
              scale: orbScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: PayspinTokens.gradientPink,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: PayspinTokens.pink.withValues(alpha: 0.3), blurRadius: 24),
                        BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.15), blurRadius: 16),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: PayspinMotion.fast,
                      child: Icon(
                        _icons[activeIndex],
                        key: ValueKey(activeIndex),
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: const PayspinMorphingAuroraHairline(intensity: 0.8),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: PayspinMotion.fast,
                    child: Text(
                      l10n.introValueWord(activeIndex),
                      key: ValueKey('label_$activeIndex'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orbitWord(
    PayspinSemanticColors colors,
    String word,
    int i,
    int active,
    double frac,
  ) {
    final angle = (i / 4) * 2 * math.pi - math.pi / 2 + frac * 0.3;
    const radius = 118.0;
    final isActive = i == active;
    final scale = isActive ? 1.0 : 0.75;
    final opacity = isActive ? 1.0 : 0.35;

    return Positioned(
      left: 140 + math.cos(angle) * radius - 40,
      top: 140 + math.sin(angle) * radius - 12,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Text(
            word.split(' ').first,
            style: GoogleFonts.inter(
              fontSize: isActive ? 13 : 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? PayspinTokens.mint : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
