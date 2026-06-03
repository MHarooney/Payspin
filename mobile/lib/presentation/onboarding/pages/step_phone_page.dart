import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/phone_country_codes.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_phone_input_row.dart';
import '../onboarding_cubit.dart';

class StepPhonePage extends StatefulWidget {
  const StepPhonePage({super.key});

  @override
  State<StepPhonePage> createState() => _StepPhonePageState();
}

class _StepPhonePageState extends State<StepPhonePage> {
  late final TextEditingController _phone;
  String _country = kDefaultPhoneCountryCode;

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

  /// Cold-start restore: splash may route here with an empty cubit when phone
  /// was saved but Firebase never returned a verification id.
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return PayspinOnboardingShell(
      step: 2,
      totalSteps: 5,
      title: const Text('What is your\nmobile number?'),
      subtitle:
          'We\'ll send you a verification code by text message so you can confirm that it\'s really you.',
      onBack: () => context.go('/onboarding/name'),
      onNext: _phone.text.trim().length < 6
          ? null
          : () {
              cubit.updatePhone(_phone.text);
              cubit.updateCountry(_country);
              context.go('/onboarding/otp');
            },
      child: PayspinPhoneInputRow(
        phoneController: _phone,
        selectedDialCode: _country,
        onDialCodeChanged: (dialCode) => setState(() => _country = dialCode),
        onPhoneChanged: (v) {
          cubit.updatePhone(v);
          setState(() {});
        },
      ),
    );
  }
}
