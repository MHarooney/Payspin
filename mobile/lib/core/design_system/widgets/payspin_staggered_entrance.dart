import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/payspin_motion.dart';

/// Fades and slides a child in with staggered delay — respects reduced motion.
class PayspinStaggeredEntrance extends StatefulWidget {
  const PayspinStaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.axis = Axis.vertical,
  });

  final int index;
  final Widget child;
  final Axis axis;

  @override
  State<PayspinStaggeredEntrance> createState() => _PayspinStaggeredEntranceState();
}

class _PayspinStaggeredEntranceState extends State<PayspinStaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: PayspinMotion.medium);
    _opacity = CurvedAnimation(parent: _controller, curve: PayspinMotion.easeEnter);
    final slide = widget.axis == Axis.vertical ? const Offset(0, 0.08) : const Offset(0.06, 0);
    _offset = Tween<Offset>(begin: slide, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: PayspinMotion.easeEnter),
    );
    final delay = PayspinMotion.stagger * widget.index;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _startTimer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PayspinMotion.reduced(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
