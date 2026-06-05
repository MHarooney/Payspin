import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/payspin_localizations.dart';
import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';

/// Floating glass navigation bar — a rounded `glass.overlay` pill with an
/// animated active highlight and brand glow on the selected item.
class PayspinBottomNav extends StatelessWidget {
  const PayspinBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: PayspinGlassSurface(
          tier: PayspinGlassTier.overlay,
          borderRadius: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _item(context, 0, l10n.navHome, Icons.home_rounded),
              _item(context, 1, l10n.navScanQr, Icons.qr_code_scanner_rounded),
              _item(context, 2, l10n.navProfile, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, String label, IconData icon) {
    final colors = context.psColors;
    final selected = currentIndex == index;
    final color = selected ? colors.textPrimary : colors.textMuted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          child: AnimatedContainer(
            duration: PayspinMotion.fast,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        PayspinTokens.pink.withValues(alpha: 0.16),
                        PayspinTokens.mint.withValues(alpha: 0.10),
                      ],
                    )
                  : null,
              border: selected
                  ? Border.all(color: PayspinTokens.pink.withValues(alpha: 0.28))
                  : Border.all(color: Colors.transparent),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PayspinGradientFab extends StatelessWidget {
  const PayspinGradientFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: PayspinTokens.gradientPink, boxShadow: PayspinTokens.fabShadow),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add, color: PayspinTokens.onBrand, size: 28),
        ),
      ),
    );
  }
}
