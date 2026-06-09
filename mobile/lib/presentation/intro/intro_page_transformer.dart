import 'package:flutter/material.dart';

import '../../core/design_system/theme/payspin_motion.dart';

/// Parallax scale + fade for intro [PageView] pages.
class IntroPageTransformer extends StatelessWidget {
  const IntroPageTransformer({
    super.key,
    required this.pageOffset,
    required this.index,
    required this.child,
  });

  final double pageOffset;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PayspinMotion.reduced(context)) return child;

    final delta = (pageOffset - index).abs().clamp(0.0, 1.0);
    final scale = 1 - delta * 0.08;
    final opacity = 1 - delta * 0.4;
    final dx = (pageOffset - index) * 24;

    return Opacity(
      opacity: opacity.clamp(0.6, 1.0),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}
