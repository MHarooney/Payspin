import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

/// Secondary circle action (e.g. QR on send name) — mint tint when active.
class PayspinAccentCircleButton extends StatelessWidget {
  const PayspinAccentCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? PayspinTokens.mint.withValues(alpha: 0.15) : PayspinTokens.glass,
      shape: CircleBorder(
        side: BorderSide(
          color: active ? PayspinTokens.mint.withValues(alpha: 0.3) : PayspinTokens.border,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: active ? PayspinTokens.mint : PayspinTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
