import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'intro_scene_scope.dart';

/// Pauses a looping [AnimationController] when the scene is off-screen.
mixin IntroSceneLifecycle<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  AnimationController? _loop;
  int _sceneIndex = 0;
  bool _visible = true;
  VoidCallback? _offsetListener;
  Listenable? _offsetListenable;

  void bindIntroLoop({
    required AnimationController controller,
    required int sceneIndex,
  }) {
    _loop = controller;
    _sceneIndex = sceneIndex;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _attachOffsetListener();
      _syncLoop();
    });
  }

  void _attachOffsetListener() {
    final scope = IntroSceneScope.maybeOf(context);
    if (scope == null || _offsetListener != null) return;
    _offsetListener = _syncLoop;
    _offsetListenable = scope.offsetListenable;
    _offsetListenable!.addListener(_offsetListener!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachOffsetListener();
    _syncLoop();
  }

  @override
  void dispose() {
    if (_offsetListener != null && _offsetListenable != null) {
      _offsetListenable!.removeListener(_offsetListener!);
    }
    super.dispose();
  }

  void _syncLoop() {
    final controller = _loop;
    if (controller == null || !mounted) return;
    final v = IntroSceneScope.visibility(context, _sceneIndex);
    final shouldRun = v > 0.15;
    if (shouldRun == _visible) return;
    _visible = shouldRun;
    if (shouldRun) {
      if (!controller.isAnimating) controller.repeat();
    } else {
      controller.stop();
    }
  }
}
