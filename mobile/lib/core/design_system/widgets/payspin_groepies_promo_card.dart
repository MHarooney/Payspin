import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

/// Promo card nudging users toward Groepies, shown at the bottom of the
/// Tikkies list.
class PayspinGroepiesPromoCard extends StatelessWidget {
  const PayspinGroepiesPromoCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PayspinTokens.purple.withValues(alpha: 0.20),
                PayspinTokens.mint.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
            border: Border.all(color: PayspinTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: PayspinTokens.gradientPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('👥', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split costs with Groepies',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 15, color: PayspinTokens.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track shared expenses with friends.',
                      style: GoogleFonts.inter(fontSize: 12, color: PayspinTokens.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: PayspinTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
