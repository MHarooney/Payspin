import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';
import 'payspin_radial_glow.dart';
import 'payspin_stacked_cards_illustration.dart';

/// Branded empty state: glow + stacked-cards illustration + title + subtitle
/// + optional action(s). Entrance fade/slide for a polished first impression.
class PayspinEmptyState extends StatelessWidget {
  const PayspinEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.primary,
    this.secondary,
    this.tertiary,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Widget? primary;
  final Widget? secondary;
  final Widget? tertiary;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: _Entrance(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const PayspinRadialGlow(size: 240),
                    PayspinStackedCardsIllustration(emoji: emoji),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted, height: 1.55),
              ),
              if (primary != null) ...[const SizedBox(height: 28), primary!],
              if (secondary != null) ...[const SizedBox(height: 12), secondary!],
              if (tertiary != null) ...[const SizedBox(height: 8), tertiary!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Entrance extends StatefulWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}
