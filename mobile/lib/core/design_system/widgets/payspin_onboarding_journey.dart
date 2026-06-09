import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Aurora Journey chapters for onboarding.
enum OnboardingChapter { you, verify, getPaid }

/// Where the user is within the 3-chapter onboarding flow.
class OnboardingJourneySpec {
  const OnboardingJourneySpec({
    required this.chapter,
    required this.subStep,
    required this.subTotal,
  });

  final OnboardingChapter chapter;
  final int subStep;
  final int subTotal;

  int get chapterIndex => chapter.index;

  double get chapterProgress => (subStep / subTotal).clamp(0.0, 1.0);

  /// 0..1 across all three chapters.
  double get overallProgress => ((chapterIndex + chapterProgress) / 3).clamp(0.0, 1.0);

  static const name = OnboardingJourneySpec(
    chapter: OnboardingChapter.you,
    subStep: 1,
    subTotal: 1,
  );

  static const phone = OnboardingJourneySpec(
    chapter: OnboardingChapter.verify,
    subStep: 1,
    subTotal: 2,
  );

  static const otp = OnboardingJourneySpec(
    chapter: OnboardingChapter.verify,
    subStep: 2,
    subTotal: 2,
  );

  static const connect = OnboardingJourneySpec(
    chapter: OnboardingChapter.getPaid,
    subStep: 1,
    subTotal: 2,
  );

  static const iban = OnboardingJourneySpec(
    chapter: OnboardingChapter.getPaid,
    subStep: 1,
    subTotal: 2,
  );

  static const fullName = OnboardingJourneySpec(
    chapter: OnboardingChapter.getPaid,
    subStep: 2,
    subTotal: 2,
  );

  String chapterLabel(OnboardingChapter c) {
    switch (c) {
      case OnboardingChapter.you:
        return 'You';
      case OnboardingChapter.verify:
        return 'Verify';
      case OnboardingChapter.getPaid:
        return 'Get paid';
    }
  }

  String get activeChapterLabel => chapterLabel(chapter);

  String get subProgressLabel => '$subStep/$subTotal';
}

/// Three chapter orbs with connecting hairlines.
class PayspinOnboardingChapterRail extends StatelessWidget {
  const PayspinOnboardingChapterRail({super.key, required this.journey});

  final OnboardingJourneySpec journey;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    const chapters = OnboardingChapter.values;

    return Row(
      children: [
        for (var i = 0; i < chapters.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= journey.chapterIndex
                    ? PayspinTokens.mint.withValues(alpha: 0.35)
                    : colors.border,
              ),
            ),
          _ChapterOrb(
            label: journey.chapterLabel(chapters[i]),
            state: i < journey.chapterIndex
                ? _OrbState.completed
                : i == journey.chapterIndex
                    ? _OrbState.active
                    : _OrbState.upcoming,
          ),
        ],
      ],
    );
  }
}

enum _OrbState { upcoming, active, completed }

class _ChapterOrb extends StatelessWidget {
  const _ChapterOrb({required this.label, required this.state});

  final String label;
  final _OrbState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final active = state == _OrbState.active;
    final done = state == _OrbState.completed;

    Widget orb = Container(
      width: active ? 12 : 10,
      height: active ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active || done ? PayspinTokens.gradientPink : null,
        color: active || done ? null : PayspinTokens.surfaceMuted,
        boxShadow: active
            ? [
                BoxShadow(color: PayspinTokens.pink.withValues(alpha: 0.35), blurRadius: 10),
                BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.2), blurRadius: 6),
              ]
            : null,
      ),
    );

    if (done && !active) {
      orb = Icon(Icons.check, size: 10, color: PayspinTokens.mint);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        orb,
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? colors.textPrimary : colors.textMuted,
            letterSpacing: 0.02,
          ),
        ),
      ],
    );
  }
}

/// Segmented progress: three chapters, animated fill within active segment.
class PayspinOnboardingChapterProgress extends StatelessWidget {
  const PayspinOnboardingChapterProgress({super.key, required this.journey});

  final OnboardingJourneySpec journey;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Row(
      children: List.generate(3, (i) {
        final fill = i < journey.chapterIndex
            ? 1.0
            : i == journey.chapterIndex
                ? journey.chapterProgress
                : 0.0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 3, right: i == 2 ? 0 : 3),
            child: _AnimatedSegment(fill: fill, trackColor: PayspinTokens.surfaceMuted),
          ),
        );
      }),
    );
  }
}

class _AnimatedSegment extends StatelessWidget {
  const _AnimatedSegment({required this.fill, required this.trackColor});

  final double fill;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            TweenAnimationBuilder<double>(
              tween: Tween(end: fill.clamp(0.0, 1.0)),
              duration: reduced ? Duration.zero : const Duration(milliseconds: 350),
              curve: PayspinMotion.easeEnter,
              builder: (_, value, __) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: const DecoratedBox(decoration: BoxDecoration(gradient: PayspinTokens.gradientPink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sub-progress label for the active chapter (e.g. "2/2").
class PayspinOnboardingSubProgress extends StatelessWidget {
  const PayspinOnboardingSubProgress({super.key, required this.journey});

  final OnboardingJourneySpec journey;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textMuted),
        children: [
          TextSpan(text: journey.activeChapterLabel),
          TextSpan(
            text: ' · ${journey.subProgressLabel}',
            style: TextStyle(color: colors.textHint, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
