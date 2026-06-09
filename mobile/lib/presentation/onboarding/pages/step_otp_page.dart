import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/injection.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_journey.dart';
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
  bool _successFlash = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  bool get _real => _phoneAuth.available;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _code.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _bootstrap() async {
    final cubit = context.read<OnboardingCubit>();

    if (cubit.state.phone.trim().isEmpty) {
      final progress = await cubit.restorePhoneProgress();
      if (!mounted || progress == null) return;
      if (progress.verificationId != null && progress.codeSent) {
        _phoneAuth.restorePendingVerification(progress.verificationId!);
        setState(() => _codeSent = true);
        _startResendCountdown();
      }
      return;
    }

    if (_real && _phoneAuth.canConfirmCode) {
      setState(() => _codeSent = true);
      _startResendCountdown();
    }
  }

  String _e164() {
    final draft = context.read<OnboardingCubit>().state;
    final digits = draft.phone.replaceAll(RegExp(r'\D'), '');
    return '${draft.countryCode}$digits';
  }

  Future<void> _sendCode({bool forceResending = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await _phoneAuth.sendCode(
      _e164(),
      forceResending: forceResending,
      onCodeSent: () async {
        final cubit = context.read<OnboardingCubit>();
        await cubit.savePhoneProgress(
          verificationId: _phoneAuth.pendingVerificationId,
          codeSent: true,
        );
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _busy = false;
        });
        _startResendCountdown();
      },
      onAutoVerified: () {
        if (mounted) _onVerified();
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = friendlyPhoneAuthError(message);
          _busy = false;
        });
      },
    );
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
      await cubit.clearPhoneProgress();
      if (!mounted) return;
      setState(() => _successFlash = true);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
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

    if (!cubit.verifyOtpCode(_code.text)) {
      setState(() => _error = 'Enter a 6-digit code');
      return;
    }
    await _onVerified();
  }

  Future<void> _goBack() async {
    await context.read<OnboardingCubit>().clearPhoneProgress();
    if (mounted) context.go('/onboarding/phone');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final masked = cubit.state.phoneMasked;
    final subtitle = !_real
        ? 'Phone verification is coming soon — this step is a preview for $masked. Enter any 6 digits to continue.'
        : _codeSent
            ? 'Enter the 6-digit code we sent to $masked.'
            : 'Tap Send code to receive a text message at $masked.';

    return Stack(
      children: [
        PayspinOnboardingShell(
          journey: OnboardingJourneySpec.otp,
          title: const Text('Enter the code'),
          subtitle: subtitle,
          onBack: _goBack,
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
                PayspinOtpResendButton(
                  secondsRemaining: _resendSeconds,
                  onPressed: _busy ? null : () => _sendCode(forceResending: _codeSent),
                ),
              ],
            ],
          ),
        ),
        if (_successFlash)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _successFlash ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: ColoredBox(color: PayspinTokens.mint.withValues(alpha: 0.18)),
              ),
            ),
          ),
      ],
    );
  }
}
