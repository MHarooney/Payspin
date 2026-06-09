import 'package:flutter/material.dart';

import '../../../domain/entities/payment_link.dart';
import 'payspin_peel_reveal.dart';

/// Payment-link adapter over [PayspinPeelReveal] (cancel / hide / more).
class PayspinTikkieSlidableRow extends StatelessWidget {
  const PayspinTikkieSlidableRow({
    super.key,
    required this.link,
    required this.builder,
    required this.isOpen,
    required this.onOpenChanged,
    this.onCancel,
    this.onArchive,
    this.onMore,
    this.cancelLabel = 'Cancel link',
    this.archiveLabel = 'Hide',
    this.moreLabel = 'More',
    this.borderRadius = 18,
  });

  final PaymentLink link;
  final Widget Function(double revealProgress) builder;
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback? onCancel;
  final VoidCallback? onArchive;
  final VoidCallback? onMore;
  final String cancelLabel;
  final String archiveLabel;
  final String moreLabel;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final canCancel = link.canCancel && onCancel != null;
    final canArchive = !canCancel && onArchive != null;
    final actions = <PeelRevealAction>[];

    if (canCancel) {
      actions.add(PeelRevealAction(
        icon: Icons.link_off_rounded,
        label: cancelLabel,
        kind: PeelActionKind.cancel,
        onTap: onCancel!,
      ));
    } else if (canArchive) {
      actions.add(PeelRevealAction(
        icon: Icons.visibility_off_rounded,
        label: archiveLabel,
        kind: PeelActionKind.hide,
        onTap: onArchive!,
      ));
    }
    if (onMore != null) {
      actions.add(PeelRevealAction(
        icon: Icons.more_horiz_rounded,
        label: moreLabel,
        kind: PeelActionKind.more,
        onTap: onMore!,
      ));
    }

    return PayspinPeelReveal(
      peelId: link.id,
      isOpen: isOpen,
      onOpenChanged: onOpenChanged,
      actions: actions,
      builder: builder,
      borderRadius: borderRadius,
    );
  }
}
