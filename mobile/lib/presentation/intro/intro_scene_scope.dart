import 'package:flutter/material.dart';

/// Provides per-scene visibility (0..1) from the intro [PageController] offset.
class IntroSceneScope extends InheritedWidget {
  const IntroSceneScope({
    super.key,
    required this.pageOffset,
    required this.offsetListenable,
    required super.child,
  });

  final double pageOffset;
  final Listenable offsetListenable;

  static IntroSceneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IntroSceneScope>();

  /// How visible scene [index] is (1 = fully on screen).
  static double visibility(BuildContext context, int index) {
    final scope = maybeOf(context);
    if (scope == null) return 1;
    return (1 - (scope.pageOffset - index).abs()).clamp(0.0, 1.0);
  }

  @override
  bool updateShouldNotify(IntroSceneScope old) => old.pageOffset != pageOffset;
}
