import 'package:flutter/material.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import 'payspin_emblem_assemble.dart';

/// Branded loading indicator — gradient arrow layers spinning together (2.4s loop).
///
/// Uses the split arc + loop assets so motion reads as “transaction flow”, not a
/// flat bitmap spin. Reduced motion → static assembled emblem.
class PayspinEmblemLoader extends StatefulWidget {
  const PayspinEmblemLoader({super.key, this.size = 48});

  final double size;

  @override
  State<PayspinEmblemLoader> createState() => _PayspinEmblemLoaderState();
}

class _PayspinEmblemLoaderState extends State<PayspinEmblemLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PayspinMotion.loop,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);

    if (reduced) {
      if (_controller.isAnimating) _controller.stop();
      return Semantics(
        label: 'Loading',
        child: PayspinEmblemAssembleStatic(
          size: widget.size,
          style: PayspinEmblemStyle.gradient,
        ),
      );
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }

    return Semantics(
      label: 'Loading',
      child: RotationTransition(
        turns: _controller,
        child: PayspinEmblemAssembleStatic(
          size: widget.size,
          style: PayspinEmblemStyle.gradient,
        ),
      ),
    );
  }
}
