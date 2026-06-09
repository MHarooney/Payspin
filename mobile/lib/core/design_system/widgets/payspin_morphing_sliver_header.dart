import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
/// Scroll-driven morphing header for shell tabs.
typedef MorphingSliverHeaderBuilder = Widget Function(
  BuildContext context,
  double t,
  bool overlapsContent,
);

/// Pinned [SliverPersistentHeader] that lerps from an expanded hero to a compact
/// glass command bar as the user scrolls.
class PayspinMorphingSliverHeader extends StatelessWidget {
  const PayspinMorphingSliverHeader({
    super.key,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.builder,
    this.pinned = true,
    this.freezeCollapse = false,
    this.showAuroraHairline = true,
    this.rebuildTrigger,
  });

  /// Content height at scroll offset 0 (excludes safe-area top inset).
  final double expandedHeight;

  /// Pinned strip content height (excludes safe-area top inset).
  final double collapsedHeight;

  final MorphingSliverHeaderBuilder builder;
  final bool pinned;
  final bool freezeCollapse;
  final bool showAuroraHairline;

  /// Bumps delegate rebuild when header content changes (search, user, tab data).
  final Object? rebuildTrigger;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: _PayspinMorphingSliverHeaderDelegate(
        expandedHeight: expandedHeight,
        collapsedHeight: collapsedHeight,
        topPadding: topPadding,
        freezeCollapse: freezeCollapse,
        showAuroraHairline: showAuroraHairline,
        rebuildTrigger: rebuildTrigger,
        builder: builder,
      ),
    );
  }
}

class _PayspinMorphingSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PayspinMorphingSliverHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
    required this.freezeCollapse,
    required this.showAuroraHairline,
    required this.rebuildTrigger,
    required this.builder,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final bool freezeCollapse;
  final bool showAuroraHairline;
  final Object? rebuildTrigger;
  final MorphingSliverHeaderBuilder builder;

  static const double _glassFadeStart = 0.35;

  double get _collapseRange => (expandedHeight - collapsedHeight).clamp(0, double.infinity);

  double _shrinkT(BuildContext context, double shrinkOffset) {
    if (freezeCollapse) return 0;
    if (_collapseRange <= 0) return 0;
    final raw = (shrinkOffset / _collapseRange).clamp(0.0, 1.0);
    if (PayspinMotion.reduced(context)) return raw > 0.5 ? 1.0 : 0.0;
    return raw;
  }

  @override
  double get minExtent =>
      freezeCollapse ? expandedHeight + topPadding : collapsedHeight + topPadding;

  @override
  double get maxExtent => expandedHeight + topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = _shrinkT(context, shrinkOffset);
    final currentExtent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final contentHeight = (currentExtent - topPadding).clamp(0.0, expandedHeight);
    final glassOpacity = showAuroraHairline
        ? ((t - _glassFadeStart) / (1 - _glassFadeStart)).clamp(0.0, 1.0)
        : t.clamp(0.0, 1.0);
    final auroraOpacity = (t * 0.85).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: SizedBox(
        height: currentExtent,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            if (glassOpacity > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: collapsedHeight + topPadding,
                child: Opacity(
                  opacity: glassOpacity,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.psColors.glassFillStrong,
                          border: Border(
                            bottom: BorderSide(color: context.psColors.glassBorder, width: 1),
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            if (showAuroraHairline && auroraOpacity > 0)
              Positioned(
                left: 20,
                right: 20,
                bottom: 0,
                child: Opacity(
                  opacity: auroraOpacity,
                  child: PayspinMorphingAuroraHairline(intensity: auroraOpacity),
                ),
              ),
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: contentHeight,
              child: ClipRect(
                child: SizedBox(
                  height: contentHeight,
                  width: double.infinity,
                  child: builder(context, t, overlapsContent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PayspinMorphingSliverHeaderDelegate old) {
    return old.expandedHeight != expandedHeight ||
        old.collapsedHeight != collapsedHeight ||
        old.topPadding != topPadding ||
        old.freezeCollapse != freezeCollapse ||
        old.showAuroraHairline != showAuroraHairline ||
        old.rebuildTrigger != rebuildTrigger;
  }
}

/// Pink→mint gradient rule that intensifies as the header collapses.
class PayspinMorphingAuroraHairline extends StatelessWidget {
  const PayspinMorphingAuroraHairline({super.key, this.intensity = 1});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PayspinTokens.pink.withValues(alpha: 0.15 + 0.55 * intensity),
            PayspinTokens.mint.withValues(alpha: 0.15 + 0.55 * intensity),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: PayspinTokens.pink.withValues(alpha: 0.12 * intensity),
            blurRadius: 8,
          ),
          BoxShadow(
            color: PayspinTokens.mint.withValues(alpha: 0.10 * intensity),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

/// Lerps a value between expanded and collapsed endpoints.
double morphLerp(double t, double expanded, double collapsed) =>
    expanded + (collapsed - expanded) * t;
