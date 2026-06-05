import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Row of passcode progress dots (filled = entered). Shakes via [shake] and
/// turns pink on [error] to signal a wrong code.
class PayspinPasscodeDots extends StatelessWidget {
  const PayspinPasscodeDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
  });

  /// Total dots to render.
  final int length;

  /// How many are currently filled.
  final int filled;

  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        final color = error
            ? PayspinTokens.pink
            : isFilled
                ? colors.textPrimary
                : colors.textHint;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled || error ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
            boxShadow: isFilled && !error
                ? [BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.25), blurRadius: 8)]
                : null,
          ),
        );
      }),
    );
  }
}
