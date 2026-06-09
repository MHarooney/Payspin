import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/l10n/payspin_localizations.dart';
import '../intro_scene_lifecycle.dart';

/// Scene 5 — perspective profession carousel with labels.
class IntroScene5 extends StatefulWidget {
  const IntroScene5({super.key, this.sceneIndex = 4});

  final int sceneIndex;

  @override
  State<IntroScene5> createState() => _IntroScene5State();
}

class _IntroScene5State extends State<IntroScene5>
    with SingleTickerProviderStateMixin, IntroSceneLifecycle {
  static const _icons = [
    Icons.photo_camera_outlined,
    Icons.handyman_outlined,
    Icons.laptop_mac_outlined,
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
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
      return _carousel(colors, l10n, 0, 0);
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pos = _c.value * 3;
        final active = pos.floor() % 3;
        final merge = (_c.value > 0.92) ? ((_c.value - 0.92) / 0.08) : 0.0;
        return _carousel(colors, l10n, active, merge);
      },
    );
  }

  Widget _carousel(
    PayspinSemanticColors colors,
    PayspinLocalizations l10n,
    int activeIndex,
    double mergeGlow,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (mergeGlow > 0)
                  Container(
                    width: 120 + mergeGlow * 40,
                    height: 120 + mergeGlow * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PayspinTokens.pink.withValues(alpha: 0.2 * mergeGlow),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                for (var i = 0; i < 3; i++) _card(colors, i, activeIndex),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: PayspinMotion.fast,
            child: Text(
              l10n.introProfessionLabel(activeIndex),
              key: ValueKey(activeIndex),
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(PayspinSemanticColors colors, int i, int active) {
    final offset = (i - active).toDouble();
    final isCenter = offset == 0;
    final scale = isCenter ? 1.0 : 0.82;
    final opacity = isCenter ? 1.0 : 0.45;
    final dx = offset * 110;

    Widget card = Container(
      width: 120,
      height: 150,
      decoration: BoxDecoration(
        gradient: isCenter ? PayspinTokens.gradientPink : null,
        color: isCenter ? null : colors.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCenter ? Colors.transparent : colors.glassBorder,
        ),
        boxShadow: isCenter ? PayspinTokens.fabShadow : null,
      ),
      child: Icon(
        _icons[i],
        size: 48,
        color: isCenter ? Colors.white : colors.textMuted,
      ),
    );

    if (!isCenter) {
      card = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: card,
      );
    }

    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.scale(
        scale: scale,
        child: Opacity(opacity: opacity, child: card),
      ),
    );
  }
}
