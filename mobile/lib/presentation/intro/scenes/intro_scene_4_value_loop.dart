import 'package:flutter/material.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/l10n/payspin_localizations.dart';

/// Scene 4 — a gradient badge cycles through Easy → Quick → Free → All over
/// Europe, each with its own icon.
class IntroScene4 extends StatefulWidget {
  const IntroScene4({super.key});

  @override
  State<IntroScene4> createState() => _IntroScene4State();
}

class _IntroScene4State extends State<IntroScene4>
    with SingleTickerProviderStateMixin {
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

    Widget badge(int index, double scale, double opacity) {
      return Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: PayspinTokens.gradientPink,
                  shape: BoxShape.circle,
                  boxShadow: PayspinTokens.fabShadow,
                ),
                child: Icon(_icons[index], color: Colors.white, size: 54),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.introValueWord(index),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (PayspinMotion.reduced(context)) {
      return Center(child: badge(0, 1, 1));
    }

    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final pos = _c.value * 4; // 0..4
          final index = pos.floor() % 4;
          final frac = pos - pos.floor();
          // Cross-fade near each boundary.
          final scale = 0.9 + 0.1 * (1 - (frac - 0.0).clamp(0.0, 1.0));
          final opacity = frac < 0.85 ? 1.0 : (1 - frac) / 0.15;
          return badge(index, scale.clamp(0.9, 1.0), opacity.clamp(0.0, 1.0));
        },
      ),
    );
  }
}
