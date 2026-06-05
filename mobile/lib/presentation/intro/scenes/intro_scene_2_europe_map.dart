import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';

/// Scene 2 — a stylised European network: requests fly from a source pin to
/// five destinations, and money sparks travel back.
class IntroScene2 extends StatefulWidget {
  const IntroScene2({super.key});

  @override
  State<IntroScene2> createState() => _IntroScene2State();
}

class _IntroScene2State extends State<IntroScene2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    if (PayspinMotion.reduced(context)) {
      return Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: CustomPaint(painter: _MapPainter(t: 0.5, colors: colors)),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              CustomPaint(painter: _MapPainter(t: _c.value, colors: colors)),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.t, required this.colors});

  final double t;
  final PayspinSemanticColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Offset(size.width * 0.42, size.height * 0.68); // DE-ish
    final targets = <Offset>[
      Offset(size.width * 0.34, size.height * 0.40), // NL
      Offset(size.width * 0.18, size.height * 0.58), // FR
      Offset(size.width * 0.20, size.height * 0.84), // ES
      Offset(size.width * 0.64, size.height * 0.30), // AT/CH-ish
      Offset(size.width * 0.74, size.height * 0.60),
    ];

    // Faint country dots scattered to suggest a map.
    final dotPaint = Paint()..color = colors.textHint.withValues(alpha: 0.18);
    final rnd = math.Random(7);
    for (var i = 0; i < 60; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.6, dotPaint);
    }

    final linkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      final phase = (t + i / targets.length) % 1.0;

      // Arc control point bows the path outward.
      final mid = Offset.lerp(source, target, 0.5)!;
      final normal = (target - source);
      final ctrl = mid + Offset(-normal.dy, normal.dx) * 0.25;

      Offset along(double p) {
        final a = Offset.lerp(source, ctrl, p)!;
        final b = Offset.lerp(ctrl, target, p)!;
        return Offset.lerp(a, b, p)!;
      }

      // Trail.
      final path = Path()..moveTo(source.dx, source.dy);
      for (var s = 0.0; s <= 1.0; s += 0.05) {
        final pt = along(s);
        path.lineTo(pt.dx, pt.dy);
      }
      linkPaint.color = PayspinTokens.mint.withValues(alpha: 0.18);
      canvas.drawPath(path, linkPaint);

      // Outgoing request (first half) then returning coin (second half).
      if (phase < 0.5) {
        final p = phase / 0.5;
        final pos = along(p);
        _envelope(canvas, pos, PayspinTokens.pink);
      } else {
        final p = (phase - 0.5) / 0.5;
        final pos = along(1 - p);
        _coin(canvas, pos);
      }

      // Destination dot.
      canvas.drawCircle(
        target,
        5,
        Paint()..color = PayspinTokens.mint.withValues(alpha: 0.9),
      );
    }

    // Source pin.
    canvas.drawCircle(source, 10, Paint()..color = PayspinTokens.pink);
    canvas.drawCircle(
      source,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _envelope(Canvas canvas, Offset c, Color color) {
    final r = Rect.fromCenter(center: c, width: 16, height: 11);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()..color = color,
    );
  }

  void _coin(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 7, Paint()..color = PayspinTokens.mustard);
    canvas.drawCircle(
      c,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.t != t || old.colors != colors;
}
