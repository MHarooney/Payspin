import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_link_icon_avatar.dart';

/// Compact pinned-link card for the Home Favorites horizontal strip. Shows the
/// link avatar, title, amount, and a filled star to unpin.
class PayspinFavoriteLinkCard extends StatelessWidget {
  const PayspinFavoriteLinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onUnfavorite,
    this.tintIndex = 0,
  });

  final PaymentLink link;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;
  final int tintIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final title = link.description?.trim().isNotEmpty == true
        ? link.description!
        : link.amountLabel;

    return SizedBox(
      width: 160,
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.flat,
        borderRadius: 18,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PayspinLinkIconAvatar(link: link, size: 40, tintIndex: tintIndex),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Unpin $title',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onUnfavorite();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.star_rounded, size: 20, color: PayspinTokens.mustard),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              link.amountLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: link.amountCents == null ? PayspinTokens.mint : colors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
