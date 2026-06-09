import 'package:flutter/material.dart';

import '../../../domain/entities/payment_link.dart';
import '../../utils/payment_visuals.dart';
import '../tokens/payspin_tokens.dart';

/// Shared emoji/glyph tile for a payment link — a rounded tinted square with the
/// deterministic [PaymentVisuals] emoji. Used by the Tikkie row, favorite card,
/// and active hero so every link looks consistent.
///
/// Open-amount links get a subtle mint accent ring; an [active] tile gets a
/// pink→mint gradient ring to read as the current request.
class PayspinLinkIconAvatar extends StatelessWidget {
  const PayspinLinkIconAvatar({
    super.key,
    required this.link,
    this.size = 44,
    this.tintIndex = 0,
    this.active = false,
  });

  final PaymentLink link;
  final double size;
  final int tintIndex;
  final bool active;

  static const _tints = [
    Color(0x2EFC00FF),
    Color(0x2E07D8DD),
    Color(0x2EFFC408),
    Color(0x2E5C7AEA),
  ];

  bool get _isOpenAmount => link.amountCents == null;

  @override
  Widget build(BuildContext context) {
    final tint = _tints[tintIndex % _tints.length];
    final radius = BorderRadius.circular(size * 0.32);

    final Border? accentBorder = active
        ? null
        : _isOpenAmount
            ? Border.all(color: PayspinTokens.mint.withValues(alpha: 0.55), width: 1)
            : null;

    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: radius,
        border: accentBorder,
      ),
      alignment: Alignment.center,
      child: Text(
        PaymentVisuals.emoji(link.description ?? link.shortCode),
        style: TextStyle(fontSize: size * 0.5),
      ),
    );

    if (!active) return inner;

    // Gradient ring for the active/highlighted request.
    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: PayspinTokens.gradientPink,
        borderRadius: BorderRadius.circular(size * 0.32 + 2),
      ),
      child: inner,
    );
  }
}
