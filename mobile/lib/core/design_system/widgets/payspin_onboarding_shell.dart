import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';
import 'payspin_gradient_circle_button.dart';
import 'payspin_progress_bar.dart';
import 'payspin_quick_settings.dart';

class PayspinOnboardingShell extends StatelessWidget {
  const PayspinOnboardingShell({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.onNext,
    this.nextDisabled = false,
    this.nextLoading = false,
    this.nextIcon = Icons.arrow_forward_rounded,
    required this.child,
  });

  final int step;
  final int totalSteps;
  final Widget title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final bool nextDisabled;
  final bool nextLoading;
  final IconData nextIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const Spacer(),
                  const PayspinQuickSettings(size: 34, iconSize: 18),
                  const SizedBox(width: 12),
                  PayspinStepCounter(step: step, total: totalSteps),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PayspinProgressBar(progress: step / totalSteps),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    child,
                    if (subtitle != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colors.textMuted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Align(
                alignment: Alignment.centerRight,
                child: PayspinGradientCircleButton(
                  icon: nextIcon,
                  onPressed: nextDisabled ? null : onNext,
                  loading: nextLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
