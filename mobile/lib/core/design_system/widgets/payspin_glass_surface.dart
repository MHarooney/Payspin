import 'dart:ui';

import 'package:flutter/material.dart';

import '../motion/payspin_motion_scope.dart';
import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Glass elevation scale — the single source of depth across the app.
///
/// Higher tiers blur more, sit on denser fills, and cast deeper shadows.
/// Keep at most one *blurred* tier per visible layer for scroll performance:
/// list rows should use [flat] (tint + highlight, no real blur).
enum PayspinGlassTier {
  /// List rows / chips — tint + hairline + highlight, no backdrop blur.
  flat,

  /// Cards / tiles — light backdrop blur.
  raised,

  /// Sheets / dialogs / nav bar — denser fill, stronger blur.
  overlay,

  /// Signature surfaces (balance / IBAN hero) — gradient-tinted glass.
  hero,
}

/// Frosted glass panel: backdrop blur + translucent fill + hairline border +
/// top-edge reflection + soft depth shadow. Adapts to light/dark via
/// [PayspinSemanticColors].
///
/// Prefer this (and [PayspinGlassCard]) over ad-hoc `Container` fills so depth
/// stays consistent everywhere.
class PayspinGlassSurface extends StatefulWidget {
  const PayspinGlassSurface({
    super.key,
    required this.child,
    this.tier = PayspinGlassTier.raised,
    this.borderRadius = PayspinTokens.radiusCard,
    this.padding,
    this.blur,
    this.glow = false,
    this.border,
    this.onTap,
    this.gradientBorder = false,
    this.highlight = true,
    this.shadow = true,
    this.tilt3d,
    this.liquidSheen = true,
  });

  final Widget child;
  final PayspinGlassTier tier;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Override the tier's default blur sigma.
  final double? blur;

  /// Adds the brand pink/mint outer glow (used on hero / focused surfaces).
  final bool glow;
  final Border? border;
  final VoidCallback? onTap;

  /// Replaces the hairline border with a pink→mint gradient hairline.
  final bool gradientBorder;

  /// Top-edge inner reflection. Disable for very small surfaces.
  final bool highlight;

  /// Soft drop shadow under the panel.
  final bool shadow;

  /// Device-tilt 3D parallax + moving liquid highlight. Defaults to on for every
  /// tier except [PayspinGlassTier.flat] (list rows stay cheap). Auto-disables
  /// under Reduce Motion and where no sensor is available.
  final bool? tilt3d;

  /// Moving specular "liquid glass" highlight that pools toward the device tilt.
  final bool liquidSheen;

  double get _blur {
    if (blur != null) return blur!;
    switch (tier) {
      case PayspinGlassTier.flat:
        return 0;
      case PayspinGlassTier.raised:
        return 18;
      case PayspinGlassTier.overlay:
        return 24;
      case PayspinGlassTier.hero:
        return 22;
    }
  }

  @override
  State<PayspinGlassSurface> createState() => _PayspinGlassSurfaceState();
}

class _PayspinGlassSurfaceState extends State<PayspinGlassSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final radius = BorderRadius.circular(widget.borderRadius);

    final fill = switch (widget.tier) {
      PayspinGlassTier.overlay => colors.glassFillStrong,
      PayspinGlassTier.hero => colors.glassFill,
      _ => colors.glassFill,
    };

    final BoxBorder resolvedBorder = widget.border ??
        (widget.gradientBorder
            ? const Border.fromBorderSide(BorderSide(color: Colors.transparent, width: 1))
            : Border.all(color: colors.glassBorder, width: 1));

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: widget.gradientBorder ? null : resolvedBorder,
        gradient: widget.tier == PayspinGlassTier.hero
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PayspinTokens.pink.withValues(alpha: 0.10),
                  PayspinTokens.mint.withValues(alpha: 0.08),
                ],
              )
            : null,
      ),
      child: widget.padding != null
          ? Padding(padding: widget.padding!, child: widget.child)
          : widget.child,
    );

    // Top-edge reflection overlay — keep base [content] non-positioned so the
    // stack keeps the child's intrinsic height inside Columns.
    if (widget.highlight) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: widget.borderRadius * 2 + 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(widget.borderRadius)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.glassHighlight, colors.glassHighlight.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget panel = ClipRRect(
      borderRadius: radius,
      child: widget._blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: widget._blur, sigmaY: widget._blur),
              child: content,
            )
          : content,
    );

    // Gradient hairline border (drawn over the clipped panel).
    if (widget.gradientBorder) {
      panel = _GradientBorder(radius: radius, child: panel);
    }

    final shadows = <BoxShadow>[
      if (widget.shadow) ..._tierShadow(colors),
      if (widget.glow) ...[
        BoxShadow(color: colors.pageGlowPink, blurRadius: 36, spreadRadius: -6),
        BoxShadow(color: colors.pageGlowMint, blurRadius: 28, spreadRadius: -10),
      ],
    ];

    Widget result = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: panel,
    );

    if (widget.onTap != null) {
      result = AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: PayspinMotion.fast,
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: result,
        ),
      );
    }

    final motionEnabled =
        (widget.tilt3d ??
            widget.tier == PayspinGlassTier.overlay ||
                widget.tier == PayspinGlassTier.hero) &&
            !PayspinMotion.reduced(context);
    if (motionEnabled) {
      final sheenColor = colors.glassHighlight;
      final isLight = Theme.of(context).brightness == Brightness.light;
      result = ValueListenableBuilder<Offset>(
        valueListenable: PayspinMotionScope.of(context),
        child: result,
        builder: (context, tilt, child) {
          final parallax = Offset(tilt.dx * 6, tilt.dy * 4);
          Widget panel = Transform.translate(offset: parallax, child: child);
          if (widget.liquidSheen) {
            panel = ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  panel,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _LiquidSheen(
                        tilt: tilt,
                        color: sheenColor,
                        isLight: isLight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return panel;
        },
      );
    }

    return result;
  }

  List<BoxShadow> _tierShadow(PayspinSemanticColors colors) {
    switch (widget.tier) {
      case PayspinGlassTier.flat:
        return [BoxShadow(color: colors.glassShadow, blurRadius: 10, offset: const Offset(0, 3))];
      case PayspinGlassTier.raised:
        return [BoxShadow(color: colors.glassShadow, blurRadius: 20, offset: const Offset(0, 8))];
      case PayspinGlassTier.overlay:
        return [BoxShadow(color: colors.glassShadow, blurRadius: 32, offset: const Offset(0, 14))];
      case PayspinGlassTier.hero:
        return [BoxShadow(color: colors.glassShadow, blurRadius: 30, offset: const Offset(0, 12))];
    }
  }
}

/// Soft white "light pool" that slides toward the device tilt, selling the
/// liquid-glass refraction. Pure gradient — no shader, no blur.
class _LiquidSheen extends StatelessWidget {
  const _LiquidSheen({
    required this.tilt,
    required this.color,
    required this.isLight,
  });

  final Offset tilt;
  final Color color;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final cx = (tilt.dx * 1.3).clamp(-1.0, 1.0);
    final cy = (tilt.dy * 1.3).clamp(-1.0, 1.0);
    // Light: brand-tinted pool so the highlight reads on pale glass.
    final peak = isLight
        ? Color.lerp(
            PayspinTokens.pink.withValues(alpha: 0.22),
            PayspinTokens.mint.withValues(alpha: 0.18),
            (cx + 1) / 2,
          )!
        : color.withValues(alpha: color.a * 0.65);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(cx, cy),
            radius: 0.95,
            colors: [peak, peak.withValues(alpha: 0)],
            stops: const [0.0, 0.68],
          ),
        ),
      ),
    );
  }
}

/// Draws a pink→mint gradient ring around [child] using a shader mask cutout.
class _GradientBorder extends StatelessWidget {
  const _GradientBorder({required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RingPainter(radius: radius),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.radius});

  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [PayspinTokens.pink, PayspinTokens.mint],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}

/// Convenience: a padded [PayspinGlassSurface] for content cards.
class PayspinGlassCard extends StatelessWidget {
  const PayspinGlassCard({
    super.key,
    required this.child,
    this.tier = PayspinGlassTier.raised,
    this.padding = const EdgeInsets.all(PayspinTokens.space4),
    this.borderRadius = PayspinTokens.radiusCard,
    this.onTap,
    this.glow = false,
    this.gradientBorder = false,
  });

  final Widget child;
  final PayspinGlassTier tier;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool glow;
  final bool gradientBorder;

  @override
  Widget build(BuildContext context) {
    return PayspinGlassSurface(
      tier: tier,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      glow: glow,
      gradientBorder: gradientBorder,
      child: child,
    );
  }
}
