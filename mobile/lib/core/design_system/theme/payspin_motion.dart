import 'package:flutter/material.dart';

/// Shared motion tokens — durations, curves, and stagger timing.
///
/// Keep transitions short and purposeful (250–400 ms). Splash uses dedicated
/// [splashAssemble] / [splashMinimum] tokens. Loop loaders 2–3 s/rotation.
/// Always pair animated widgets with a reduced-motion fallback via
/// [PayspinMotion.reduced].
abstract final class PayspinMotion {
  /// Button press, icon toggle.
  static const Duration fast = Duration(milliseconds: 200);

  /// Page push, card expand.
  static const Duration medium = Duration(milliseconds: 350);

  /// Splash reveal, success bounce.
  static const Duration slow = Duration(milliseconds: 600);

  /// Two-layer emblem assemble on cold start (arc + loop stagger).
  static const Duration splashAssemble = Duration(milliseconds: 2400);

  /// Minimum time splash stays on screen before routing (tap skips early).
  static const Duration splashMinimum = Duration(milliseconds: 5200);

  /// Loader spin period (one full rotation).
  static const Duration loop = Duration(milliseconds: 2400);

  /// QR plate scale-in.
  static const Duration qrScale = Duration(milliseconds: 350);

  /// Stagger between list/grid children.
  static const Duration stagger = Duration(milliseconds: 70);

  /// Elements entering the screen.
  static const Curve easeEnter = Curves.easeOutCubic;

  /// Elements leaving the screen.
  static const Curve easeExit = Curves.easeInCubic;

  /// Spring-like overshoot for success/emblem pops.
  static const Curve spring = Curves.easeOutBack;

  /// Whether the OS has requested reduced motion. When true, callers must skip
  /// non-essential animation and show the final state immediately.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
