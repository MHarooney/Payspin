import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_gradient_pill_button.dart';

/// Glass confirmation dialog for destructive / irreversible actions.
///
/// Returns `true` when confirmed, `false`/`null` otherwise. Use a single voice
/// for cancel / logout / remove flows instead of bespoke [AlertDialog]s.
Future<bool> showPayspinConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: Colors.transparent,
    transitionDuration: PayspinMotion.slow,
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, __) {
      final reduced = PayspinMotion.reduced(context);
      final enter = CurvedAnimation(parent: anim, curve: PayspinMotion.easeEnter);
      final spring = CurvedAnimation(parent: anim, curve: PayspinMotion.spring);

      final body = _ConfirmBody(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      );

      Widget card = body;
      if (!reduced) {
        card = FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(enter),
            child: Transform.scale(
              scale: 0.78 + 0.22 * spring.value,
              child: body,
            ),
          ),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: anim,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.62),
              child: reduced
                  ? const SizedBox.expand()
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 16 * anim.value,
                        sigmaY: 16 * anim.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
          if (!reduced)
            FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: const Interval(0.1, 0.9)),
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (destructive ? PayspinTokens.danger : PayspinTokens.pink).withValues(alpha: 0.22 * anim.value),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          card,
        ],
      );
    },
  );
  return result ?? false;
}

class _ConfirmBody extends StatefulWidget {
  const _ConfirmBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  @override
  State<_ConfirmBody> createState() => _ConfirmBodyState();
}

class _ConfirmBodyState extends State<_ConfirmBody> with TickerProviderStateMixin {
  static const _staggerDuration = Duration(milliseconds: 680);

  late final AnimationController _stagger = AnimationController(
    vsync: this,
    duration: _staggerDuration,
  );

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = PayspinMotion.reduced(context);
      if (!reduced) {
        _stagger.forward();
        _shine.forward();
        if (widget.destructive) _pulse.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    _shine.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _staggerAnim(int step) {
    final start = (step * PayspinMotion.stagger.inMilliseconds) / _staggerDuration.inMilliseconds;
    final end = (start + 0.5).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _stagger,
      curve: Interval(start, end, curve: PayspinMotion.easeEnter),
    );
  }

  Widget _reveal(int step, Widget child, {Offset slide = const Offset(0, 0.1)}) {
    if (PayspinMotion.reduced(context)) return child;
    final anim = _staggerAnim(step);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: slide, end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  Widget _revealIcon(Widget child) {
    if (PayspinMotion.reduced(context)) return child;
    final fade = CurvedAnimation(parent: _stagger, curve: const Interval(0, 0.35, curve: PayspinMotion.easeEnter));
    final scale = CurvedAnimation(parent: _stagger, curve: const Interval(0, 0.5, curve: PayspinMotion.spring));
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.35, end: 1).animate(scale),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final accent = widget.destructive ? PayspinTokens.danger : PayspinTokens.mint;
    final heroGradient = widget.destructive
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PayspinTokens.danger.withValues(alpha: 0.22),
              PayspinTokens.pink.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PayspinTokens.pink.withValues(alpha: 0.18),
              PayspinTokens.mint.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          );

    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          PayspinGlassSurface(
            tier: PayspinGlassTier.overlay,
            borderRadius: 24,
            glow: true,
            gradientBorder: true,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hero header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  decoration: BoxDecoration(gradient: heroGradient),
                  child: Column(
                    children: [
                      if (widget.icon != null) ...[
                        _revealIcon(
                          _ConfirmHeroIcon(
                            icon: widget.icon!,
                            accent: accent,
                            destructive: widget.destructive,
                            pulse: _pulse,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _reveal(
                        1,
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colors.border),
                // Body + actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    children: [
                      _reveal(
                        2,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.glassFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.glassBorder),
                          ),
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.55,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _reveal(
                        3,
                        Column(
                          children: [
                            if (widget.destructive)
                              _DestructiveCta(
                                label: widget.confirmLabel,
                                onTap: () => Navigator.of(context).pop(true),
                              )
                            else
                              PayspinGradientPillButton(
                                label: widget.confirmLabel,
                                shimmer: true,
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            const SizedBox(height: 10),
                            _GlassCancelButton(
                              label: widget.cancelLabel,
                              onTap: () => Navigator.of(context).pop(false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // One-shot shine sweep across the card
          if (!PayspinMotion.reduced(context))
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, _) {
                    if (_shine.isDismissed || _shine.isCompleted) return const SizedBox.shrink();
                    final t = Curves.easeInOut.transform(_shine.value);
                    final streak = Colors.white.withValues(alpha: 0.14);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: FractionallySizedBox(
                        widthFactor: 0.35,
                        alignment: Alignment(-1.5 + 3 * t, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, streak, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: widget.title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (widget.destructive ? PayspinTokens.danger : PayspinTokens.pink).withValues(alpha: 0.28),
                    blurRadius: 48,
                    spreadRadius: -8,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: PayspinTokens.mint.withValues(alpha: 0.12),
                    blurRadius: 36,
                    spreadRadius: -12,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Large emblem-style icon — tri-gradient ring + breathing glow for destructive flows.
class _ConfirmHeroIcon extends StatelessWidget {
  const _ConfirmHeroIcon({
    required this.icon,
    required this.accent,
    required this.destructive,
    required this.pulse,
  });

  final IconData icon;
  final Color accent;
  final bool destructive;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);

    Widget core = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: destructive ? null : PayspinTokens.gradientTri,
        color: destructive ? null : null,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.bgElevated,
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Icon(icon, color: accent, size: 34),
      ),
    );

    if (destructive) {
      core = Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              PayspinTokens.danger.withValues(alpha: 0.9),
              PayspinTokens.pink.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: PayspinTokens.danger.withValues(alpha: 0.4),
              blurRadius: 28,
              spreadRadius: -2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bgElevated),
          child: Icon(icon, color: accent, size: 34),
        ),
      );
    }

    if (!reduced && destructive) {
      core = AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final glow = 0.12 + 0.1 * pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PayspinTokens.danger.withValues(alpha: glow),
                  blurRadius: 32 + 12 * pulse.value,
                  spreadRadius: 4 * pulse.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: core,
      );
    }

    return core;
  }
}

/// Filled destructive CTA with danger gradient glow — reads clearly as irreversible.
class _DestructiveCta extends StatefulWidget {
  const _DestructiveCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_DestructiveCta> createState() => _DestructiveCtaState();
}

class _DestructiveCtaState extends State<_DestructiveCta> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !PayspinMotion.reduced(context)) _shimmer.repeat();
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    final scale = (_pressed && !reduced) ? 0.96 : 1.0;

    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedScale(
        scale: scale,
        duration: PayspinMotion.fast,
        curve: PayspinMotion.easeEnter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4D6A), Color(0xFFD9365A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: PayspinTokens.danger.withValues(alpha: _pressed ? 0.55 : 0.42),
                blurRadius: _pressed ? 20 : 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onTap();
              },
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: PayspinTokens.btnHeightLg,
                      child: Center(
                        child: Text(
                          widget.label,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PayspinTokens.onBrand,
                          ),
                        ),
                      ),
                    ),
                    if (!reduced)
                      AnimatedBuilder(
                        animation: _shimmer,
                        builder: (context, _) {
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: FractionallySizedBox(
                                widthFactor: 0.28,
                                alignment: Alignment(-1.4 + 2.8 * _shimmer.value, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.22),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCancelButton extends StatefulWidget {
  const _GlassCancelButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_GlassCancelButton> createState() => _GlassCancelButtonState();
}

class _GlassCancelButtonState extends State<_GlassCancelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final scale = (_pressed && !reduced) ? 0.98 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: PayspinMotion.fast,
      child: Material(
        color: colors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          side: BorderSide(color: colors.glassBorder),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
