import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Compact row shortcuts — mint share pill + glass copy circle (~28–32px).
class PayspinLinkSharePill extends StatelessWidget {
  const PayspinLinkSharePill({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.45;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(100),
            child: Ink(
              decoration: BoxDecoration(
                gradient: PayspinTokens.gradientPink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ios_share_rounded, size: 13, color: PayspinTokens.onBrand),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: PayspinTokens.onBrand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PayspinLinkCopyButton extends StatelessWidget {
  const PayspinLinkCopyButton({
    super.key,
    required this.onPressed,
    this.size = 28,
    this.semanticLabel,
  });

  final VoidCallback onPressed;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: colors.glassFill,
        shape: CircleBorder(side: BorderSide(color: colors.glassBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.link_rounded, color: colors.textPrimary, size: 14),
          ),
        ),
      ),
    );
  }
}
