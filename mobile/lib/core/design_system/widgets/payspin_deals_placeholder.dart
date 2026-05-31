import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';
import 'payspin_radial_glow.dart';

/// Fully designed "coming soon" state for the Deals tab (prototype had none).
class PayspinDealsPlaceholder extends StatelessWidget {
  const PayspinDealsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const PayspinRadialGlow(size: 220),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: PayspinTokens.gradientPink,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: PayspinTokens.fabShadow,
                    ),
                    alignment: Alignment.center,
                    child: const Text('✨', style: TextStyle(fontSize: 40)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deals are on the way',
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'Exclusive offers and cashback from your favourite brands — landing here soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: PayspinTokens.textMuted, height: 1.55),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
                border: Border.all(color: PayspinTokens.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 16, color: PayspinTokens.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Notify me',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: PayspinTokens.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
