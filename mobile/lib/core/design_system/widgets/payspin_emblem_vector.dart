import 'package:flutter/material.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_emblem_paths.dart';

/// Vector-drawn Payspin emblem — stroke-trim animation for splash, loaders, etc.
///
/// Prefer this over PNG layer slides when you need precise control (draw speed,
/// stagger, glow, partial loops). [progress] is `0…1` on the master controller.
class PayspinEmblemVector extends StatelessWidget {
  const PayspinEmblemVector({
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
  Widget build(BuildContext context) {
    final useGradient = _useGradient(context);

    final emblem = CustomPaint(
      size: Size(size, size),
      painter: _PayspinEmblemPainter(
        progress: progress,
        useGradient: useGradient,
      ),
    );

    if (!glow) return emblem;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.psColors.pageGlowPink,
            blurRadius: size * 0.35,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: emblem,
    );
  }

  bool _useGradient(BuildContext context) {
    final emblemStyle = switch (style) {
      PayspinEmblemStyle.white => PayspinEmblemStyle.white,
      PayspinEmblemStyle.gradient => PayspinEmblemStyle.gradient,
      PayspinEmblemStyle.auto => context.psColors.emblemStyle,
    };
    return emblemStyle == PayspinEmblemStyle.gradient;
  }
}

class _PayspinEmblemPainter extends CustomPainter {
  _PayspinEmblemPainter({
    required this.progress,
    required this.useGradient,
  });

  final double progress;
  final bool useGradient;

  // Layer motion spans ~70% of master progress (arc leads, loop trails).
  static const _arcEnd = 0.42;
  static const _loopStart = 0.16;
  static const _loopEnd = 0.78;

  @override
  void paint(Canvas canvas, Size size) {
    final arcT = Curves.easeInOutCubic.transform(
      (progress / _arcEnd).clamp(0.0, 1.0),
    );
    final loopT = Curves.easeInOutCubic.transform(
      ((progress - _loopStart) / (_loopEnd - _loopStart)).clamp(0.0, 1.0),
    );

    final loopFill = PayspinEmblemPaths.scaled(PayspinEmblemPaths.loopFill(), size.width);
    final arcFill = PayspinEmblemPaths.scaled(PayspinEmblemPaths.arcFill(), size.width);
    final loopSpine = PayspinEmblemPaths.scaled(PayspinEmblemPaths.loopSpine(), size.width);
    final arcSpine = PayspinEmblemPaths.scaled(PayspinEmblemPaths.arcSpine(), size.width);

    final fillPaint = _fillPaint(size);

    _drawRevealed(canvas, size, loopFill, loopSpine, fillPaint, loopT);
    _drawRevealed(canvas, size, arcFill, arcSpine, fillPaint, arcT);
  }

  Paint _fillPaint(Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (useGradient) {
      paint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [PayspinTokens.pink, PayspinTokens.mint],
      ).createShader(Offset.zero & size);
    } else {
      paint.color = Colors.white;
    }
    return paint;
  }

  /// Draws [fill] revealed up to [t] by clipping to a growing ribbon built from
  /// overlapping discs sampled along the drawn portion of [spine]. The reveal
  /// follows the arrow's curve; final pixels match the official outline exactly.
  void _drawRevealed(
    Canvas canvas,
    Size size,
    Path fill,
    Path spine,
    Paint fillPaint,
    double t,
  ) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(fill, fillPaint);
      return;
    }

    final radius = size.width * 0.16;
    final step = radius * 0.5;
    final clip = Path()..fillType = PathFillType.nonZero;
    for (final metric in spine.computeMetrics()) {
      final drawn = metric.length * t;
      if (drawn <= 0) continue;
      for (var d = 0.0; d < drawn; d += step) {
        final tan = metric.getTangentForOffset(d);
        if (tan != null) {
          clip.addOval(Rect.fromCircle(center: tan.position, radius: radius));
        }
      }
      final endTan = metric.getTangentForOffset(drawn);
      if (endTan != null) {
        clip.addOval(Rect.fromCircle(center: endTan.position, radius: radius));
      }
    }

    canvas.save();
    canvas.clipPath(clip);
    canvas.drawPath(fill, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PayspinEmblemPainter old) =>
      old.progress != progress || old.useGradient != useGradient;
}

/// Fully drawn emblem — reduced motion / loader static frame.
class PayspinEmblemVectorStatic extends StatelessWidget {
  const PayspinEmblemVectorStatic({
    super.key,
    required this.size,
    this.style = PayspinEmblemStyle.white,
    this.glow = false,
  });

  final double size;
  final PayspinEmblemStyle style;
  final bool glow;

  @override
  Widget build(BuildContext context) => PayspinEmblemVector(
        size: size,
        progress: 1,
        style: style,
        glow: glow,
      );
}

/// Respects reduced motion — static vector when OS requests it.
Widget payspinEmblemVectorForContext(
  BuildContext context, {
  required double size,
  required double progress,
  PayspinEmblemStyle style = PayspinEmblemStyle.white,
  bool glow = false,
}) {
  if (PayspinMotion.reduced(context)) {
    return PayspinEmblemVectorStatic(size: size, style: style, glow: glow);
  }
  return PayspinEmblemVector(
    size: size,
    progress: progress,
    style: style,
    glow: glow,
  );
}
