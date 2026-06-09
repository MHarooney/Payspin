import 'package:flutter/material.dart';

import 'payspin_quick_action_tile.dart';

/// Describes one quick action. [onTap] null renders the tile disabled.
class PayspinQuickAction {
  const PayspinQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticHint,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticHint;
}

/// Evenly spaced row of up to four [PayspinQuickActionTile]s. Kept to ≤4 by
/// product decision (see mobile-home-redesign-plan.md) — no redundant tiles.
class PayspinQuickActionsRow extends StatelessWidget {
  const PayspinQuickActionsRow({super.key, required this.actions});

  final List<PayspinQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final a in actions)
          PayspinQuickActionTile(
            icon: a.icon,
            label: a.label,
            onTap: a.onTap,
            semanticHint: a.semanticHint,
          ),
      ],
    );
  }
}
