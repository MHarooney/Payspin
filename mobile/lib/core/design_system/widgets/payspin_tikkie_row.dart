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
import 'payspin_status_chip.dart';

/// Opens the link power-actions sheet (favorite, copy, share, QR, request again).
Future<void> showPayspinLinkActionsSheet(
  BuildContext context, {
  required PaymentLink link,
  required bool isFavorite,
  VoidCallback? onToggleFavorite,
  VoidCallback? onCopy,
  VoidCallback? onShare,
  VoidCallback? onShowQr,
  VoidCallback? onRequestAgain,
}) async {
  final hasSheet = onToggleFavorite != null ||
      onCopy != null ||
      onShare != null ||
      onShowQr != null ||
      onRequestAgain != null;
  if (!hasSheet) return;

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
            if (onShowQr != null && link.isPayable) tile(Icons.qr_code_2_rounded, l10n.showQr, onShowQr),
            if (onRequestAgain != null && link.canRequestAgain)
              tile(Icons.replay_rounded, l10n.requestAgain, onRequestAgain),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

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
    this.onShowQr,
    this.onRequestAgain,
    this.onShareDisabled,
    this.showShortcuts = true,
    this.swipeRevealProgress = 0,
    this.useOpaqueSwipeBacking = false,
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
  final VoidCallback? onShowQr;
  final VoidCallback? onRequestAgain;

  /// Called when share is tapped but the link is not payable.
  final VoidCallback? onShareDisabled;

  /// When false, hides the always-visible share/copy rail (e.g. search-only list).
  final bool showShortcuts;

  /// 0..1 peel progress from [PayspinTikkieSlidableRow] — fades the amount column.
  final double swipeRevealProgress;

  /// Solid backing so action dock does not bleed through glass at rest.
  final bool useOpaqueSwipeBacking;

  /// Emoji chosen from the description (e.g. "Pizza" → 🍕), not at random.
  static String emojiFor(PaymentLink link) =>
      PaymentVisuals.emoji(link.description ?? link.shortCode);

  bool get _hasSheet =>
      onToggleFavorite != null ||
      onCopy != null ||
      onShare != null ||
      onShowQr != null ||
      onRequestAgain != null;

  Future<void> openActionsSheet(BuildContext context) => showPayspinLinkActionsSheet(
        context,
        link: link,
        isFavorite: isFavorite,
        onToggleFavorite: onToggleFavorite,
        onCopy: onCopy,
        onShare: onShare,
        onShowQr: onShowQr,
        onRequestAgain: onRequestAgain,
      );

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
    final title = link.description?.trim().isNotEmpty == true ? link.description! : link.amountLabel;
    final paid = link.completedPaymentCount > 0;
    final status = paid ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel;
    final statusColor = PaymentVisuals.linkStatusColor(link.status, hasCompletedPayments: paid);
    final colors = context.psColors;
    final isOpenAmount = link.amountCents == null;
    final shareEnabled = link.isPayable && onShare != null;

    final amountOpacity = (1 - (swipeRevealProgress * 1.4)).clamp(0.0, 1.0);

    Widget rowSurface = PayspinGlassSurface(
          tier: PayspinGlassTier.flat,
          borderRadius: 18,
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: _hasSheet ? () => openActionsSheet(context) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PayspinStatusChip(label: status, color: statusColor),
                      ),
                      if (showShortcuts && (onCopy != null || onShare != null)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (onShare != null)
                              PayspinLinkSharePill(
                                label: l10n.shareLink,
                                enabled: shareEnabled,
                                semanticLabel: l10n.shareLink,
                                onPressed: _onShareTap,
                              ),
                            if (onShare != null && onCopy != null) const SizedBox(width: 8),
                            if (onCopy != null)
                              PayspinLinkCopyButton(
                                onPressed: _onCopyTap,
                                semanticLabel: l10n.copyLink,
                              ),
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
                ),
              ],
            ),
          ),
        );

    if (useOpaqueSwipeBacking) {
      rowSurface = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.glassBorder),
        ),
        child: rowSurface,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '$title, ${link.amountLabel}, $status',
        child: rowSurface,
      ),
    );
  }
}
