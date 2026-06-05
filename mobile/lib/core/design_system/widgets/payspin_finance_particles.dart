import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/payspin_motion_scope.dart';
import '../theme/payspin_motion.dart';
import '../tokens/payspin_tokens.dart';

/// Ambient finance-themed particle field: euro coins, payment-link pills and
/// soft bubbles drifting upward with depth-based tilt parallax.
///
/// Communicates the product (money moving between people) without weight — a
/// single repaint loop over ~14 cached primitives. Honours Reduce Motion
/// (renders a calm static field) and reads device tilt from [PayspinMotionScope].
class PayspinFinanceParticles extends StatefulWidget {
  const PayspinFinanceParticles({super.key, this.intensity = 1});

  /// Scales particle opacity (0 = invisible, 1 = default).
  final double intensity;

  @override
  State<PayspinFinanceParticles> createState() => _PayspinFinanceParticlesState();
}

class _PayspinFinanceParticlesState extends State<PayspinFinanceParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  late final List<_Particle> _particles = _buildParticles();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !PayspinMotion.reduced(context)) _drift.repeat();
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tiltListenable = PayspinMotionScope.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => ValueListenableBuilder<Offset>(
            valueListenable: tiltListenable,
            builder: (context, tilt, __) => LayoutBuilder(
              builder: (context, constraints) => CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: reduced ? 0.2 : _drift.value,
                  tilt: reduced ? Offset.zero : tilt,
                  intensity: widget.intensity,
                  isLight: isLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_Particle> _buildParticles() {
    final rng = math.Random(42);
    const count = 14;
    return List.generate(count, (i) {
      return _Particle(
        x: rng.nextDouble(),
        baseY: rng.nextDouble(),
        size: 14 + rng.nextDouble() * 26,
        speed: 0.25 + rng.nextDouble() * 0.5,
        depth: 0.25 + rng.nextDouble() * 0.75,
        phase: rng.nextDouble() * math.pi * 2,
        swaySpeed: 0.4 + rng.nextDouble() * 0.8,
        type: _ParticleType.values[i % _ParticleType.values.length],
        colorIndex: rng.nextInt(3),
      );
    });
  }
}

enum _ParticleType { coin, pill, bubble }

class _Particle {
  const _Particle({
    required this.x,
    required this.baseY,
    required this.size,
    required this.speed,
    required this.depth,
    required this.phase,
    required this.swaySpeed,
    required this.type,
    required this.colorIndex,
  });

  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double depth;
  final double phase;
  final double swaySpeed;
  final _ParticleType type;
  final int colorIndex;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.tilt,
    required this.intensity,
    required this.isLight,
  });

  final List<_Particle> particles;
  final double progress;
  final Offset tilt;
  final double intensity;
  final bool isLight;

  /// Light surfaces need brand-saturated strokes — never white-on-white.
  List<Color> get _palette => isLight
      ? [
          PayspinTokens.pink,
          PayspinTokens.mint,
          const Color(0xFF5A5F6B),
        ]
      : [
          PayspinTokens.pink,
          PayspinTokens.mint,
          Colors.white,
        ];

  double get _alphaBoost => isLight ? 1.75 : 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final rawY = (p.baseY - progress * p.speed) % 1.0;
      final y = (rawY < 0 ? rawY + 1.0 : rawY);
      final sway = math.sin(progress * 2 * math.pi * p.swaySpeed + p.phase) * 0.018;
      final px = (p.x + sway) * size.width + tilt.dx * p.depth * 26;
      final py = y * size.height + tilt.dy * p.depth * 18;

      final edge = (y < 0.12)
          ? y / 0.12
          : (y > 0.88 ? (1 - y) / 0.12 : 1.0);
      final alpha = ((0.10 + 0.16 * p.depth) * edge * intensity * _alphaBoost)
          .clamp(0.0, isLight ? 0.55 : 0.35);
      if (alpha <= 0.01) continue;

      final color = _palette[p.colorIndex];
      final r = p.size * (0.55 + 0.45 * p.depth) / 2;
      final center = Offset(px, py);

      switch (p.type) {
        case _ParticleType.coin:
          _drawCoin(canvas, center, r, color, alpha);
          break;
        case _ParticleType.pill:
          _drawPill(canvas, center, r, color, alpha);
          break;
        case _ParticleType.bubble:
          _drawBubble(canvas, center, r, color, alpha);
          break;
      }
    }
  }

  void _drawCoin(Canvas canvas, Offset c, double r, Color color, double a) {
    final fillAlpha = isLight ? a * 0.35 : a * 0.5;
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: fillAlpha));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLight ? 1.4 : 1.2
        ..color = color.withValues(alpha: (a * 1.15).clamp(0, 1)),
    );
    final glyphColor = isLight ? color : Colors.white;
    final fontSize = r * 1.05;
    final glyph = TextPainter(
      text: TextSpan(
        text: '\u20AC',
        style: TextStyle(
          color: glyphColor.withValues(alpha: (a * 1.5).clamp(0.35, 1)),
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, c - Offset(glyph.width / 2, glyph.height / 2));
  }

  void _drawPill(Canvas canvas, Offset c, double r, Color color, double a) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 3.2, height: r * 1.3),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: a * 0.45));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLight ? 1.3 : 1.1
        ..color = color.withValues(alpha: (a * 1.15).clamp(0, 1)),
    );
    final dotColor = isLight ? color : Colors.white;
    final dot = Paint()..color = dotColor.withValues(alpha: (a * 1.3).clamp(0.4, 1));
    canvas.drawCircle(c - Offset(r * 0.7, 0), r * 0.22, dot);
    canvas.drawCircle(c + Offset(r * 0.7, 0), r * 0.22, dot);
  }

  void _drawBubble(Canvas canvas, Offset c, double r, Color color, double a) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLight ? 1.4 : 1.2
        ..color = color.withValues(alpha: (a * 0.95).clamp(0, 1)),
    );
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress ||
      old.tilt != tilt ||
      old.intensity != intensity ||
      old.isLight != isLight;
}
