import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/payspin_localizations.dart';
import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_brand_mark.dart';
import 'payspin_glass_icon_button.dart';
import 'payspin_glass_surface.dart';
import 'payspin_gradient_text.dart';
import 'payspin_morphing_sliver_header.dart';

// ── Home ─────────────────────────────────────────────────────────────────────

abstract final class PayspinHomeShellHeaderMetrics {
  static const double collapsedHeight = 56;
  static const double expandedHeight = 168;
  static const double searchExtraHeight = 56;
  static const double greetingBlockHeight = 52;

  static double expanded({required bool searchOpen}) =>
      expandedHeight + (searchOpen ? searchExtraHeight : 0);
}

class PayspinHomeShellHeader extends StatelessWidget {
  const PayspinHomeShellHeader({
    super.key,
    required this.t,
    required this.searchOpen,
    required this.onToggleSearch,
    required this.onSearchChanged,
    this.greetingPhrase,
    this.userName,
    this.onScan,
    this.onProfile,
    required this.notificationBell,
  });

  final double t;
  final bool searchOpen;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final String? greetingPhrase;
  final String? userName;
  final VoidCallback? onScan;
  final VoidCallback? onProfile;
  final Widget notificationBell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final hasGreeting =
            greetingPhrase != null && greetingPhrase!.trim().isNotEmpty;
        final contentMinHeight = _homeExpandedContentMinHeight(
          hasGreeting: hasGreeting && !searchOpen,
          searchOpen: searchOpen,
        );
        final heightMorph = contentMinHeight <= maxH
            ? 0.0
            : ((contentMinHeight - maxH) /
                    (contentMinHeight - PayspinHomeShellHeaderMetrics.collapsedHeight))
                .clamp(0.0, 1.0);
        final morph = math.max(t.clamp(0.0, 1.0), heightMorph);

        const btnSize = 48.0;
        const btnGap = 4.0;
        const collapsedTrailingGap = 14.0;
        final vPad = morphLerp(morph, 12.0, 4.0);
        final bottomPad = morphLerp(morph, 8.0, 4.0);
        final toolbarHeight = morphLerp(morph, 44.0, 40.0);
        final greetingOpacity = (1 - morph * 1.75).clamp(0.0, 1.0);
        final minForGreeting = vPad +
            bottomPad +
            toolbarHeight +
            8 +
            PayspinHomeShellHeaderMetrics.greetingBlockHeight +
            (searchOpen ? 12.0 + PayspinHomeShellHeaderMetrics.searchExtraHeight : 0.0);
        final showGreeting =
            hasGreeting && maxH >= minForGreeting && greetingOpacity > 0.02;

        const emblemSize = 22.0;
        const brandGap = 8.0;
        const brandTextWidth = 78.0;
        final brandWidth = emblemSize + brandGap + brandTextWidth;
        final brandLeft = morphLerp(morph, (maxW - brandWidth) / 2, 0.0);
        final emblemScale = morphLerp(morph, 1.0, 0.92);
        final gradientWordmarkOpacity = (1 - morph * 1.8).clamp(0.0, 1.0);
        final solidWordmarkOpacity = ((morph - 0.22) / 0.45).clamp(0.0, 1.0);
        final wordmarkSize = morphLerp(morph, 18.0, 16.0);

        final scanOpacity = (1 - morph * 2.2).clamp(0.0, 1.0);
        final profileOpacity = (1 - morph * 2.2).clamp(0.0, 1.0);
        final searchTravel = ((morph - 0.18) / 0.82).clamp(0.0, 1.0);
        final searchLeftExpanded = btnSize + btnGap;
        final trailingGap = morphLerp(searchTravel, btnGap, collapsedTrailingGap);
        final searchLeftCollapsed = maxW - btnSize - trailingGap - btnSize;
        final searchLeft =
            morphLerp(searchTravel, searchLeftExpanded, searchLeftCollapsed);
        final bellRight = morphLerp(morph, btnSize + btnGap, 0.0);
        final scanLeft = morphLerp(morph, 0.0, -btnSize);

        return Padding(
          padding: EdgeInsets.fromLTRB(20, vPad, 20, bottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: toolbarHeight,
                width: maxW,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (scanOpacity > 0)
                      Positioned(
                        left: scanLeft,
                        top: (toolbarHeight - btnSize) / 2,
                        child: Opacity(
                          opacity: scanOpacity,
                          child: PayspinGlassIconButton(
                            icon: Icons.qr_code_2,
                            semanticLabel: l10n.navScanQr,
                            bordered: false,
                            onPressed: onScan ?? () => context.push('/scan'),
                          ),
                        ),
                      ),
                    Positioned(
                      left: searchLeft,
                      top: (toolbarHeight - btnSize) / 2,
                      child: PayspinGlassIconButton(
                        icon: searchOpen ? Icons.close_rounded : Icons.search,
                        semanticLabel: l10n.searchTikkies,
                        bordered: false,
                        onPressed: onToggleSearch,
                      ),
                    ),
                    Positioned(
                      left: brandLeft,
                      top: (toolbarHeight - emblemSize) / 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: emblemScale,
                            child: PayspinBrandMark.inline(
                              size: emblemSize,
                              emblemStyle: isDark ? PayspinEmblemStyle.gradient : null,
                            ),
                          ),
                          const SizedBox(width: brandGap),
                          SizedBox(
                            width: brandTextWidth,
                            height: wordmarkSize * 1.2,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                if (gradientWordmarkOpacity > 0)
                                  Opacity(
                                    opacity: gradientWordmarkOpacity,
                                    child: const PayspinGradientText(
                                      'Payspin',
                                      wordmark: true,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                if (solidWordmarkOpacity > 0)
                                  Opacity(
                                    opacity: solidWordmarkOpacity,
                                    child: Text(
                                      'Payspin',
                                      style: GoogleFonts.raleway(
                                        fontWeight: FontWeight.w800,
                                        fontSize: wordmarkSize,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: bellRight,
                      top: (toolbarHeight - btnSize) / 2,
                      child: SizedBox(
                        width: btnSize,
                        height: btnSize,
                        child: Center(child: notificationBell),
                      ),
                    ),
                    if (profileOpacity > 0)
                      Positioned(
                        right: 0,
                        top: (toolbarHeight - btnSize) / 2,
                        child: Opacity(
                          opacity: profileOpacity,
                          child: PayspinGlassIconButton(
                            icon: Icons.person_rounded,
                            semanticLabel: l10n.navProfile,
                            bordered: false,
                            onPressed: onProfile ?? () => context.go('/home/profile'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showGreeting)
                Opacity(
                  opacity: greetingOpacity,
                  child: Transform.translate(
                    offset: Offset(0, morph * -8),
                    child: Padding(
                      padding: EdgeInsets.only(top: morphLerp(morph, 8.0, 2.0)),
                      child: _HomeGreetingHero(
                        phrase: greetingPhrase!,
                        userName: userName,
                      ),
                    ),
                  ),
                ),
              if (searchOpen && morph < 0.42)
                AnimatedSize(
                  duration: reduced ? Duration.zero : PayspinMotion.fast,
                  curve: PayspinMotion.easeEnter,
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Opacity(
                      opacity: (1 - morph * 2.4).clamp(0.0, 1.0),
                      child: PayspinGlassSurface(
                        tier: PayspinGlassTier.raised,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          autofocus: true,
                          onChanged: onSearchChanged,
                          style: GoogleFonts.inter(color: colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.searchTikkies,
                            prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static double _homeExpandedContentMinHeight({
    required bool hasGreeting,
    required bool searchOpen,
  }) {
    var height = 12.0 + 44.0 + 8.0 + 12.0;
    if (hasGreeting) {
      height += 8.0 + PayspinHomeShellHeaderMetrics.greetingBlockHeight;
    }
    if (searchOpen) {
      height += 12.0 + PayspinHomeShellHeaderMetrics.searchExtraHeight;
    }
    return height;
  }
}

/// Time-of-day line + gradient first-name hero for the home tab.
class _HomeGreetingHero extends StatelessWidget {
  const _HomeGreetingHero({
    required this.phrase,
    this.userName,
  });

  final String phrase;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final name = userName?.trim();
    final hasName = name != null && name.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: hasName ? 40 : 28,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: PayspinTokens.gradientPink,
            boxShadow: [
              BoxShadow(
                color: PayspinTokens.pink.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasName)
                Text(
                  phrase,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PayspinTokens.mint.withValues(alpha: 0.92),
                    letterSpacing: 0.15,
                    height: 1.2,
                  ),
                ),
              if (hasName) ...[
                const SizedBox(height: 2),
                PayspinGradientText(
                  name,
                  style: GoogleFonts.raleway(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.02,
                  ),
                ),
              ] else
                Text(
                  phrase,
                  style: GoogleFonts.raleway(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.02,
                    color: colors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Groepies ─────────────────────────────────────────────────────────────────

abstract final class PayspinGroepiesShellHeaderMetrics {
  static const double collapsedHeight = 64;
  static const double expandedHeight = 120;
}

class PayspinGroepiesShellHeader extends StatelessWidget {
  const PayspinGroepiesShellHeader({
    super.key,
    required this.t,
    this.onCreate,
  });

  final double t;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final compact = t > 0.55;
    final orbitRadius = morphLerp(t, 18, 6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: compact
          ? Row(
              children: [
                Text(
                  'Groepies',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                PayspinGlassIconButton(
                  icon: Icons.add_rounded,
                  semanticLabel: 'Create Groepie',
                  bordered: false,
                  onPressed: onCreate ?? () => context.push('/circles/create'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Groepies',
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: colors.textPrimary,
                              letterSpacing: -0.02,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Community savings',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: PayspinTokens.mint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PayspinGlassIconButton(
                      icon: Icons.add_rounded,
                      semanticLabel: 'Create Groepie',
                      bordered: false,
                      onPressed: onCreate ?? () => context.push('/circles/create'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _GroepiesOrbitDots(radius: orbitRadius, t: t, reduced: reduced),
              ],
            ),
    );
  }
}

class _GroepiesOrbitDots extends StatelessWidget {
  const _GroepiesOrbitDots({
    required this.radius,
    required this.t,
    required this.reduced,
  });

  final double radius;
  final double t;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    if (reduced) return const SizedBox(height: 8);
    return SizedBox(
      height: 24,
      width: 72,
      child: CustomPaint(
        painter: _OrbitDotsPainter(
          radius: radius,
          phase: t * math.pi * 0.5,
        ),
      ),
    );
  }
}

class _OrbitDotsPainter extends CustomPainter {
  _OrbitDotsPainter({required this.radius, required this.phase});

  final double radius;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    const dots = 3;
    final center = Offset(12, size.height / 2);
    for (var i = 0; i < dots; i++) {
      final angle = phase + (i * 2 * math.pi / dots);
      final offset = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.35);
      final paint = Paint()
        ..color = i.isEven ? PayspinTokens.pink.withValues(alpha: 0.75) : PayspinTokens.mint.withValues(alpha: 0.75);
      final dotRadius = 2.5 + (radius / 18) * 1.0;
      canvas.drawCircle(offset, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitDotsPainter old) =>
      old.radius != radius || old.phase != phase;
}

// ── Profile ──────────────────────────────────────────────────────────────────

abstract final class PayspinProfileShellHeaderMetrics {
  static const double collapsedHeight = 56;
  /// Minimum vertical space for the full avatar hero (see [PayspinProfileShellHeader]).
  static const double expandedContentMinHeight = 224;
  static const double expandedHeight = 252;
}

class PayspinProfileShellHeader extends StatelessWidget {
  const PayspinProfileShellHeader({
    super.key,
    required this.t,
    required this.name,
    required this.initial,
    this.contact,
    this.onBack,
  });

  final double t;
  final String name;
  final String initial;
  final String? contact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final heroMinHeight = _profileHeroMinHeight(contact);
        final heightMorph = heroMinHeight <= maxH
            ? 0.0
            : ((heroMinHeight - maxH) /
                    (heroMinHeight - PayspinProfileShellHeaderMetrics.collapsedHeight))
                .clamp(0.0, 1.0);
        final morph = math.max(t.clamp(0.0, 1.0), heightMorph);

        final vPad = morphLerp(morph, 8.0, 4.0);
        final backSize = 48.0;
        final toolbarHeight = morphLerp(morph, 44.0, 40.0);
        final avatarSize = morphLerp(morph, 88.0, 32.0);
        final avatarFontSize = morphLerp(morph, 30.0, 14.0);

        final expandedAvatarLeft = (maxW - avatarSize) / 2;
        final collapsedAvatarLeft = backSize + 8;
        final avatarLeft = morphLerp(morph, expandedAvatarLeft, collapsedAvatarLeft);

        final expandedAvatarTop = toolbarHeight + 8;
        final collapsedAvatarTop = (toolbarHeight - avatarSize) / 2;
        final avatarTop = morphLerp(morph, expandedAvatarTop, collapsedAvatarTop);

        final nameOpacity = (1 - morph * 1.75).clamp(0.0, 1.0);
        final contactOpacity = (1 - morph * 2.1).clamp(0.0, 1.0);
        final titleOpacity = ((morph - 0.32) / 0.42).clamp(0.0, 1.0);
        final nameFontSize = morphLerp(morph, 22.0, 17.0);
        final nameTop = avatarTop + avatarSize + morphLerp(morph, 10.0, 6.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(20, vPad, 20, vPad),
          child: SizedBox(
            height: math.max(0, maxH - vPad * 2),
            width: maxW,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: morphLerp(morph, 0, (toolbarHeight - backSize) / 2),
                  left: 0,
                  child: PayspinGlassIconButton(
                    icon: Icons.arrow_back,
                    onPressed: onBack ?? () {},
                  ),
                ),
                Positioned(
                  left: avatarLeft,
                  top: avatarTop,
                  child: _ProfileAvatarRing(
                    size: avatarSize,
                    initial: initial,
                    fontSize: avatarFontSize,
                  ),
                ),
                if (titleOpacity > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: toolbarHeight,
                    child: Opacity(
                      opacity: titleOpacity,
                      child: Center(
                        child: Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (nameOpacity > 0)
                  Positioned(
                    top: nameTop,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: nameOpacity,
                      child: Transform.translate(
                        offset: Offset(0, morph * -6),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (contact != null &&
                    contact!.isNotEmpty &&
                    contactOpacity > 0)
                  Positioned(
                    top: nameTop + nameFontSize * 1.1 + 4,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: contactOpacity,
                      child: Transform.translate(
                        offset: Offset(0, morph * -8),
                        child: Text(
                          contact!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.2,
                            color: colors.textMuted,
                          ),
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

  /// Vertical space required for the expanded profile hero (padding included).
  static double _profileHeroMinHeight(String? contact) {
    var height = 16.0 + 44.0 + 8.0 + 88.0 + 10.0 + 24.0;
    if (contact != null && contact.trim().isNotEmpty) {
      height += 4.0 + 16.0;
    }
    return height;
  }
}

class _ProfileAvatarRing extends StatelessWidget {
  const _ProfileAvatarRing({
    required this.size,
    required this.initial,
    required this.fontSize,
  });

  final double size;
  final String initial;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PayspinTokens.gradientTri,
        boxShadow: size > 48 ? PayspinTokens.fabShadow : null,
      ),
      padding: EdgeInsets.all(size > 48 ? 4 : 2),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bg),
        padding: EdgeInsets.all(size > 48 ? 3 : 1.5),
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: PayspinTokens.gradientPink),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.raleway(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: PayspinTokens.onBrand,
            ),
          ),
        ),
      ),
    );
  }
}
