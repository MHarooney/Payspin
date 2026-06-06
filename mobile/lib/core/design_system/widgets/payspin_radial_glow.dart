import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

/// Slow breathing radial glow used behind welcome / success / empty states.
///
/// Renders a soft pink→mint radial gradient that gently scales and fades to
/// give depth without distracting from foreground content.
class PayspinRadialGlow extends StatefulWidget {
  const PayspinRadialGlow({
    super.key,
    this.size = 400,
    this.animate = true,
    this.alignment = const Alignment(0, -0.55),
    this.centered = false,
  });

  final double size;
  final bool animate;
  final Alignment alignment;

  /// When true, omits the outer [Align] so the glow can be centred inside a
  /// [Stack] behind the emblem (splash / welcome hero layout).
  final bool centered;

  @override
  State<PayspinRadialGlow> createState() => _PayspinRadialGlowState();
}

class _PayspinRadialGlowState extends State<PayspinRadialGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disk = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 0.92 + 0.12 * t;
        final opacity = 0.7 + 0.3 * t;
        return Transform.scale(
          scale: widget.animate ? scale : 1,
          child: Opacity(opacity: widget.animate ? opacity : 1, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              PayspinTokens.pink.withValues(alpha: 0.25),
              PayspinTokens.mint.withValues(alpha: 0.12),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 0.72],
          ),
        ),
      ),
    );

    if (widget.centered) {
      return IgnorePointer(child: disk);
    }

    return IgnorePointer(
      child: Align(
        alignment: widget.alignment,
        child: disk,
      ),
    );
  }
}
