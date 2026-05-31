import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

/// Camera overlay: dims everything outside a centered square and draws
/// glowing mint corner brackets to guide QR alignment.
class PayspinScanFrame extends StatelessWidget {
  const PayspinScanFrame({super.key, this.size = 250});

  final double size;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ScanFramePainter(frameSize: size),
        );
      },
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter({required this.frameSize});

  final double frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final rect = Rect.fromCenter(center: center, width: frameSize, height: frameSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Dim everything except the cutout.
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRRect(rrect);
    final dim = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Corner brackets.
    final paint = Paint()
      ..color = PayspinTokens.mint
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    const r = 24.0;

    void corner(Offset c, double dx, double dy) {
      final path = Path()
        ..moveTo(c.dx, c.dy + dy * len)
        ..lineTo(c.dx, c.dy + dy * r)
        ..arcToPoint(Offset(c.dx + dx * r, c.dy), radius: const Radius.circular(r), clockwise: dx * dy > 0)
        ..lineTo(c.dx + dx * len, c.dy);
      canvas.drawPath(path, paint);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.frameSize != frameSize;
}
