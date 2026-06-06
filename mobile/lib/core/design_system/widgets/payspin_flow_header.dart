import 'package:flutter/material.dart';

import 'payspin_glass_icon_button.dart';

/// Send / onboarding top row: back + optional help. Appearance/language now
/// live only in Profile, so this header no longer exposes quick settings.
class PayspinFlowHeader extends StatelessWidget {
  const PayspinFlowHeader({
    super.key,
    required this.onBack,
    this.onHelp,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  final VoidCallback onBack;
  final VoidCallback? onHelp;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          PayspinGlassIconButton(icon: Icons.arrow_back, onPressed: onBack),
          const Spacer(),
          if (onHelp != null)
            PayspinGlassIconButton(icon: Icons.help_outline, onPressed: onHelp!),
        ],
      ),
    );
  }
}
