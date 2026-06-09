import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../../l10n/payspin_localizations.dart';
import '../../utils/payment_visuals.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_link_icon_avatar.dart';
import 'payspin_link_shortcut_button.dart';
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
    this.onCopy,
    this.onShare,
    this.onShareDisabled,
    this.swipeRevealProgress = 0,
    this.useOpaqueSwipeBacking = false,
  });

  final PaymentLink link;
  final VoidCallback onTap;

  /// 0..1 fraction for capped MULTI links; null hides the bar.
  final double? progress;
  final String? progressLabel;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onShareDisabled;
  final double swipeRevealProgress;
  final bool useOpaqueSwipeBacking;

  void _onShareTap() {
    if (link.isPayable && onShare != null) {
      HapticFeedback.lightImpact();
      onShare!();
    } else {
      onShareDisabled?.call();
    }
  }

  void _onCopyTap() {
    if (onCopy == null) return;
    HapticFeedback.lightImpact();
    onCopy!();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.psColors;
    final title = link.description?.trim().isNotEmpty == true
        ? link.description!
        : link.amountLabel;
    final paid = link.completedPaymentCount > 0;
    final statusColor = PaymentVisuals.linkStatusColor(link.status, hasCompletedPayments: paid);
    final shareEnabled = link.isPayable && onShare != null;
    final amountOpacity = (1 - (swipeRevealProgress * 1.4)).clamp(0.0, 1.0);

    Widget heroSurface = PayspinGlassSurface(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (onCopy != null || onShare != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (onShare != null)
                            PayspinLinkSharePill(
                              label: l10n.shareLink,
                              enabled: shareEnabled,
                              onPressed: _onShareTap,
                            ),
                          if (onShare != null && onCopy != null) const SizedBox(width: 8),
                          if (onCopy != null)
                            PayspinLinkCopyButton(onPressed: _onCopyTap),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Opacity(
                opacity: amountOpacity,
                child: Column(
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PayspinTokens.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
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

    if (useOpaqueSwipeBacking) {
      heroSurface = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.glassBorder),
        ),
        child: heroSurface,
      );
    }

    return heroSurface;
  }
}
