import 'package:flutter/material.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';

/// Scene 5 — three professions light up in sequence: photographer,
/// tradesperson, freelancer.
class IntroScene5 extends StatefulWidget {
  const IntroScene5({super.key});

  @override
  State<IntroScene5> createState() => _IntroScene5State();
}

class _IntroScene5State extends State<IntroScene5>
    with SingleTickerProviderStateMixin {
  static const _icons = [
    Icons.photo_camera_outlined,
    Icons.handyman_outlined,
    Icons.laptop_mac_outlined,
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
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

    Widget panel(int i, double active) {
      return Expanded(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: 0.9 + active * 0.1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 150,
            decoration: BoxDecoration(
              gradient: active > 0.5 ? PayspinTokens.gradientPink : null,
              color: active > 0.5 ? null : colors.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active > 0.5 ? Colors.transparent : colors.glassBorder,
              ),
            ),
            child: Icon(
              _icons[i],
              size: 48,
              color: active > 0.5 ? Colors.white : colors.textMuted,
            ),
          ),
        ),
      );
    }

    if (PayspinMotion.reduced(context)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [panel(0, 1), panel(1, 0), panel(2, 0)]),
        ),
      );
    }

    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final activeIndex = (_c.value * 3).floor() % 3;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) panel(i, i == activeIndex ? 1 : 0),
              ],
            ),
          );
        },
      ),
    );
  }
}
