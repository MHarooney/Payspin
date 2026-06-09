import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Row of passcode progress dots (filled = entered). Shakes via parent [Transform]
/// and turns pink on [error] to signal a wrong code.
class PayspinPasscodeDots extends StatelessWidget {
  const PayspinPasscodeDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
    this.successPulse = false,
  });

  /// Total dots to render.
  final int length;

  /// How many are currently filled.
  final int filled;

  final bool error;

  /// Brief mint glow on all filled dots when a step completes.
  final bool successPulse;

  static const double _dotSize = 14;
  static const double _dotMargin = 9;
  static const double _slotWidth = _dotSize + _dotMargin * 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final trackWidth = length * _slotWidth;
    final railInset = _dotMargin + _dotSize / 2;
    final progress = length == 0 ? 0.0 : (filled / length).clamp(0.0, 1.0);

    return SizedBox(
      width: trackWidth,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: railInset,
            right: railInset,
            top: 13,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: colors.glassBorder,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            left: railInset,
            top: 13,
            width: (trackWidth - railInset * 2) * progress,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: PayspinTokens.gradientPink,
                borderRadius: BorderRadius.circular(1),
                boxShadow: successPulse
                    ? [BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.5), blurRadius: 8)]
                    : null,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(length, (i) {
              final isFilled = i < filled;
              return _PasscodeDot(
                key: ValueKey('dot-$i'),
                isFilled: isFilled,
                error: error,
                successPulse: successPulse && isFilled,
                colors: colors,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PasscodeDot extends StatefulWidget {
  const _PasscodeDot({
    super.key,
    required this.isFilled,
    required this.error,
    required this.successPulse,
    required this.colors,
  });

  final bool isFilled;
  final bool error;
  final bool successPulse;
  final PayspinSemanticColors colors;

  @override
  State<_PasscodeDot> createState() => _PasscodeDotState();
}

class _PasscodeDotState extends State<_PasscodeDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void didUpdateWidget(_PasscodeDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFilled && widget.isFilled && !PayspinMotion.reduced(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.error
        ? PayspinTokens.pink
        : widget.isFilled
            ? widget.colors.textPrimary
            : widget.colors.textHint;

    final reduced = PayspinMotion.reduced(context);

    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final t = reduced ? 0.0 : _pop.value;
        final scale = 1.0 + 0.18 * math.sin(t * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 9),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isFilled || widget.error ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          boxShadow: widget.isFilled && !widget.error
              ? [
                  BoxShadow(
                    color: PayspinTokens.mint.withValues(alpha: widget.successPulse ? 0.45 : 0.25),
                    blurRadius: widget.successPulse ? 12 : 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
