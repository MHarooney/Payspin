import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_lock_keypad.dart';
import '../../core/design_system/widgets/payspin_passcode_dots.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/notifications/push_service.dart';
import '../../core/security/app_lock_controller.dart';
import '../../core/security/app_lock_service.dart';
import 'lock_screen.dart' show biometricIconFor;

enum _Phase { create, confirm, biometric }

/// Post-registration screen that activates the app lock: create a 6-digit
/// passcode, then (smartly) offer the priority biometric — Face ID, else
/// fingerprint/Touch ID. The passcode is the universal fallback.
class SetupLockPage extends StatefulWidget {
  const SetupLockPage({super.key, this.displayName});

  final String? displayName;

  @override
  State<SetupLockPage> createState() => _SetupLockPageState();
}

class _SetupLockPageState extends State<SetupLockPage> with SingleTickerProviderStateMixin {
  final AppLockService _service = sl<AppLockService>();
  final AppLockController _controller = sl<AppLockController>();

  _Phase _phase = _Phase.create;
  String _first = '';
  String _entry = '';
  bool _error = false;
  bool _busy = false;
  bool _successPulse = false;
  bool _entered = false;
  LockCapability _cap = LockCapability.empty;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _service.capability().then((c) {
      if (mounted) setState(() => _cap = c);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  int get _journeyStep {
    switch (_phase) {
      case _Phase.create:
        return 0;
      case _Phase.confirm:
        return 1;
      case _Phase.biometric:
        return 2;
    }
  }

  String get _title {
    switch (_phase) {
      case _Phase.create:
        return 'Create a passcode';
      case _Phase.confirm:
        return 'Confirm your passcode';
      case _Phase.biometric:
        return 'Enable ${_cap.label}';
    }
  }

  String get _subtitle {
    switch (_phase) {
      case _Phase.create:
        final name = widget.displayName?.trim() ?? '';
        if (name.isNotEmpty) {
          return 'Hi $name — add a 6-digit passcode to keep Payspin secure.';
        }
        return 'Add a 6-digit passcode to lock Payspin. You\'ll use it if biometrics are unavailable.';
      case _Phase.confirm:
        return 'Re-enter your passcode to confirm.';
      case _Phase.biometric:
        return 'Unlock faster next time with ${_cap.label}. You can still use your passcode anytime.';
    }
  }

  void _onDigit(String d) {
    if (_busy || _entry.length >= AppLockService.pinLength) return;
    setState(() {
      _error = false;
      _entry += d;
    });
    if (_entry.length == AppLockService.pinLength) _commitEntry();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() {
      _error = false;
      _entry = _entry.substring(0, _entry.length - 1);
    });
  }

  Future<void> _commitEntry() async {
    if (_phase == _Phase.create) {
      HapticFeedback.selectionClick();
      if (!PayspinMotion.reduced(context)) {
        setState(() => _successPulse = true);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
      }
      setState(() {
        _first = _entry;
        _entry = '';
        _successPulse = false;
        _phase = _Phase.confirm;
      });
      return;
    }
    // confirm phase
    if (_entry != _first) {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
      if (!PayspinMotion.reduced(context)) {
        _shake.forward(from: 0);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _entry = '';
        _first = '';
        _error = false;
        _phase = _Phase.create;
      });
      return;
    }
    HapticFeedback.mediumImpact();
    if (_cap.hasBiometrics) {
      setState(() => _phase = _Phase.biometric);
    } else {
      await _finish(biometricEnabled: false);
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _busy = true);
    _controller.suspendAutoLock = true;
    final result = await _service.authenticateBiometric(
      reason: 'Confirm ${_cap.label} to enable it for Payspin',
    );
    _controller.suspendAutoLock = false;
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == BiometricResult.success) {
      await _finish(biometricEnabled: true);
    } else if (result == BiometricResult.unavailable) {
      await _finish(biometricEnabled: false);
    }
    // canceled/error/lockedOut: stay so the user can retry or skip.
  }

  Future<void> _finish({required bool biometricEnabled}) async {
    setState(() => _busy = true);
    await _service.enableLock(
      pin: _first,
      biometricEnabled: biometricEnabled,
      displayName: widget.displayName,
    );
    _controller.markEnabledUnlocked();
    if (!mounted) return;
    await sl<PushService>().requestNotificationPermission();
    if (!mounted) return;
    context.go('/home');
  }

  void _skip() {
    context.go('/home');
  }

  double _shakeOffset(double t) {
    const amplitude = 10.0;
    return amplitude * (1 - t) * math.sin(t * 3 * 2 * math.pi);
  }

  Widget _phaseTransition(Widget child) {
    if (PayspinMotion.reduced(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: PayspinMotion.spring,
      switchOutCurve: PayspinMotion.easeExit,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final showKeypad = _phase != _Phase.biometric;
    final showBiometricStep = _cap.hasBiometrics;

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
                Align(
                  alignment: Alignment.centerRight,
                  child: _SkipLaterButton(onTap: _busy ? null : _skip),
                ),
                const SizedBox(height: 4),
                _JourneyRail(
                  activeStep: _journeyStep,
                  showBiometricStep: showBiometricStep,
                ),
                const SizedBox(height: 16),
                _SetupLockHero(phase: _phase, cap: _cap),
                const SizedBox(height: 20),
                Expanded(
                  child: _phaseTransition(
                    KeyedSubtree(
                      key: ValueKey(_phase),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Text(
                                  _title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.raleway(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (showKeypad)
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (context, child) {
                                final dx = _error && !reduced ? _shakeOffset(_shake.value) : 0.0;
                                return Transform.translate(offset: Offset(dx, 0), child: child);
                              },
                              child: PayspinPasscodeDots(
                                length: AppLockService.pinLength,
                                filled: _entry.length,
                                error: _error,
                                successPulse: _successPulse,
                              ),
                            ),
                          const Spacer(),
                          if (showKeypad)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: PayspinLockKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _BiometricUpgradeCard(
                                cap: _cap,
                                busy: _busy,
                                onEnable: _enableBiometric,
                                onPasscodeOnly: () => _finish(biometricEnabled: false),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
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
}

class _SkipLaterButton extends StatefulWidget {
  const _SkipLaterButton({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_SkipLaterButton> createState() => _SkipLaterButtonState();
}

class _SkipLaterButtonState extends State<_SkipLaterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final enabled = widget.onTap != null;
    final scale = (_pressed && enabled && !reduced) ? 0.98 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Set up later',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? colors.textMuted : colors.textHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyRail extends StatelessWidget {
  const _JourneyRail({required this.activeStep, required this.showBiometricStep});

  final int activeStep;
  final bool showBiometricStep;

  static const _labels = ['Create', 'Confirm', 'Unlock'];

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final steps = showBiometricStep ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: List.generate(steps, (i) {
          final completed = i < activeStep;
          final active = i == activeStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == steps - 1 ? 0 : 4),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: PayspinMotion.easeEnter,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: completed || active ? PayspinTokens.gradientPink : null,
                      color: completed || active ? null : colors.glassFill,
                      border: completed || active ? null : Border.all(color: colors.glassBorder),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? colors.textPrimary
                          : completed
                              ? PayspinTokens.mint
                              : colors.textHint,
                    ),
                    child: Text(_labels[i]),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SetupLockHero extends StatefulWidget {
  const _SetupLockHero({required this.phase, required this.cap});

  final _Phase phase;
  final LockCapability cap;

  @override
  State<_SetupLockHero> createState() => _SetupLockHeroState();
}

class _SetupLockHeroState extends State<_SetupLockHero> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  IconData get _icon {
    if (widget.phase == _Phase.biometric) {
      return biometricIconFor(widget.cap.kind);
    }
    return Icons.lock_outline;
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
            child: Icon(_icon, color: PayspinTokens.mint, size: 32),
          ),
        ),
      );
    }

    final hero = reduced
        ? buildRing(0)
        : AnimatedBuilder(animation: _glow, builder: (context, _) => buildRing(_glow.value));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: PayspinMotion.spring,
      switchOutCurve: PayspinMotion.easeExit,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(widget.phase), child: hero),
    );
  }
}

class _BiometricUpgradeCard extends StatelessWidget {
  const _BiometricUpgradeCard({
    required this.cap,
    required this.busy,
    required this.onEnable,
    required this.onPasscodeOnly,
  });

  final LockCapability cap;
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onPasscodeOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;

    return PayspinGlassSurface(
      tier: PayspinGlassTier.raised,
      gradientBorder: true,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: PayspinTokens.gradientPink,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bg),
                child: Icon(biometricIconFor(cap.kind), color: PayspinTokens.mint, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'One tap to unlock',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable ${cap.label} for quick access. Your passcode always works as a backup.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: colors.textMuted),
          ),
          const SizedBox(height: 24),
          PayspinGradientPillButton(
            label: 'Enable ${cap.label}',
            shimmer: true,
            icon: Icon(biometricIconFor(cap.kind), color: PayspinTokens.onBrand, size: 20),
            loading: busy,
            onPressed: busy ? null : onEnable,
          ),
          const SizedBox(height: 12),
          _GlassSecondaryButton(
            label: 'Use passcode only',
            onTap: busy ? null : onPasscodeOnly,
          ),
        ],
      ),
    );
  }
}

class _GlassSecondaryButton extends StatefulWidget {
  const _GlassSecondaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_GlassSecondaryButton> createState() => _GlassSecondaryButtonState();
}

class _GlassSecondaryButtonState extends State<_GlassSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final enabled = widget.onTap != null;
    final scale = (_pressed && enabled && !reduced) ? 0.98 : 1.0;

    return AnimatedScale(
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
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: enabled ? colors.textPrimary : colors.textHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
