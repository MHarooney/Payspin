import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';

/// Groepies tab body — keep inside [HomePage] scroll so header + tabs stay visible.
class GroepiesTabContent extends StatelessWidget {
  const GroepiesTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Track Group Expenses?',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep track of costs together quickly and easily. And we\'ll do all the math.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: PayspinTokens.textMuted, height: 1.6),
          ),
          const SizedBox(height: 28),
          PayspinGradientPillButton(
            label: 'Create Groepie',
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// Standalone route wrapper (e.g. deep link to /home/groepies).
class GroepiesPage extends StatelessWidget {
  const GroepiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: GroepiesTabContent(),
    );
  }
}
