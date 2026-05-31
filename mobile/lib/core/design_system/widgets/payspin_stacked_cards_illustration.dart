import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

/// Layered "ghost cards" illustration used by empty states (Tikkies/Groepies).
///
/// Three stacked rounded cards fan out behind a glowing gradient emoji badge —
/// gives empty screens a premium, branded feel instead of plain text.
class PayspinStackedCardsIllustration extends StatelessWidget {
  const PayspinStackedCardsIllustration({super.key, this.emoji = '💸'});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _card(angle: -0.14, dx: -30, dy: 14, opacity: 0.30),
          _card(angle: 0.12, dx: 30, dy: 8, opacity: 0.45),
          _card(angle: 0, dx: 0, dy: -4, opacity: 1, withBadge: true),
        ],
      ),
    );
  }

  Widget _card({
    required double angle,
    required double dx,
    required double dy,
    required double opacity,
    bool withBadge = false,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 120,
            height: 84,
            decoration: BoxDecoration(
              color: PayspinTokens.bgElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PayspinTokens.border),
              boxShadow: withBadge
                  ? [
                      BoxShadow(
                        color: PayspinTokens.pink.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: withBadge
                ? Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: PayspinTokens.gradientPink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
