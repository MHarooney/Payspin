import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Visual style for a peel-reveal action well.
enum PeelActionKind { cancel, hide, more, dismiss }

/// One action exposed when the user swipes a card left.
class PeelRevealAction {
  const PeelRevealAction({
    required this.icon,
    required this.label,
    required this.kind,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final PeelActionKind kind;
  final VoidCallback onTap;
}

/// Shared right-edge clip peel for home cards (links, hero, promos).
///
/// Foreground clips from the right; opaque action dock fades in after ~12%
/// reveal progress. Dock hidden at rest to avoid ghosting through glass.
class PayspinPeelReveal extends StatefulWidget {
  const PayspinPeelReveal({
    super.key,
    required this.peelId,
    required this.isOpen,
    required this.onOpenChanged,
    required this.actions,
    required this.builder,
    this.tileWidth = 80,
    this.borderRadius = 18,
    this.dragZoneFraction = 0.42,
  });

  final String peelId;
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;
  final List<PeelRevealAction> actions;
  final Widget Function(double revealProgress) builder;
  final double tileWidth;
  final double borderRadius;
  final double dragZoneFraction;

  @override
  State<PayspinPeelReveal> createState() => _PayspinPeelRevealState();
}

class _PayspinPeelRevealState extends State<PayspinPeelReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragExtent = 0;
  double _lastHapticProgress = 0;

  int get _actionCount => widget.actions.length;
  double get _maxExtent => _actionCount * widget.tileWidth;

  double get _revealProgress =>
      _maxExtent == 0 ? 0 : (_dragExtent / _maxExtent).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PayspinMotion.medium,
    )..addListener(_onAnimate);
    if (widget.isOpen && _maxExtent > 0) {
      _controller.value = 1;
      _dragExtent = _maxExtent;
    }
  }

  void _onAnimate() {
    setState(() => _dragExtent = _controller.value * _maxExtent);
  }

  @override
  void didUpdateWidget(PayspinPeelReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      _animateTo(widget.isOpen ? 1 : 0, snapHaptic: widget.isOpen);
    }
    if (_dragExtent > _maxExtent) {
      _dragExtent = _maxExtent;
      _controller.value = _maxExtent == 0 ? 0 : 1;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimate);
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool snapHaptic = false}) {
    final reduced = PayspinMotion.reduced(context);
    if (reduced) {
      _controller.value = target;
      _dragExtent = target * _maxExtent;
      if (snapHaptic && target == 1) HapticFeedback.lightImpact();
      return;
    }
    _controller.animateTo(
      target,
      curve: target > _controller.value ? PayspinMotion.spring : PayspinMotion.easeExit,
    ).then((_) {
      if (snapHaptic && target == 1 && mounted) HapticFeedback.lightImpact();
    });
  }

  void _setOpen(bool open) {
    if (open != widget.isOpen) widget.onOpenChanged(open);
    _animateTo(open ? 1 : 0, snapHaptic: open);
    if (!open) _lastHapticProgress = 0;
  }

  void _close() => _setOpen(false);

  void _onDragUpdate(DragUpdateDetails details) {
    if (_maxExtent == 0) return;
    var next = _dragExtent - details.delta.dx;
    if (next > _maxExtent) {
      next = _maxExtent + (next - _maxExtent) * 0.25;
    }
    next = next.clamp(0.0, _maxExtent * 1.15);
    setState(() => _dragExtent = next);
    _controller.value = (next / _maxExtent).clamp(0.0, 1.0);

    final progress = _revealProgress;
    if (progress >= 0.5 && _lastHapticProgress < 0.5) {
      HapticFeedback.selectionClick();
    }
    _lastHapticProgress = progress;

    if (next > 0 && !widget.isOpen) widget.onOpenChanged(true);
    if (next == 0 && widget.isOpen) widget.onOpenChanged(false);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_maxExtent == 0) return;
    final velocity = details.primaryVelocity ?? 0;
    final open = velocity < -240 || _dragExtent > _maxExtent * 0.45;
    _setOpen(open);
  }

  double _dockOpacity(bool reduced) {
    if (reduced) return _revealProgress > 0 ? 1 : 0;
    return Curves.easeOut.transform(((_revealProgress - 0.12) / 0.88).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    if (_actionCount == 0) return widget.builder(0);

    final reduced = PayspinMotion.reduced(context);
    final dockOpacity = _dockOpacity(reduced);
    final widthFactor = (1 - _revealProgress).clamp(0.001, 1.0);
    final radius = widget.borderRadius;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;

        return SizedBox(
          width: fullWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: _maxExtent,
                  child: Opacity(
                    opacity: dockOpacity,
                    child: _PeelActionDock(
                      progress: _revealProgress,
                      reduced: reduced,
                      actions: widget.actions,
                      onAction: (action) {
                        _close();
                        action.onTap();
                      },
                    ),
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor,
                    child: SizedBox(
                      width: fullWidth,
                      child: Stack(
                        children: [
                          ClipRect(child: widget.builder(_revealProgress)),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: fullWidth * widget.dragZoneFraction,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: _onDragUpdate,
                              onHorizontalDragEnd: _onDragEnd,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeelActionDock extends StatelessWidget {
  const _PeelActionDock({
    required this.progress,
    required this.reduced,
    required this.actions,
    required this.onAction,
  });

  final double progress;
  final bool reduced;
  final List<PeelRevealAction> actions;
  final void Function(PeelRevealAction action) onAction;

  double _staggerFor(int index) {
    if (reduced) return progress > 0 ? 1 : 0;
    final threshold = index == 0 ? 0.4 : 0.65;
    return ((progress - threshold) / (1 - threshold)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++)
            Expanded(
              child: _PeelActionWell(
                action: actions[i],
                stagger: _staggerFor(i),
                onTap: () => onAction(actions[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeelActionWell extends StatelessWidget {
  const _PeelActionWell({
    required this.action,
    required this.stagger,
    required this.onTap,
  });

  final PeelRevealAction action;
  final double stagger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final scale = 0.75 + 0.25 * Curves.easeOut.transform(stagger);
    final slideX = 12 * (1 - stagger);

    final BoxDecoration decoration = switch (action.kind) {
      PeelActionKind.cancel => const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PayspinTokens.danger, Color(0xFFFF2D55)],
          ),
        ),
      PeelActionKind.hide || PeelActionKind.dismiss => BoxDecoration(
          color: const Color(0xFF1E1A2E),
          border: Border(left: BorderSide(color: colors.border)),
        ),
      PeelActionKind.more => BoxDecoration(
          color: PayspinTokens.mint.withValues(alpha: 0.18),
          border: Border(left: BorderSide(color: colors.border)),
        ),
    };

    final iconColor = switch (action.kind) {
      PeelActionKind.cancel => PayspinTokens.onBrand,
      PeelActionKind.hide || PeelActionKind.dismiss => colors.textPrimary,
      PeelActionKind.more => PayspinTokens.mint,
    };

    final circleFill = switch (action.kind) {
      PeelActionKind.cancel => Colors.white.withValues(alpha: 0.2),
      PeelActionKind.hide || PeelActionKind.dismiss || PeelActionKind.more => colors.bgElevated,
    };

    return ClipRect(
      child: Transform.translate(
        offset: Offset(slideX, 0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: decoration,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: circleFill,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.glassBorder),
                        ),
                        child: Icon(action.icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
