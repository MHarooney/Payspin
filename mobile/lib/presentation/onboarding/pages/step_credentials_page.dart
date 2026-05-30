import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_underline_field.dart';
import '../onboarding_cubit.dart';

class StepCredentialsPage extends StatefulWidget {
  const StepCredentialsPage({super.key});

  @override
  State<StepCredentialsPage> createState() => _StepCredentialsPageState();
}

class _StepCredentialsPageState extends State<StepCredentialsPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return PayspinOnboardingShell(
      step: 3,
      totalSteps: 5,
      title: const Text('Create your account'),
      subtitle: 'Email sign-in powers your Payspin wallet (OTP above is UI-only for now).',
      onBack: () => context.go('/onboarding/otp'),
      onNext: _email.text.contains('@') && _password.text.length >= 8
          ? () {
              cubit.updateEmail(_email.text);
              cubit.updatePassword(_password.text);
              context.go('/onboarding/connect');
            }
          : null,
      child: Column(
        children: [
          PayspinUnderlineField(
            controller: _email,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) {
              cubit.updateEmail(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          PayspinUnderlineField(
            controller: _password,
            hintText: 'Password (8+ chars)',
            obscureText: true,
            onChanged: (v) {
              cubit.updatePassword(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Your phone number is stored locally until SMS auth ships.',
            style: GoogleFonts.inter(fontSize: 12, color: PayspinTokens.textMuted),
          ),
        ],
      ),
    );
  }
}
