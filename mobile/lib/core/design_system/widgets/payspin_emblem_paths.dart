import 'package:flutter/material.dart';

/// Vector geometry for the official Payspin two-arrow emblem (viewBox 0…100).
///
/// The two [arcFill] / [loopFill] paths are **filled outlines traced from the
/// canonical artwork** (`Emblem_White-01.png` / `Emblem_Gradient-01.png`) — two
/// open arrows with triangular heads, NOT closed rings. Render them filled.
///
/// [arcSpine] / [loopSpine] are open centre-lines used purely as a stroke-draw
/// reveal mask (sweep a wide round stroke along the spine, clipped to the fill
/// via `BlendMode.dstIn`) so the splash assemble looks hand-drawn while the
/// final pixels match the official emblem exactly.
abstract final class PayspinEmblemPaths {
  static const Size viewBox = Size(100, 100);

  /// Upper-left arrow — filled outline. Tail (lower-left) → arc over the top →
  /// right-pointing arrowhead. Traced from official artwork.
  static Path arcFill() {
    final p = Path();
    p.moveTo(35.79, 6.21);
    p.cubicTo(29.97, 6.78, 25.16, 8.62, 20.82, 11.96);
    p.cubicTo(19.47, 13.00, 17.13, 15.29, 16.09, 16.60);
    p.cubicTo(13.37, 20.03, 11.37, 24.38, 10.60, 28.55);
    p.cubicTo(10.21, 30.69, 10.12, 31.69, 10.12, 33.98);
    p.cubicTo(10.12, 37.45, 10.57, 40.24, 11.61, 43.28);
    p.cubicTo(13.45, 48.59, 16.57, 53.03, 20.99, 56.58);
    p.lineTo(21.81, 57.25);
    p.lineTo(25.11, 53.95);
    p.cubicTo(26.93, 52.12, 28.42, 50.62, 28.42, 50.62);
    p.cubicTo(28.42, 50.61, 28.04, 50.33, 27.57, 50.01);
    p.cubicTo(23.67, 47.34, 20.80, 43.29, 19.77, 39.01);
    p.cubicTo(19.40, 37.49, 19.24, 36.12, 19.24, 34.44);
    p.cubicTo(19.24, 32.69, 19.41, 31.25, 19.84, 29.59);
    p.cubicTo(21.15, 24.46, 24.85, 19.88, 29.67, 17.45);
    p.cubicTo(32.39, 16.06, 34.64, 15.47, 37.50, 15.36);
    p.cubicTo(40.62, 15.24, 43.29, 15.81, 46.13, 17.18);
    p.cubicTo(47.21, 17.69, 49.52, 19.14, 49.78, 19.45);
    p.cubicTo(49.85, 19.55, 49.45, 19.99, 47.99, 21.39);
    p.cubicTo(46.95, 22.38, 46.10, 23.21, 46.09, 23.24);
    p.cubicTo(46.09, 23.27, 47.88, 23.75, 50.08, 24.30);
    p.cubicTo(52.27, 24.84, 56.31, 25.87, 59.06, 26.57);
    p.cubicTo(61.83, 27.28, 64.10, 27.82, 64.13, 27.80);
    p.cubicTo(64.15, 27.77, 63.84, 26.18, 63.43, 24.25);
    p.cubicTo(63.02, 22.32, 62.28, 18.80, 61.77, 16.41);
    p.cubicTo(61.26, 14.01, 60.73, 11.50, 60.59, 10.82);
    p.lineTo(60.32, 9.58);
    p.lineTo(59.58, 10.25);
    p.cubicTo(59.17, 10.62, 58.47, 11.30, 58.01, 11.77);
    p.cubicTo(57.55, 12.24, 57.01, 12.74, 56.82, 12.91);
    p.lineTo(56.45, 13.20);
    p.lineTo(55.18, 12.21);
    p.cubicTo(51.25, 9.14, 46.75, 7.20, 41.84, 6.45);
    p.cubicTo(40.54, 6.24, 36.88, 6.10, 35.79, 6.21);
    p.close();
    return p;
  }

  /// Lower-right arrow — filled outline. Diagonal tail (bottom-left) → large
  /// right-hand loop → left-pointing arrowhead. Traced from official artwork.
  static Path loopFill() {
    final p = Path();
    p.moveTo(63.48, 36.79);
    p.cubicTo(59.32, 37.07, 55.63, 38.01, 52.18, 39.66);
    p.cubicTo(48.95, 41.19, 46.52, 42.90, 43.65, 45.64);
    p.cubicTo(43.19, 46.08, 42.36, 46.88, 41.80, 47.41);
    p.cubicTo(41.23, 47.94, 40.29, 48.84, 39.70, 49.41);
    p.cubicTo(39.11, 49.98, 37.62, 51.42, 36.38, 52.59);
    p.cubicTo(35.15, 53.76, 33.65, 55.20, 33.06, 55.76);
    p.cubicTo(32.47, 56.34, 29.06, 59.59, 25.49, 63.00);
    p.cubicTo(19.15, 69.03, 6.93, 80.69, 5.67, 81.89);
    p.lineTo(5.04, 82.50);
    p.lineTo(5.37, 82.87);
    p.cubicTo(5.56, 83.09, 7.01, 84.62, 8.62, 86.30);
    p.lineTo(11.54, 89.35);
    p.lineTo(15.80, 85.27);
    p.cubicTo(18.15, 83.04, 20.49, 80.81, 21.00, 80.32);
    p.cubicTo(21.50, 79.84, 22.38, 79.00, 22.95, 78.46);
    p.cubicTo(23.52, 77.92, 25.52, 76.01, 27.39, 74.21);
    p.cubicTo(29.28, 72.41, 32.72, 69.12, 35.06, 66.89);
    p.cubicTo(37.39, 64.66, 41.26, 60.97, 43.65, 58.69);
    p.cubicTo(46.04, 56.42, 48.57, 54.00, 49.27, 53.33);
    p.cubicTo(51.62, 51.05, 52.66, 50.21, 54.49, 49.12);
    p.cubicTo(56.24, 48.07, 58.46, 47.18, 60.58, 46.69);
    p.cubicTo(63.32, 46.04, 66.97, 46.02, 69.78, 46.62);
    p.cubicTo(76.89, 48.14, 82.82, 53.28, 84.89, 59.72);
    p.cubicTo(86.79, 65.62, 85.72, 71.95, 82.00, 76.91);
    p.cubicTo(78.10, 82.12, 71.68, 85.10, 65.50, 84.59);
    p.cubicTo(63.46, 84.41, 62.09, 84.10, 60.18, 83.36);
    p.cubicTo(58.45, 82.70, 57.16, 81.94, 55.43, 80.62);
    p.lineTo(54.56, 79.94);
    p.lineTo(56.46, 78.12);
    p.cubicTo(57.50, 77.11, 58.33, 76.27, 58.30, 76.25);
    p.cubicTo(58.27, 76.22, 56.76, 75.83, 54.93, 75.36);
    p.cubicTo(49.75, 74.03, 43.05, 72.31, 41.65, 71.93);
    p.cubicTo(40.96, 71.75, 40.36, 71.61, 40.35, 71.63);
    p.cubicTo(40.33, 71.65, 40.67, 73.40, 41.11, 75.51);
    p.cubicTo(42.26, 81.04, 44.04, 89.73, 44.04, 89.79);
    p.cubicTo(44.04, 89.99, 44.46, 89.63, 46.12, 88.05);
    p.cubicTo(47.72, 86.50, 48.02, 86.26, 48.15, 86.36);
    p.cubicTo(48.24, 86.43, 48.77, 86.87, 49.33, 87.33);
    p.cubicTo(52.71, 90.19, 57.23, 92.36, 61.62, 93.25);
    p.cubicTo(65.22, 93.98, 69.18, 93.98, 72.74, 93.25);
    p.cubicTo(80.93, 91.58, 88.04, 86.22, 91.85, 78.86);
    p.cubicTo(93.27, 76.10, 94.12, 73.43, 94.66, 70.02);
    p.cubicTo(94.83, 68.91, 94.86, 68.27, 94.86, 65.97);
    p.cubicTo(94.86, 63.01, 94.76, 61.96, 94.19, 59.42);
    p.cubicTo(92.76, 53.06, 88.88, 47.08, 83.47, 42.95);
    p.cubicTo(80.62, 40.79, 77.18, 39.02, 73.88, 38.05);
    p.cubicTo(70.46, 37.04, 66.57, 36.57, 63.48, 36.79);
    p.close();
    return p;
  }

  /// Open centre-line of the upper arc — tail → over the top → arrowhead tip.
  /// Used only as a stroke-draw reveal mask, not rendered directly.
  static Path arcSpine() {
    final p = Path();
    p.moveTo(21, 55);
    p.cubicTo(15, 49, 12, 42, 12.5, 34);
    p.cubicTo(13, 25, 18, 18, 26, 14);
    p.cubicTo(33, 11, 42, 11, 49, 15);
    p.cubicTo(54, 17, 58, 21, 61, 25);
    return p;
  }

  /// Open centre-line of the lower loop — diagonal tail → loop → arrowhead tip.
  /// Used only as a stroke-draw reveal mask, not rendered directly.
  static Path loopSpine() {
    final p = Path();
    p.moveTo(8, 86);
    p.cubicTo(20, 74, 34, 62, 47, 50);
    p.cubicTo(54, 44, 62, 41, 71, 43);
    p.cubicTo(84, 46, 92, 57, 91, 68);
    p.cubicTo(90, 80, 80, 88, 68, 90);
    p.cubicTo(58, 91, 49, 86, 43, 79);
    p.lineTo(42, 73);
    return p;
  }

  /// Scales normalized paths to [size] and recenters in the box.
  static Path scaled(Path source, double size) {
    final scale = size / viewBox.width;
    final offset = (size - viewBox.width * scale) / 2;
    final m = Matrix4.identity()
      ..translateByDouble(offset, offset, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    return source.transform(m.storage);
  }
}
