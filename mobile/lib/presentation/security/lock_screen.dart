import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_lock_keypad.dart';
import '../../core/design_system/widgets/payspin_passcode_dots.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/security/app_lock_service.dart';
import 'forgot_passcode_flow.dart';

IconData biometricIconFor(BiometricKind kind) {
  switch (kind) {
    case BiometricKind.faceId:
    case BiometricKind.faceUnlock:
      return Icons.face_retouching_natural;
    case BiometricKind.iris:
      return Icons.remove_red_eye_outlined;
    case BiometricKind.touchId:
    case BiometricKind.fingerprint:
    case BiometricKind.none:
      return Icons.fingerprint;
  }
}

/// Full-screen unlock gate. Auto-prompts the priority biometric, with the
/// passcode keypad as the universal fallback.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.service,
    required this.onUnlocked,
    required this.onPasscodeReset,
    required this.onSignOutFallback,
  });

  final AppLockService service;
  final VoidCallback onUnlocked;
  final VoidCallback onPasscodeReset;
  final VoidCallback onSignOutFallback;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _error = false;
  bool _biometricEnabled = false;
  bool _busy = false;
  bool _entered = false;
  String? _notice;
  LockCapability _cap = LockCapability.empty;
  String _name = '';

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cap = await widget.service.capability();
    final enabled = await widget.service.isBiometricEnabled();
    final name = await widget.service.displayName();
    if (!mounted) return;
    setState(() {
      _cap = cap;
      _biometricEnabled = enabled;
      _name = name ?? '';
    });
    if (enabled && cap.hasBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runBiometric());
    }
  }

  bool get _showBiometricKey => _biometricEnabled && _cap.hasBiometrics;

  String? get _greetingFirstName {
    final trimmed = _name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Future<void> _runBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    final result = await widget.service.authenticateBiometric(
      reason: 'Unlock Payspin',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case BiometricResult.success:
        widget.onUnlocked();
      case BiometricResult.lockedOut:
        setState(() => _notice = 'Biometrics locked. Enter your passcode.');
      case BiometricResult.unavailable:
        setState(() => _biometricEnabled = false);
      case BiometricResult.failedFallback:
      case BiometricResult.canceled:
      case BiometricResult.error:
        break;
    }
  }

  void _onDigit(String d) {
    if (_busy || _pin.length >= AppLockService.pinLength) return;
    setState(() {
      _error = false;
      _notice = null;
      _pin += d;
    });
    if (_pin.length == AppLockService.pinLength) _verify();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _error = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    final ok = await widget.service.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _error = true);
    if (!PayspinMotion.reduced(context)) {
      _shake.forward(from: 0);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) setState(() => _pin = '');
  }

  Future<void> _forgotPasscode() async {
    if (!mounted) return;

    final result = await showForgotPasscodeFlow(context);
    switch (result) {
      case ForgotPasscodeResult.otpVerified:
        widget.onPasscodeReset();
      case ForgotPasscodeResult.signOut:
        widget.onSignOutFallback();
      case ForgotPasscodeResult.supportSubmitted:
      case ForgotPasscodeResult.canceled:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final firstName = _greetingFirstName;

    Widget body = PayspinAmbientBackground(
      intensity: 0.65,
      child: Stack(
        children: [
          const Positioned.fill(
            child: PayspinRadialGlow(
              size: 320,
              animate: true,
              alignment: Alignment(0, -0.55),
            ),
          ),
          if (!reduced) const PayspinFinanceParticles(intensity: 0.2),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const _LockHero(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        'Welcome back.',
                        style: GoogleFonts.raleway(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (firstName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          firstName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 15, color: PayspinTokens.mint),
                        ),
                      ],
                      if (_name.isNotEmpty && firstName != _name.trim()) ...[
                        const SizedBox(height: 4),
                        Text(
                          _name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final dx = _error && !reduced ? _shakeOffset(_shake.value) : 0.0;
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
                  child: PayspinPasscodeDots(
                    length: AppLockService.pinLength,
                    filled: _pin.length,
                    error: _error,
                  ),
                ),
                const SizedBox(height: 16),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: PayspinGlassSurface(
                      tier: PayspinGlassTier.flat,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shadow: false,
                      child: Text(
                        _notice!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: PayspinTokens.mustard),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PayspinLockKeypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    biometricIcon: _showBiometricKey ? biometricIconFor(_cap.kind) : null,
                    onBiometric: _runBiometric,
                  ),
                ),
                const SizedBox(height: 12),
                _ForgotPasscodeButton(onTap: _busy ? null : _forgotPasscode),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );

    if (!reduced) {
      body = AnimatedOpacity(opacity: _entered ? 1 : 0, duration: PayspinMotion.medium, child: body);
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: body,
    );
  }

  double _shakeOffset(double t) {
    const amplitude = 10.0;
    return amplitude * (1 - t) * math.sin(t * 3 * 2 * math.pi);
  }
}

class _LockHero extends StatefulWidget {
  const _LockHero();

  @override
  State<_LockHero> createState() => _LockHeroState();
}

class _LockHeroState extends State<_LockHero> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);

    Widget buildRing(double glowT) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: PayspinTokens.gradientPink,
          boxShadow: [
            BoxShadow(
              color: PayspinTokens.mint.withValues(alpha: reduced ? 0.2 : 0.15 + 0.1 * glowT),
              blurRadius: reduced ? 16 : 20 + 8 * glowT,
              spreadRadius: reduced ? 0 : 2 * glowT,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.bg,
              border: Border.all(color: colors.glassBorder),
            ),
            child: const Icon(Icons.lock_outline, color: PayspinTokens.mint, size: 32),
          ),
        ),
      );
    }

    return reduced
        ? buildRing(0)
        : AnimatedBuilder(animation: _glow, builder: (context, _) => buildRing(_glow.value));
  }
}

class _ForgotPasscodeButton extends StatefulWidget {
  const _ForgotPasscodeButton({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_ForgotPasscodeButton> createState() => _ForgotPasscodeButtonState();
}

class _ForgotPasscodeButtonState extends State<_ForgotPasscodeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final enabled = widget.onTap != null;
    final scale = (_pressed && enabled && !reduced) ? 0.98 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedScale(
        scale: scale,
        duration: PayspinMotion.fast,
        child: Material(
          color: colors.glassFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
            side: BorderSide(color: colors.glassBorder),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Forgot your passcode?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? PayspinTokens.pink : colors.textHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
