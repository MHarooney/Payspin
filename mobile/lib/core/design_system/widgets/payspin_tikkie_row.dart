import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../tokens/payspin_tokens.dart';

class PayspinTikkieRow extends StatelessWidget {
  const PayspinTikkieRow({super.key, required this.link, required this.onTap, this.tintIndex = 0});

  final PaymentLink link;
  final VoidCallback onTap;
  final int tintIndex;

  static const _tints = [Color(0x2EFC00FF), Color(0x2E07D8DD), Color(0x2EFFC408), Color(0x2E5C7AEA)];
  static const _emojis = ['🍣', '⛽', '🎁', '☕', '🍕', '🎬'];

  static String emojiFor(PaymentLink link) {
    final seed = (link.description ?? link.shortCode).hashCode;
    return _emojis[seed.abs() % _emojis.length];
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tints[tintIndex % _tints.length];
    final title = link.description?.trim().isNotEmpty == true ? link.description! : link.amountLabel;
    final status = link.completedPaymentCount > 0 ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: PayspinTokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(emojiFor(link), style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 15, color: PayspinTokens.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PayspinTokens.mint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: PayspinTokens.mint, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(status, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: PayspinTokens.mint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (link.dateLabel.isNotEmpty)
                      Text(link.dateLabel, style: GoogleFonts.inter(fontSize: 11, color: PayspinTokens.textHint)),
                    const SizedBox(height: 4),
                    Text(
                      link.amountLabel,
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 16, color: PayspinTokens.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
