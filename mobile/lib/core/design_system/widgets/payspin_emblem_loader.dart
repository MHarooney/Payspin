import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/payspin_motion.dart';
import 'payspin_emblem_assemble.dart';

/// Branded loading indicator — loops the splash emblem assemble + breathing pulse.
///
/// Reduced motion → static assembled emblem.
class PayspinEmblemLoader extends StatefulWidget {
  const PayspinEmblemLoader({super.key, this.size = 48});

  final double size;

  @override
  State<PayspinEmblemLoader> createState() => _PayspinEmblemLoaderState();
}

class _PayspinEmblemLoaderState extends State<PayspinEmblemLoader> with TickerProviderStateMixin {
  AnimationController? _assemble;
  AnimationController? _ambient;

  @override
  void initState() {
    super.initState();
    _assemble = AnimationController(vsync: this, duration: PayspinMotion.splashAssemble);
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMotion());
  }

  void _startMotion() {
    if (!mounted) return;
    if (PayspinMotion.reduced(context)) return;
    _assemble?.repeat();
    _ambient?.repeat();
  }

  @override
  void dispose() {
    _assemble?.dispose();
    _ambient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);

    if (reduced) {
      return Semantics(
        label: 'Loading',
        child: payspinEmblemAssembleForContext(
          context,
          size: widget.size,
          progress: 1,
          glow: widget.size >= 40,
        ),
      );
    }

    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: Listenable.merge([_assemble!, _ambient!]),
        builder: (context, _) {
          final breath = 1 + 0.02 * math.sin(_ambient!.value * 2 * math.pi);
          return Transform.scale(
            scale: breath,
            child: payspinEmblemAssembleForContext(
              context,
              size: widget.size,
              progress: _assemble!.value,
              glow: widget.size >= 40,
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen or section loading placeholder using the splash-style loader.
class PayspinPageLoader extends StatelessWidget {
  const PayspinPageLoader({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(child: PayspinEmblemLoader(size: size));
  }
}
