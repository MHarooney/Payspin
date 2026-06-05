import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/payspin_localizations.dart';
import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_emblem_assemble.dart';
import 'payspin_gradient_text.dart';

/// Animated Payspin emblem + optional wordmark — same motion language as splash.
///
/// Use [PayspinBrandMark.hero] on welcome / marketing screens,
/// [PayspinBrandMark.auth] on login, and [PayspinBrandMark.inline] in app chrome.
class PayspinBrandMark extends StatefulWidget {
  const PayspinBrandMark({
    super.key,
    required this.emblemSize,
    this.showWordmark = false,
    this.showTagline = false,
    this.showOrbit = false,
    this.shimmerWordmark = false,
    this.replayAssemble = true,
    this.loopAmbient = true,
    this.orbitRadius,
    this.wordmarkFontSize = 42,
    this.tagline,
  });

  /// Welcome / splash-scale brand block.
  factory PayspinBrandMark.hero({Key? key, String? tagline}) => PayspinBrandMark(
        key: key,
        emblemSize: 108,
        showWordmark: true,
        showTagline: tagline != null,
        showOrbit: true,
        shimmerWordmark: true,
        wordmarkFontSize: 42,
        tagline: tagline,
        orbitRadius: 92,
      );

  /// Login and other auth surfaces — emblem draws in, wordmark shimmers.
  factory PayspinBrandMark.auth({Key? key}) => PayspinBrandMark(
        key: key,
        emblemSize: 72,
        showWordmark: true,
        shimmerWordmark: true,
        showOrbit: true,
        wordmarkFontSize: 28,
        orbitRadius: 58,
      );

  /// Compact header chip — assembled emblem with subtle breathing only.
  factory PayspinBrandMark.inline({Key? key, double size = 22}) => PayspinBrandMark(
        key: key,
        emblemSize: size,
        replayAssemble: false,
        loopAmbient: true,
        showOrbit: false,
      );

  final double emblemSize;
  final bool showWordmark;
  final bool showTagline;
  final bool showOrbit;
  final bool shimmerWordmark;
  final bool replayAssemble;
  final bool loopAmbient;
  final double? orbitRadius;
  final double wordmarkFontSize;
  final String? tagline;

  @override
  State<PayspinBrandMark> createState() => _PayspinBrandMarkState();
}

class _PayspinBrandMarkState extends State<PayspinBrandMark> with TickerProviderStateMixin {
  late final AnimationController _assemble = AnimationController(
    vsync: this,
    duration: PayspinMotion.splashAssemble,
  );

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  late final Animation<double> _wordmarkFade = CurvedAnimation(
    parent: _assemble,
    curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
  );

  late final Animation<Offset> _wordmarkSlide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _assemble,
    curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
  ));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMotion());
  }

  void _startMotion() {
    if (!mounted) return;
    final reduced = PayspinMotion.reduced(context);
    if (reduced) {
      _assemble.value = 1;
      return;
    }
    if (widget.replayAssemble) {
      _assemble.forward();
    } else {
      _assemble.value = 1;
    }
    if (widget.loopAmbient) _ambient.repeat();
  }

  @override
  void dispose() {
    _assemble.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    if (reduced && _assemble.value != 1) _assemble.value = 1;

    final colors = context.psColors;
    final emblemStyle = colors.emblemStyle;
    final resolvedTagline = widget.tagline ?? (widget.showTagline ? context.l10n.tagline : null);
    final orbitRadius = widget.orbitRadius ?? widget.emblemSize * 0.85;
    final boxExtent = widget.showOrbit ? orbitRadius * 2 + 30 : widget.emblemSize;

    return AnimatedBuilder(
      animation: Listenable.merge([_assemble, _ambient]),
      builder: (context, _) {
        final breath = reduced ? 1.0 : 1 + 0.025 * math.sin(_ambient.value * 2 * math.pi);
        final appear = widget.replayAssemble ? _wordmarkFade.value : 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: boxExtent,
              height: boxExtent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.showOrbit && !reduced)
                    _BrandOrbitLayer(
                      t: _ambient.value,
                      radius: orbitRadius,
                      opacity: appear,
                    ),
                  Transform.scale(
                    scale: breath,
                    child: payspinEmblemAssembleForContext(
                      context,
                      size: widget.emblemSize,
                      progress: widget.replayAssemble ? _assemble.value : 1,
                      style: emblemStyle,
                      glow: widget.emblemSize >= 48,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showWordmark) ...[
              SizedBox(height: widget.emblemSize >= 80 ? 20 : 12),
              SlideTransition(
                position: _wordmarkSlide,
                child: FadeTransition(
                  opacity: _wordmarkFade,
                  child: _BrandShimmerWordmark(
                    animation: _ambient,
                    enabled: widget.shimmerWordmark && !reduced,
                    child: PayspinGradientText(
                      'Payspin',
                      solidWordmark: true,
                      style: TextStyle(
                        fontSize: widget.wordmarkFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.showTagline && resolvedTagline != null) ...[
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _wordmarkFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    resolvedTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BrandOrbitLayer extends StatelessWidget {
  const _BrandOrbitLayer({required this.t, required this.radius, required this.opacity});

  final double t;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final angle = t * 2 * math.pi;
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: SizedBox(
        width: radius * 2 + 30,
        height: radius * 2 + 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _coin(context, angle, PayspinTokens.pink),
            _coin(context, angle + math.pi, PayspinTokens.mint),
          ],
        ),
      ),
    );
  }

  Widget _coin(BuildContext context, double angle, Color color) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final glyphColor = isLight ? color : Colors.white;
    final offset = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    return Transform.translate(
      offset: offset,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: isLight ? 0.12 : 0.18),
          border: Border.all(color: color.withValues(alpha: 0.75), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: Center(
          child: Text(
            '\u20AC',
            style: TextStyle(color: glyphColor, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _BrandShimmerWordmark extends StatelessWidget {
  const _BrandShimmerWordmark({
    required this.child,
    required this.animation,
    required this.enabled,
  });

  final Widget child;
  final Animation<double> animation;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, ch) {
        final dx = animation.value * 2.4 - 1.2;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(dx - 0.35, 0),
            end: Alignment(dx + 0.35, 0),
            colors: const [Color(0x00FFFFFF), Color(0x80FFFFFF), Color(0x00FFFFFF)],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
          child: ch,
        );
      },
    );
  }
}
