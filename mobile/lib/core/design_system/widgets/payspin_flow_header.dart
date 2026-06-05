import 'package:flutter/material.dart';

import 'payspin_glass_icon_button.dart';
import 'payspin_quick_settings.dart';

/// Send / onboarding top row: back + appearance/language + optional help.
class PayspinFlowHeader extends StatelessWidget {
  const PayspinFlowHeader({
    super.key,
    required this.onBack,
    this.onHelp,
    this.showQuickSettings = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  final VoidCallback onBack;
  final VoidCallback? onHelp;
  final bool showQuickSettings;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          PayspinGlassIconButton(icon: Icons.arrow_back, onPressed: onBack),
          const Spacer(),
          if (showQuickSettings) const PayspinQuickSettings(),
          if (onHelp != null) ...[
            const SizedBox(width: 10),
            PayspinGlassIconButton(icon: Icons.help_outline, onPressed: onHelp!),
          ],
        ],
      ),
    );
  }
}
