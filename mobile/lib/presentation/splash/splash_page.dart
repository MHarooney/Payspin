import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/widgets/payspin_emblem_assemble.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/onboarding/intro_store.dart';
import '../../core/onboarding/onboarding_progress_store.dart';
import '../../domain/repositories/auth_repository.dart';

/// Animated brand splash — two arrow layers assemble, then wordmark fades up.
///
/// Routes after [minimumDuration] (or earlier on tap):
///   1. in-progress OTP restore → `/onboarding/otp`
///   2. session exists → `/home`
///   3. else → `/welcome`
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.minimumDuration = PayspinMotion.splashMinimum,
  });

  final Duration minimumDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _assemble = AnimationController(
    vsync: this,
    duration: PayspinMotion.splashAssemble,
  );

  /// Wordmark enters after the emblem layers have mostly assembled.
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

  bool _navigated = false;
  final Completer<void> _skip = Completer<void>();

  @override
  void initState() {
    super.initState();
    _assemble.forward();
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
          // First launch for a signed-out user → play the intro storyboard once.
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
  void dispose() {
    _assemble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    if (reduced && _assemble.value != 1) {
      _assemble.value = 1;
    }

    final emblemStyle = context.psColors.emblemStyle;

    return Scaffold(
      backgroundColor: context.psColors.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipIntro,
        child: Stack(
          children: [
            const Positioned.fill(child: PayspinRadialGlow(size: 460)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _assemble,
                    builder: (context, _) => payspinEmblemAssembleForContext(
                      context,
                      size: 104,
                      progress: _assemble.value,
                      style: emblemStyle,
                      glow: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position: _wordmarkSlide,
                    child: FadeTransition(
                      opacity: _wordmarkFade,
                      child: const PayspinGradientText(
                        'Payspin',
                        solidWordmark: true,
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
