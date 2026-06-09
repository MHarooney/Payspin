import 'package:flutter/material.dart';
import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/widgets/payspin_staggered_entrance.dart';

/// Staggered title + body entrance when a scene becomes active.
class IntroSceneCopy extends StatelessWidget {
  const IntroSceneCopy({
    super.key,
    required this.title,
    required this.body,
    required this.sceneKey,
    required this.titleStyle,
    required this.bodyStyle,
  });

  final String title;
  final String body;
  final int sceneKey;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PayspinStaggeredEntrance(
          key: ValueKey('intro_title_$sceneKey'),
          index: 0,
          child: Text(title, textAlign: TextAlign.center, style: titleStyle),
        ),
        const SizedBox(height: 14),
        PayspinStaggeredEntrance(
          key: ValueKey('intro_body_$sceneKey'),
          index: 1,
          child: Text(body, textAlign: TextAlign.center, style: bodyStyle),
        ),
      ],
    );
  }
}

/// Brief illustration exit before directed page advance.
class IntroIllustrationTransition extends StatelessWidget {
  const IntroIllustrationTransition({
    super.key,
    required this.exiting,
    required this.child,
  });

  final bool exiting;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PayspinMotion.reduced(context)) return child;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 150),
      curve: PayspinMotion.easeEnter,
      offset: exiting ? const Offset(0, -0.04) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: exiting ? 0 : 1,
        child: child,
      ),
    );
  }
}
