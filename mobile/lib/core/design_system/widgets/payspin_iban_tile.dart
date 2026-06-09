import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// A single bank account / IBAN row used in the profile list and the
/// send-flow account picker. Renders a masked IBAN, the holder, an optional
/// "Primary" badge, a selected radio indicator, and a trailing actions slot.
class PayspinIbanTile extends StatelessWidget {
  const PayspinIbanTile({
    super.key,
    required this.ibanLast4,
    required this.accountHolder,
    this.bankName,
    this.isPrimary = false,
    this.selected,
    this.onTap,
    this.trailing,
  });

  final String ibanLast4;
  final String accountHolder;
  final String? bankName;
  final bool isPrimary;

  /// When non-null, shows a radio indicator (picker mode).
  final bool? selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (bankName != null && bankName!.isNotEmpty) bankName!,
      accountHolder,
    ].join(' · ');
    final colors = context.psColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (selected != null) ...[
                Icon(
                  selected! ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected! ? PayspinTokens.mint : colors.textHint,
                ),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.glassFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.credit_card_outlined, size: 18, color: colors.textPrimary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '•••• $ibanLast4',
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          const PayspinPrimaryBadge(),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pink gradient pill shown next to the primary linked IBAN.
class PayspinPrimaryBadge extends StatelessWidget {
  const PayspinPrimaryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: PayspinTokens.gradientPink,
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
      ),
      child: Text(
        'Primary',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
          color: PayspinTokens.onBrand,
        ),
      ),
    );
  }
}
