import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../../utils/payment_visuals.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_link_icon_avatar.dart';
import 'payspin_progress_bar.dart';
import 'payspin_status_chip.dart';

/// Highlighted "active request" card for Home — one request the payee is still
/// collecting on. Shows the link avatar, title, live status, amount received,
/// and (for capped MULTI links) a progress bar like "2 of 3 paid".
class PayspinActiveRequestHero extends StatelessWidget {
  const PayspinActiveRequestHero({
    super.key,
    required this.link,
    required this.onTap,
    this.progress,
    this.progressLabel,
  });

  final PaymentLink link;
  final VoidCallback onTap;

  /// 0..1 fraction for capped MULTI links; null hides the bar.
  final double? progress;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final title = link.description?.trim().isNotEmpty == true
        ? link.description!
        : link.amountLabel;
    final paid = link.completedPaymentCount > 0;
    final statusColor = PaymentVisuals.linkStatusColor(link.status, hasCompletedPayments: paid);

    return PayspinGlassSurface(
      tier: PayspinGlassTier.hero,
      gradientBorder: true,
      glow: true,
      borderRadius: 22,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PayspinLinkIconAvatar(link: link, size: 48, active: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PayspinStatusChip(label: link.statusLabel, color: statusColor),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    link.amountLabel,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (paid) ...[
                    const SizedBox(height: 2),
                    Text(
                      link.totalReceivedLabel,
                      style: GoogleFonts.inter(fontSize: 12, color: PayspinTokens.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (progressLabel != null) ...[
            const SizedBox(height: 16),
            Text(
              progressLabel!,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textMuted),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              PayspinProgressBar(progress: progress!),
            ],
          ],
        ],
      ),
    );
  }
}
