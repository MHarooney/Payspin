import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Horizontal text tabs with an animated sliding mint underline.
class PayspinTabStrip extends StatelessWidget {
  const PayspinTabStrip({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _itemWidth = 72;
  static const double _gap = 24;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  _tab(context, labels[i], i),
                ],
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: selectedIndex * (_itemWidth + _gap) + 12,
              bottom: 0,
              child: Container(
                height: 2.5,
                width: _itemWidth - 24,
                decoration: BoxDecoration(
                  gradient: PayspinTokens.gradientPink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, String label, int index) {
    final active = index == selectedIndex;
    final colors = context.psColors;
    return GestureDetector(
      onTap: () => onSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _itemWidth,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: active ? colors.textPrimary : colors.textMuted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
