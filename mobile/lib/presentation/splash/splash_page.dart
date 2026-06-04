import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_logo.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/onboarding/onboarding_progress_store.dart';
import '../../domain/repositories/auth_repository.dart';

/// Animated brand splash shown on cold start. Plays a short logo/wordmark
/// entrance over the dark glow, then routes to the next screen:
///   1. an in-progress phone verification (see [OnboardingProgressStore]) so an
///      app restart during Firebase reCAPTCHA returns to the OTP step, else
///   2. `/home` when a stored session exists (returning user — the router then
///      sorts out empty banks), else
///   3. `/welcome` for first-time/logged-out users.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.minimumDuration = const Duration(milliseconds: 1900)});

  /// Floor for how long the brand moment stays on screen before routing.
  final Duration minimumDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.84, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  late final Animation<double> _wordmarkFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveNext());
  }

  Future<void> _resolveNext() async {
    final settle = Future<void>.delayed(widget.minimumDuration);
    var next = '/welcome';
    try {
      // Bound the storage read so a slow/hanging keychain never blocks routing.
      final progress = await sl<OnboardingProgressStore>()
          .load()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (progress?.shouldRestoreOtp == true) {
        next = '/onboarding/otp';
      } else if (progress?.shouldRestorePhone == true) {
        next = '/onboarding/phone';
      } else {
        // Returning user: a persisted JWT means we should land on home, not
        // Welcome. Bound the keychain read like above so a hang can't block.
        final hasSession = await sl<AuthRepository>()
            .hasSession()
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (hasSession) next = '/home';
      }
    } catch (_) {
      // Storage unavailable — fall back to the default route.
    }
    await settle;
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PayspinRadialGlow(size: 460)),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PayspinLogo(size: 104),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _wordmarkFade,
                      child: const PayspinGradientText(
                        'Payspin',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
