import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../onboarding_cubit.dart';

class StepOtpPage extends StatefulWidget {
  const StepOtpPage({super.key});

  @override
  State<StepOtpPage> createState() => _StepOtpPageState();
}

class _StepOtpPageState extends State<StepOtpPage> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final phone = cubit.state.phoneDisplay;
    return PayspinOnboardingShell(
      step: 3,
      totalSteps: 5,
      title: const Text('Enter the code'),
      subtitle: 'Sent to $phone · stub: any 6 digits (e.g. 123456)',
      onBack: () => context.go('/onboarding/phone'),
      onNext: _code.text.length != 6
          ? null
          : () {
              if (!cubit.verifyOtpCode(_code.text)) {
                setState(() => _error = 'Enter a 6-digit code');
                return;
              }
              context.go('/onboarding/credentials');
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _code,
            maxLength: 6,
            keyboardType: TextInputType.number,
            style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: PayspinTokens.mint, letterSpacing: 12),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: '······',
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
        ],
      ),
    );
  }
}
