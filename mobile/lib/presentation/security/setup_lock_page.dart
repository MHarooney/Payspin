import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_lock_keypad.dart';
import '../../core/design_system/widgets/payspin_passcode_dots.dart';
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

class _SetupLockPageState extends State<SetupLockPage> {
  final AppLockService _service = sl<AppLockService>();
  final AppLockController _controller = sl<AppLockController>();

  _Phase _phase = _Phase.create;
  String _first = '';
  String _entry = '';
  bool _error = false;
  bool _busy = false;
  LockCapability _cap = LockCapability.empty;

  @override
  void initState() {
    super.initState();
    _service.capability().then((c) {
      if (mounted) setState(() => _cap = c);
    });
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
      setState(() {
        _first = _entry;
        _entry = '';
        _phase = _Phase.confirm;
      });
      return;
    }
    // confirm phase
    if (_entry != _first) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = true;
      });
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
    // Leave lock disabled; user can enable later from Profile.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final showKeypad = _phase != _Phase.biometric;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _skip,
                child: Text(
                  'Set up later',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PayspinTokens.pink.withValues(alpha: 0.12),
                border: Border.all(color: colors.borderActive),
              ),
              child: Icon(
                _phase == _Phase.biometric
                    ? biometricIconFor(_cap.kind)
                    : Icons.lock_outline,
                color: PayspinTokens.mint,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
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
              PayspinPasscodeDots(
                length: AppLockService.pinLength,
                filled: _entry.length,
                error: _error,
              ),
            const Spacer(),
            if (showKeypad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PayspinLockKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    PayspinGradientPillButton(
                      label: 'Enable ${_cap.label}',
                      icon: Icon(biometricIconFor(_cap.kind),
                          color: PayspinTokens.onBrand, size: 20),
                      loading: _busy,
                      onPressed: _busy ? null : _enableBiometric,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : () => _finish(biometricEnabled: false),
                      child: Text(
                        'Use passcode only',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
