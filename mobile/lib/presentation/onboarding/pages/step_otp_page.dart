import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/injection.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_otp_boxes.dart';
import '../../../core/firebase/phone_auth_service.dart';
import '../onboarding_cubit.dart';

class StepOtpPage extends StatefulWidget {
  const StepOtpPage({super.key});

  @override
  State<StepOtpPage> createState() => _StepOtpPageState();
}

class _StepOtpPageState extends State<StepOtpPage> {
  final _code = TextEditingController();
  final PhoneAuthService _phoneAuth = sl<PhoneAuthService>();
  String? _error;
  bool _busy = false;
  bool _codeSent = false;

  bool get _real => _phoneAuth.available;

  @override
  void initState() {
    super.initState();
    if (_real) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _e164() {
    final draft = context.read<OnboardingCubit>().state;
    final digits = draft.phone.replaceAll(RegExp(r'\D'), '');
    return '${draft.countryCode}$digits';
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await _phoneAuth.sendCode(
      _e164(),
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _busy = false;
        });
      },
      onAutoVerified: () {
        if (mounted) _onVerified();
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = _friendlyPhoneError(message);
          _busy = false;
        });
      },
    );
  }

  String _friendlyPhoneError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('blocked') || lower.contains('too many')) {
      return 'Too many attempts. Wait a few minutes, or use a test number.';
    }
    if (lower.contains('recaptcha') ||
        lower.contains('app verification') ||
        lower.contains('integrity') ||
        lower.contains('safetynet') ||
        lower.contains('missing-client-identifier')) {
      // Device-attestation failure — guidance differs per platform.
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'We couldn’t verify this device with Google Play. Register '
              'this build’s SHA-256 in Firebase and enable Play Integrity, or '
              'use a test number to continue.';
        case TargetPlatform.iOS:
          return 'We couldn’t verify this device. Update to the latest build, '
              'try a physical device, or use a test number to continue.';
        default:
          return 'We couldn’t verify this device for phone sign-in. Use a test '
              'number to continue.';
      }
    }
    if (lower.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    return message;
  }

  Future<void> _onVerified() async {
    final cubit = context.read<OnboardingCubit>();
    cubit.markPhoneVerified();
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await cubit.ensureAccountFromPhone(_phoneAuth);
    if (!mounted) return;
    if (ok) {
      context.go('/onboarding/connect');
    } else {
      setState(() {
        _error = cubit.lastError ?? 'Could not finish phone sign-in';
        _busy = false;
      });
    }
  }

  Future<void> _submit() async {
    final cubit = context.read<OnboardingCubit>();
    if (_real) {
      setState(() {
        _busy = true;
        _error = null;
      });
      final ok = await _phoneAuth.confirmCode(_code.text);
      if (!mounted) return;
      if (ok) {
        await _onVerified();
      } else {
        setState(() {
          _error = 'Incorrect code. Please try again.';
          _busy = false;
        });
      }
      return;
    }

    // Fallback: Firebase not configured — keep the preview gate.
    if (!cubit.verifyOtpCode(_code.text)) {
      setState(() => _error = 'Enter a 6-digit code');
      return;
    }
    await _onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final phone = cubit.state.phoneDisplay;
    final sending = _real && _busy && !_codeSent;
    final subtitle = !_real
        ? 'Phone verification is coming soon — this step is a preview for $phone. Enter any 6 digits to continue.'
        : sending
            ? 'Verifying your device and sending a code to $phone…'
            : 'Enter the 6-digit code we sent to $phone.';
    return PayspinOnboardingShell(
      step: 3,
      totalSteps: 5,
      title: const Text('Enter the code'),
      subtitle: subtitle,
      onBack: () => context.go('/onboarding/phone'),
      nextLoading: cubit.isLoading || _busy,
      onNext: (_busy || _code.text.length != 6 || cubit.isLoading) ? null : _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayspinOtpBoxes(
            controller: _code,
            hasError: _error != null,
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
          ],
          if (_real) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: Text(
                _codeSent ? 'Resend code' : 'Send code',
                style: const TextStyle(color: PayspinTokens.mint),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
