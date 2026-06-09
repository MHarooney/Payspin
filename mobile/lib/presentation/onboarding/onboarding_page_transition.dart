import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/theme/payspin_motion.dart';

/// Slide + fade for onboarding route pushes (forward = from right).
Page<T> onboardingTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  bool isBack = false,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: PayspinMotion.medium,
    reverseTransitionDuration: PayspinMotion.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (PayspinMotion.reduced(context)) return child;
      final begin = Offset(isBack ? -0.08 : 0.08, 0);
      final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: PayspinMotion.easeEnter),
      );
      final fade = CurvedAnimation(parent: animation, curve: PayspinMotion.easeEnter);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
