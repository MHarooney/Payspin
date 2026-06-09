import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';

/// Lightweight confetti burst for intro scene 3 pay success.
class IntroMiniConfetti extends StatelessWidget {
  const IntroMiniConfetti({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    return CustomPaint(
      size: const Size(200, 120),
      painter: _ConfettiPainter(progress: progress),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;
  static const _colors = [PayspinTokens.mint, PayspinTokens.pink, PayspinTokens.mustard, PayspinTokens.blue];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);
    for (var i = 0; i < 12; i++) {
      final rnd = math.Random(i * 13);
      final angle = rnd.nextDouble() * 2 * math.pi;
      final dist = 30 + progress * 80 * (0.5 + rnd.nextDouble());
      final pos = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist - progress * 40);
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      if (i.isEven) {
        canvas.drawCircle(pos, 3 + rnd.nextDouble() * 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: pos, width: 5, height: 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
