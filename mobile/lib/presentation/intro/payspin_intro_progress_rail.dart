import 'package:flutter/material.dart';

import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';

/// Liquid pill progress for the 5-scene intro storyboard.
class PayspinIntroProgressRail extends StatelessWidget {
  const PayspinIntroProgressRail({
    super.key,
    required this.count,
    required this.active,
    this.pageOffset,
  });

  final int count;
  final int active;
  final double? pageOffset;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final offset = pageOffset ?? active.toDouble();
    final reduced = PayspinMotion.reduced(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          _Dot(
            active: i == active,
            proximity: (1 - (offset - i).abs()).clamp(0.0, 1.0),
            color: colors.glassBorder,
            reduced: reduced,
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.active,
    required this.proximity,
    required this.color,
    required this.reduced,
  });

  final bool active;
  final double proximity;
  final Color color;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final width = active ? 22.0 : 8.0 + proximity * 2;
    return AnimatedContainer(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 350),
      curve: PayspinMotion.easeEnter,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: width,
      height: 8,
      decoration: BoxDecoration(
        gradient: active ? PayspinTokens.gradientPink : null,
        color: active ? null : color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: proximity > 0.6 && !active
            ? [BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.12 * proximity), blurRadius: 6)]
            : null,
      ),
    );
  }
}
