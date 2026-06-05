import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';
import 'payspin_emblem_vector.dart';

/// Two-layer Payspin emblem for splash assemble motion.
///
/// Implemented as **vector stroke-draw** ([PayspinEmblemVector]) so timing,
/// curvature, and glow are controlled in code — not PNG layer slides.
class PayspinEmblemAssemble extends StatelessWidget {
  const PayspinEmblemAssemble({
    super.key,
    required this.size,
    required this.progress,
    this.style = PayspinEmblemStyle.white,
    this.glow = false,
  });

  final double size;
  final double progress;
  final PayspinEmblemStyle style;
  final bool glow;

  @override
  Widget build(BuildContext context) => PayspinEmblemVector(
        size: size,
        progress: progress,
        style: style,
        glow: glow,
      );
}

class PayspinEmblemAssembleStatic extends StatelessWidget {
  const PayspinEmblemAssembleStatic({
    super.key,
    required this.size,
    this.style = PayspinEmblemStyle.white,
    this.glow = false,
  });

  final double size;
  final PayspinEmblemStyle style;
  final bool glow;

  @override
  Widget build(BuildContext context) => PayspinEmblemVectorStatic(
        size: size,
        style: style,
        glow: glow,
      );
}

Widget payspinEmblemAssembleForContext(
  BuildContext context, {
  required double size,
  required double progress,
  PayspinEmblemStyle style = PayspinEmblemStyle.white,
  bool glow = false,
}) =>
    payspinEmblemVectorForContext(
      context,
      size: size,
      progress: progress,
      style: style,
      glow: glow,
    );
