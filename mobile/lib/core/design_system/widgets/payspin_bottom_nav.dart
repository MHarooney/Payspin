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

  /// Chrome stacked above the home-indicator inset: outer bottom padding (12),
  /// glass vertical padding (16), and one nav item row (58).
  static const double heightAboveBottomInset = 12 + 16 + 58;

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
              _item(
                context,
                0,
                l10n.navHome,
                icon: (color) => Icon(Icons.home_rounded, size: 22, color: color),
              ),
              _item(
                context,
                1,
                'Payspin',
                // Payspin emblem tinted with the item colour — white in dark
                // mode, black in light mode (the white silhouette PNG keeps its
                // alpha, so tinting recolours the mark).
                icon: (color) => Image.asset(
                  'assets/images/payspin_emblem_white.png',
                  width: 22,
                  height: 22,
                  color: color,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    String label, {
    required Widget Function(Color color) icon,
  }) {
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
                SizedBox(height: 22, child: Center(child: icon(color))),
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
