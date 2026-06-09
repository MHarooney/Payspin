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
import 'payspin_status_chip.dart';

class PayspinTikkieRow extends StatelessWidget {
  const PayspinTikkieRow({
    super.key,
    required this.link,
    required this.onTap,
    this.tintIndex = 0,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onCopy,
    this.onShare,
  });

  final PaymentLink link;
  final VoidCallback onTap;
  final int tintIndex;

  /// Favorites are client-side (see [FavoriteLinksStore]); when
  /// [onToggleFavorite] is provided a star + long-press power sheet appear.
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  /// Emoji chosen from the description (e.g. "Pizza" → 🍕), not at random.
  static String emojiFor(PaymentLink link) =>
      PaymentVisuals.emoji(link.description ?? link.shortCode);

  bool get _hasSheet => onToggleFavorite != null || onCopy != null || onShare != null;

  Future<void> _openSheet(BuildContext context) async {
    if (!_hasSheet) return;
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    final colors = context.psColors;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Widget tile(IconData icon, String label, VoidCallback? onTap) {
          return ListTile(
            enabled: onTap != null,
            leading: Icon(icon, color: onTap != null ? colors.textBody : colors.textHint),
            title: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: onTap != null ? colors.textBody : colors.textHint,
              ),
            ),
            onTap: onTap == null
                ? null
                : () {
                    Navigator.of(sheetContext).pop();
                    onTap();
                  },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 8),
              if (onToggleFavorite != null)
                tile(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
                  onToggleFavorite,
                ),
              if (onCopy != null) tile(Icons.link_rounded, l10n.copyLink, onCopy),
              if (onShare != null) tile(Icons.ios_share_rounded, l10n.shareLink, onShare),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = link.description?.trim().isNotEmpty == true ? link.description! : link.amountLabel;
    final paid = link.completedPaymentCount > 0;
    final status = paid ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel;
    final statusColor = PaymentVisuals.linkStatusColor(link.status, hasCompletedPayments: paid);
    final colors = context.psColors;
    final isOpenAmount = link.amountCents == null;

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
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: _hasSheet ? () => _openSheet(context) : null,
            child: Row(
              children: [
                PayspinLinkIconAvatar(link: link, tintIndex: tintIndex),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFavorite) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, size: 14, color: PayspinTokens.mustard),
                          ],
                        ],
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
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isOpenAmount ? PayspinTokens.mint : colors.textPrimary,
                      ),
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
