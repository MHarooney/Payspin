import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

class PayspinGradientPillButton extends StatelessWidget {
  const PayspinGradientPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? PayspinTokens.gradientPink : null,
        color: enabled ? null : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        boxShadow: enabled ? PayspinTokens.fabShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          child: SizedBox(
            height: PayspinTokens.btnHeightLg,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 10)],
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
