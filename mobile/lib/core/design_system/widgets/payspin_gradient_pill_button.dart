import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/payspin_motion.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_emblem_loader.dart';

class PayspinGradientPillButton extends StatefulWidget {
  const PayspinGradientPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.shimmer = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  /// Loops a glossy "liquid glass" highlight across the CTA. Use on hero CTAs
  /// (welcome, onboarding) — not on every button.
  final bool shimmer;

  @override
  State<PayspinGradientPillButton> createState() => _PayspinGradientPillButtonState();
}

class _PayspinGradientPillButtonState extends State<PayspinGradientPillButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final reduced = PayspinMotion.reduced(context);
    final scale = (_pressed && enabled && !reduced) ? 0.97 : 1.0;

    final shimmerOn = widget.shimmer && enabled && !reduced;
    if (shimmerOn && !_shimmer.isAnimating) {
      _shimmer.repeat();
    } else if (!shimmerOn && _shimmer.isAnimating) {
      _shimmer.stop();
    }

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
              child: Stack(
                children: [
                  SizedBox(
                    height: PayspinTokens.btnHeightLg,
                    width: double.infinity,
                    child: Center(
                      child: widget.loading
                          ? const PayspinEmblemLoader(size: 22)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  widget.icon!,
                                  const SizedBox(width: 10)
                                ],
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
                  if (shimmerOn)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shimmer,
                          builder: (context, _) {
                            final dx = _shimmer.value * 2.6 - 1.3;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(dx - 0.3, -1),
                                  end: Alignment(dx + 0.3, 1),
                                  colors: const [
                                    Color(0x00FFFFFF),
                                    Color(0x40FFFFFF),
                                    Color(0x00FFFFFF),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
