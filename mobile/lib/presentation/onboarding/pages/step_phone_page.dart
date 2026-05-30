import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_underline_field.dart';
import '../onboarding_cubit.dart';

class StepPhonePage extends StatefulWidget {
  const StepPhonePage({super.key});

  @override
  State<StepPhonePage> createState() => _StepPhonePageState();
}

class _StepPhonePageState extends State<StepPhonePage> {
  late final TextEditingController _phone;
  String _country = '+31';

  static const _countries = [
    ('+31', 'NL'),
    ('+49', 'DE'),
    ('+33', 'FR'),
    ('+44', 'GB'),
    ('+1', 'US'),
  ];

  @override
  void initState() {
    super.initState();
    final draft = context.read<OnboardingCubit>().state;
    _country = draft.countryCode;
    _phone = TextEditingController(text: draft.phone);
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
      title: const Text('Enter your phone number'),
      subtitle: 'We will send you a confirmation code there.',
      onBack: () => context.go('/onboarding/name'),
      onNext: _phone.text.trim().length < 6
          ? null
          : () {
              cubit.updatePhone(_phone.text);
              cubit.updateCountry(_country);
              context.go('/onboarding/otp');
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: _country,
                dropdownColor: PayspinTokens.bgElevated,
                style: GoogleFonts.inter(color: PayspinTokens.mint, fontWeight: FontWeight.w700, fontSize: 18),
                items: _countries.map((c) => DropdownMenuItem(value: c.$1, child: Text('${c.$2} ${c.$1}'))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _country = v);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PayspinUnderlineField(
                  controller: _phone,
                  hintText: '612345678',
                  keyboardType: TextInputType.phone,
                  onChanged: (v) {
                    cubit.updatePhone(v);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
