import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_lock_keypad.dart';
import '../../core/design_system/widgets/payspin_passcode_dots.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/security/app_lock_service.dart';

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
    required this.onForgot,
  });

  final AppLockService service;
  final VoidCallback onUnlocked;

  /// Invoked by "Forgot your passcode?" — host signs out and resets the lock.
  final VoidCallback onForgot;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _error = false;
  bool _biometricEnabled = false;
  bool _busy = false;
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
    _shake.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: PayspinAmbientBackground(
        child: Stack(
        children: [
          const Positioned.fill(
            child: PayspinRadialGlow(size: 360, animate: false, alignment: Alignment(0, -0.7)),
          ),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PayspinQuickSettings(size: 38, iconSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        'Welcome back.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                      ),
                      if (_name.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                color: colors.textMuted,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final dx = _error ? _shakeOffset(_shake.value) : 0.0;
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
                  child: PayspinPasscodeDots(
                    length: AppLockService.pinLength,
                    filled: _pin.length,
                    error: _error,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 20,
                  child: _notice != null
                      ? Text(
                          _notice!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: PayspinTokens.mustard,
                              ),
                        )
                      : null,
                ),
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _confirmForgot,
                  style: TextButton.styleFrom(
                    backgroundColor: PayspinTokens.pink.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: Text(
                    'Forgot your passcode?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PayspinTokens.pink,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _confirmForgot() async {
    final confirmed = await showPayspinConfirmDialog(
      context,
      title: 'Forgot your passcode?',
      message: 'To reset it, you\'ll be signed out and need to log in again. '
          'Your data stays safe.',
      confirmLabel: 'Sign out & reset',
      destructive: true,
      icon: Icons.lock_reset,
    );
    if (confirmed) widget.onForgot();
  }

  /// Damped horizontal oscillation for the wrong-passcode shake.
  double _shakeOffset(double t) {
    const amplitude = 10.0;
    return amplitude * (1 - t) * math.sin(t * 3 * 2 * math.pi);
  }
}
