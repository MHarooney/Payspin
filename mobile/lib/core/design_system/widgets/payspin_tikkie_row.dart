import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../../utils/payment_visuals.dart';
import '../theme/payspin_semantic_colors.dart';
import 'payspin_glass_surface.dart';
import 'payspin_status_chip.dart';

class PayspinTikkieRow extends StatelessWidget {
  const PayspinTikkieRow({super.key, required this.link, required this.onTap, this.tintIndex = 0});

  final PaymentLink link;
  final VoidCallback onTap;
  final int tintIndex;

  static const _tints = [Color(0x2EFC00FF), Color(0x2E07D8DD), Color(0x2EFFC408), Color(0x2E5C7AEA)];

  /// Emoji chosen from the description (e.g. "Pizza" → 🍕), not at random.
  static String emojiFor(PaymentLink link) =>
      PaymentVisuals.emoji(link.description ?? link.shortCode);

  @override
  Widget build(BuildContext context) {
    final tint = _tints[tintIndex % _tints.length];
    final title = link.description?.trim().isNotEmpty == true ? link.description! : link.amountLabel;
    final paid = link.completedPaymentCount > 0;
    final status = paid ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel;
    final statusColor = PaymentVisuals.linkStatusColor(link.status, hasCompletedPayments: paid);
    final colors = context.psColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '$title, ${link.amountLabel}, $status',
        child: PayspinGlassSurface(
          tier: PayspinGlassTier.flat,
          borderRadius: 18,
          onTap: onTap,
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
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerLeft, child: PayspinStatusChip(label: status, color: statusColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (link.dateLabel.isNotEmpty)
                    Text(link.dateLabel, style: GoogleFonts.inter(fontSize: 11, color: colors.textHint)),
                  const SizedBox(height: 4),
                  Text(
                    link.amountLabel,
                    style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 16, color: colors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
