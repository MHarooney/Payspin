import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';
import 'payspin_emblem_loader.dart';

/// Secondary circle action (e.g. QR on send name) — mint tint when active.
class PayspinAccentCircleButton extends StatelessWidget {
  const PayspinAccentCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.loading = false,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final bool loading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Material(
      color: active ? PayspinTokens.mint.withValues(alpha: 0.15) : PayspinTokens.glass,
      shape: CircleBorder(
        side: BorderSide(
          color: active ? PayspinTokens.mint.withValues(alpha: 0.3) : PayspinTokens.border,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: loading
                ? PayspinEmblemLoader(size: size * 0.46)
                : Icon(
                    icon,
                    color: active ? PayspinTokens.mint : PayspinTokens.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
