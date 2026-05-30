import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../../core/design_system/widgets/payspin_logo.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: Stack(
        children: [
          ...List.generate(24, (i) {
            final colors = [PayspinTokens.mint, PayspinTokens.pink, PayspinTokens.mustard, PayspinTokens.blue];
            return Positioned(
              left: (i * 37) % MediaQuery.sizeOf(context).width,
              top: (i * 53) % MediaQuery.sizeOf(context).height * 0.6,
              child: Transform.rotate(
                angle: i * 0.4,
                child: Container(
                  width: 6 + (i % 3) * 2.0,
                  height: 4,
                  decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(2)),
                ),
              ),
            );
          }),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Text('Nice!', style: GoogleFonts.raleway(fontSize: 56, fontWeight: FontWeight.w900, color: PayspinTokens.textPrimary)),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'You can now use ', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w700, color: PayspinTokens.textBody)),
                      const WidgetSpan(child: PayspinGradientText('Payspin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const PayspinLogo(size: 96),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: PayspinGradientPillButton(
                    label: 'Go to Home',
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    onPressed: () => context.go('/home'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
