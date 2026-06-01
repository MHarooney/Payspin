import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

/// 40×40 glass circle with white icon — home header, send flow, notifications.
class PayspinGlassIconButton extends StatelessWidget {
  const PayspinGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PayspinTokens.glass,
      shape: CircleBorder(side: BorderSide(color: PayspinTokens.border)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: PayspinTokens.textPrimary, size: iconSize),
        ),
      ),
    );
  }
}
