import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';
import 'payspin_gradient_pill_button.dart';

/// A reusable bottom sheet that explains a feature with numbered steps.
class PayspinExplainerSheet extends StatelessWidget {
  const PayspinExplainerSheet({
    super.key,
    required this.title,
    required this.steps,
    this.ctaLabel = 'Got it',
  });

  final String title;
  final List<({String emoji, String title, String body})> steps;
  final String ctaLabel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<({String emoji, String title, String body})> steps,
    String ctaLabel = 'Got it',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PayspinExplainerSheet(title: title, steps: steps, ctaLabel: ctaLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PayspinTokens.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, 24 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
          const SizedBox(height: 18),
          for (final step in steps) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PayspinTokens.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(step.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700, color: PayspinTokens.textPrimary)),
                        const SizedBox(height: 3),
                        Text(step.body, style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          PayspinGradientPillButton(label: ctaLabel, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
