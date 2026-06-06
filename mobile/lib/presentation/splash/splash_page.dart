import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/motion/payspin_motion_scope.dart';
import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/widgets/payspin_brand_mark.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/onboarding/intro_store.dart';
import '../../core/onboarding/onboarding_progress_store.dart';
import '../../domain/repositories/auth_repository.dart';

/// Animated brand splash — routes after [minimumDuration] (or earlier on tap).
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.minimumDuration = PayspinMotion.splashMinimum,
  });

  final Duration minimumDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;
  final Completer<void> _skip = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveNext());
  }

  void _skipIntro() {
    if (!_skip.isCompleted) _skip.complete();
  }

  Future<void> _resolveNext() async {
    final settle = Future<void>.delayed(widget.minimumDuration);
    var next = '/welcome';
    try {
      final progress = await sl<OnboardingProgressStore>()
          .load()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (progress?.shouldRestoreOtp == true) {
        next = '/onboarding/otp';
      } else if (progress?.shouldRestorePhone == true) {
        next = '/onboarding/phone';
      } else {
        final hasSession = await sl<AuthRepository>()
            .hasSession()
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (hasSession) {
          next = '/home';
        } else if (!await IntroStore.hasSeen()) {
          next = '/intro';
        }
      }
    } catch (_) {}

    await Future.any([settle, _skip.future]);
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final l10n = context.l10n;
    final reduced = PayspinMotion.reduced(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipIntro,
        child: Stack(
          children: [
            const Positioned.fill(child: PayspinFinanceParticles(intensity: 0.95)),
            Center(
              child: PayspinParallax(
                dx: reduced ? 0 : 14,
                dy: reduced ? 0 : 10,
                child: PayspinBrandMark.hero(
                  tagline: l10n.tagline,
                  emblemStyle: isDark ? PayspinEmblemStyle.gradient : null,
                  glowAnimate: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
