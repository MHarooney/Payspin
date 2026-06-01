import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

class PayspinGradientCircleButton extends StatelessWidget {
  const PayspinGradientCircleButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.size = 56,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: enabled ? PayspinTokens.gradientPink : null,
        color: enabled ? null : PayspinTokens.surfaceMuted,
        boxShadow: enabled ? PayspinTokens.fabShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: PayspinTokens.onBrand),
                  )
                : Icon(icon, color: PayspinTokens.onBrand, size: size * 0.4),
          ),
        ),
      ),
    );
  }
}
