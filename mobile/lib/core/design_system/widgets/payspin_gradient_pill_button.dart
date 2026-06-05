import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/payspin_motion.dart';
import '../tokens/payspin_tokens.dart';

class PayspinGradientPillButton extends StatefulWidget {
  const PayspinGradientPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  @override
  State<PayspinGradientPillButton> createState() => _PayspinGradientPillButtonState();
}

class _PayspinGradientPillButtonState extends State<PayspinGradientPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final reduced = PayspinMotion.reduced(context);
    final scale = (_pressed && enabled && !reduced) ? 0.97 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: PayspinMotion.fast,
      curve: PayspinMotion.easeEnter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? PayspinTokens.gradientPink : null,
          color: enabled ? null : PayspinTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          boxShadow: enabled ? PayspinTokens.fabShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!.call();
                  }
                : null,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
            child: SizedBox(
              height: PayspinTokens.btnHeightLg,
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: PayspinTokens.onBrand),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: PayspinTokens.onBrand,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ) ??
                                const TextStyle(
                                  color: PayspinTokens.onBrand,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
