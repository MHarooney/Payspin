import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/payspin_motion.dart';
import 'payspin_emblem_loader.dart';
import '../tokens/payspin_tokens.dart';

class PayspinGradientCircleButton extends StatefulWidget {
  const PayspinGradientCircleButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.size = 56,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final bool loading;

  @override
  State<PayspinGradientCircleButton> createState() => _PayspinGradientCircleButtonState();
}

class _PayspinGradientCircleButtonState extends State<PayspinGradientCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: PayspinMotion.loop)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final showLoader = widget.loading;
    final reduced = PayspinMotion.reduced(context);

    Widget button = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: enabled ? PayspinTokens.gradientPink : null,
        color: enabled ? null : PayspinTokens.surfaceMuted,
        boxShadow: enabled ? PayspinTokens.fabShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed?.call();
                }
              : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          customBorder: const CircleBorder(),
          child: Center(
            child: showLoader
                ? const PayspinEmblemLoader(size: 22)
                : Icon(widget.icon, color: PayspinTokens.onBrand, size: widget.size * 0.4),
          ),
        ),
      ),
    );

    if (enabled && !reduced) {
      button = AnimatedBuilder(
        animation: _glow,
        builder: (_, child) {
          final t = 0.5 + 0.5 * _glow.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PayspinTokens.pink.withValues(alpha: 0.18 * t),
                  blurRadius: 16 + 6 * t,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: button,
      );
    }

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: PayspinMotion.fast,
      curve: PayspinMotion.easeEnter,
      child: button,
    );
  }
}
