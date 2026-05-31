import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_otp_boxes.dart';
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
      subtitle:
          'Phone verification is coming soon — this step is a preview for $phone. Enter any 6 digits to continue.',
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
          PayspinOtpBoxes(
            controller: _code,
            hasError: _error != null,
            onChanged: (_) => setState(() => _error = null),
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
