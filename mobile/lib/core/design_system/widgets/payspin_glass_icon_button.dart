import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';

/// 40×40 glass circle with icon — home header, send flow, notifications.
class PayspinGlassIconButton extends StatelessWidget {
  const PayspinGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.semanticLabel,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  /// When false, drops the glass fill, border and shadow — just a tappable icon
  /// for a simpler, flat app-bar look.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;

    final button = Material(
      color: bordered ? colors.glassFill : Colors.transparent,
      shape: CircleBorder(
        side: bordered ? BorderSide(color: colors.glassBorder) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
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

    return Semantics(
      button: true,
      label: semanticLabel,
      child: bordered
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: colors.glassShadow, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: button,
            )
          : button,
    );
  }
}
