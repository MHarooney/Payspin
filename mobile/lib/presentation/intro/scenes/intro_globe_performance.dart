import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';

/// Performance tuning for the intro 3D globe (Scene 2).
///
/// The live globe uses GPU shaders + per-frame repaints. On physical devices we
/// prefer a lighter profile: lazy mount, no atmosphere/lighting, static arcs,
/// and no endless rotation after the entry zoom.
abstract final class IntroGlobePerformance {
  /// Mount the globe only when the scene is mostly on screen.
  static const double mountThreshold = 0.45;

  /// Tear down GPU resources once the scene has almost left the viewport.
  static const double teardownThreshold = 0.06;

  /// Cap illustration size so the shader paints fewer pixels.
  static const double maxGlobeSide = 276;

  /// Decode the Earth texture at a smaller resolution on device.
  static const ImageConfiguration surfaceConfiguration = ImageConfiguration(
    size: Size(512, 256),
    devicePixelRatio: 1,
  );

  /// Lighter shaders/textures on all devices; reduced motion adds static poses.
  static bool liteMode(BuildContext context) => true;

  static bool shouldMount(double visibility) => visibility >= mountThreshold;

  static bool shouldTeardown(double visibility) =>
      visibility < teardownThreshold;
}

/// Lightweight placeholder shown before the globe mounts or while loading.
class IntroGlobePlaceholder extends StatelessWidget {
  const IntroGlobePlaceholder({super.key, required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    final diameter = side * 0.66;
    return SizedBox(
      width: side,
      height: side,
      child: Center(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                PayspinTokens.mint.withValues(alpha: 0.14),
                const Color(0xFF15141F),
                Colors.black.withValues(alpha: 0.35),
              ],
              stops: const [0.2, 0.72, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: PayspinTokens.pink.withValues(alpha: 0.12),
                blurRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
