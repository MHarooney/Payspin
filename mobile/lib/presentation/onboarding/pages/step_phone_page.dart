import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/di/injection.dart';
import '../../../core/constants/phone_country_codes.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_journey.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_phone_input_row.dart';
import '../../../core/firebase/phone_auth_service.dart';
import '../onboarding_cubit.dart';

class StepPhonePage extends StatefulWidget {
  const StepPhonePage({super.key});

  @override
  State<StepPhonePage> createState() => _StepPhonePageState();
}

class _StepPhonePageState extends State<StepPhonePage> {
  late final TextEditingController _phone;
  final PhoneAuthService _phoneAuth = sl<PhoneAuthService>();
  String _country = kDefaultPhoneCountryCode;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestoreDraft());
    final draft = context.read<OnboardingCubit>().state;
    _country = isSupportedPhoneCountryCode(draft.countryCode)
        ? draft.countryCode
        : kDefaultPhoneCountryCode;
    _phone = TextEditingController(text: draft.phone);
  }

  Future<void> _maybeRestoreDraft() async {
    final cubit = context.read<OnboardingCubit>();
    if (cubit.state.phone.trim().isNotEmpty) return;
    final progress = await cubit.restorePhoneProgress();
    if (!mounted || progress == null) return;
    setState(() {
      _country = isSupportedPhoneCountryCode(progress.countryCode)
          ? progress.countryCode
          : kDefaultPhoneCountryCode;
      _phone.text = progress.phone;
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String _e164() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    return '$_country$digits';
  }

  Future<void> _continue() async {
    final cubit = context.read<OnboardingCubit>();
    cubit.updatePhone(_phone.text);
    cubit.updateCountry(_country);

    if (!_phoneAuth.available) {
      await cubit.savePhoneProgress(codeSent: false);
      if (mounted) context.go('/onboarding/otp');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    await cubit.savePhoneProgress(codeSent: false);

    await _phoneAuth.sendCode(
      _e164(),
      onCodeSent: () async {
        await cubit.savePhoneProgress(
          verificationId: _phoneAuth.pendingVerificationId,
          codeSent: true,
        );
        if (!mounted) return;
        setState(() => _sending = false);
        context.go('/onboarding/otp');
      },
      onAutoVerified: () async {
        await cubit.savePhoneProgress(
          verificationId: _phoneAuth.pendingVerificationId,
          codeSent: true,
        );
        if (!mounted) return;
        setState(() => _sending = false);
        context.go('/onboarding/otp');
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = friendlyPhoneAuthError(message);
          _sending = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final cubit = context.read<OnboardingCubit>();
    final canContinue = isPhoneDigitsValid(_country, _phone.text) && !_sending;

    return PayspinOnboardingShell(
      journey: OnboardingJourneySpec.phone,
      title: const Text('What is your\nmobile number?'),
      subtitle: _sending
          ? 'Sending a verification code to your phone…'
          : 'We\'ll send you a verification code by text message so you can confirm that it\'s really you.',
      onBack: () => context.go('/onboarding/name'),
      nextLoading: _sending,
      onNext: canContinue ? _continue : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayspinPhoneInputRow(
            phoneController: _phone,
            selectedDialCode: _country,
            onDialCodeChanged: (dialCode) => setState(() => _country = dialCode),
            onPhoneChanged: (v) {
              cubit.updatePhone(v);
              setState(() => _error = null);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: PayspinTokens.mint.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Only used to verify it\'s you',
                  style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted, height: 1.4),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
