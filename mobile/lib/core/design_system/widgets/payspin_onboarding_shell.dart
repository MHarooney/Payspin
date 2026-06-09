import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_ambient_background.dart';
import 'payspin_finance_particles.dart';
import 'payspin_glass_icon_button.dart';
import 'payspin_gradient_circle_button.dart';
import 'payspin_gradient_pill_button.dart';
import 'payspin_onboarding_journey.dart';
import 'payspin_staggered_entrance.dart';

enum OnboardingFooterStyle { circle, pill }

class PayspinOnboardingShell extends StatelessWidget {
  const PayspinOnboardingShell({
    super.key,
    required this.journey,
    required this.title,
    this.subtitle,
    this.subtitleBelowChild = false,
    required this.onBack,
    this.onNext,
    this.nextDisabled = false,
    this.nextLoading = false,
    this.nextIcon = Icons.arrow_forward_rounded,
    this.nextLabel = 'Continue',
    this.footerStyle = OnboardingFooterStyle.circle,
    this.footer,
    required this.child,
  });

  final OnboardingJourneySpec journey;
  final Widget title;
  final String? subtitle;
  final bool subtitleBelowChild;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final bool nextDisabled;
  final bool nextLoading;
  final IconData nextIcon;
  final String nextLabel;
  final OnboardingFooterStyle footerStyle;
  final Widget? footer;
  final Widget child;

  void _onNextTap() {
    HapticFeedback.lightImpact();
    onNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final canProceed = onNext != null && !nextDisabled;
    final footerWidget = footer ?? _buildFooter(canProceed);

    return Scaffold(
      backgroundColor: colors.bg,
      resizeToAvoidBottomInset: true,
      body: PayspinAmbientBackground(
        intensity: 0.7,
        child: Stack(
          children: [
            const PayspinFinanceParticles(intensity: 0.25),
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                        child: Row(
                          children: [
                            PayspinGlassIconButton(
                              icon: Icons.arrow_back,
                              bordered: false,
                              onPressed: onBack,
                            ),
                            const Spacer(),
                            PayspinOnboardingSubProgress(journey: journey),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: PayspinOnboardingChapterRail(journey: journey),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: PayspinOnboardingChapterProgress(journey: journey),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: PayspinStaggeredEntrance(
                          index: 0,
                          child: DefaultTextStyle(
                            style: GoogleFonts.raleway(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              height: 1.15,
                            ),
                            child: title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                24,
                                0,
                                24,
                                keyboardOpen ? 88 : 24,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: PayspinStaggeredEntrance(
                                  index: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      child,
                                      if (subtitle != null && subtitleBelowChild) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          subtitle!,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: colors.textBody,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (subtitle != null && !subtitleBelowChild) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          child: Text(
                            subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.textBody,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      if (!keyboardOpen)
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 16, 24, 28 + safeBottom),
                          child: footerWidget,
                        ),
                    ],
                  ),
                  if (keyboardOpen)
                    Positioned(
                      right: 24,
                      bottom: 16,
                      child: footerWidget,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool canProceed) {
    if (footerStyle == OnboardingFooterStyle.pill) {
      return PayspinGradientPillButton(
        label: nextLabel,
        icon: Icon(nextIcon, color: PayspinTokens.onBrand, size: 20),
        loading: nextLoading,
        onPressed: canProceed && !nextLoading ? _onNextTap : null,
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedScale(
        scale: canProceed ? 1 : 0.92,
        duration: PayspinMotion.fast,
        curve: PayspinMotion.spring,
        child: PayspinGradientCircleButton(
          icon: nextIcon,
          onPressed: nextLoading ? () {} : (canProceed ? _onNextTap : null),
          loading: nextLoading,
        ),
      ),
    );
  }
}

/// Legacy counter — kept for tests referencing step/total if needed.
class PayspinStepCounter extends StatelessWidget {
  const PayspinStepCounter({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textMuted),
        children: [
          TextSpan(text: '$step'),
          TextSpan(text: '/$total', style: TextStyle(color: colors.textHint)),
        ],
      ),
    );
  }
}
