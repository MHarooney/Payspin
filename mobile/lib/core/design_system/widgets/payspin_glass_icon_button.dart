import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';

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
    final colors = context.psColors;
    return Material(
      color: colors.glassFill,
      shape: CircleBorder(side: BorderSide(color: colors.glassBorder)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: colors.textPrimary, size: iconSize),
        ),
      ),
    );
  }
}
