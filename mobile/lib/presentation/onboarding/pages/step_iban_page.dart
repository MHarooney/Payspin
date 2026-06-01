import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_underline_field.dart';
import '../onboarding_cubit.dart';

class StepIbanPage extends StatefulWidget {
  const StepIbanPage({super.key});

  @override
  State<StepIbanPage> createState() => _StepIbanPageState();
}

class _StepIbanPageState extends State<StepIbanPage> {
  late final TextEditingController _iban;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iban = TextEditingController(text: context.read<OnboardingCubit>().state.iban);
  }

  @override
  void dispose() {
    _iban.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return PayspinOnboardingShell(
      step: 4,
      totalSteps: 5,
      title: const Text('Which IBAN do you want\nthe money paid into?'),
      subtitle: 'Your IBAN is only shared with people that have to pay you back.',
      onBack: () {
        final existing = GoRouterState.of(context).uri.queryParameters['existing'] == '1';
        context.go(existing ? '/home' : '/onboarding/connect');
      },
      onNext: () {
        cubit.updateIban(_iban.text);
        final err = cubit.validateIbanField();
        if (err != null) {
          setState(() => _error = err);
          return;
        }
        context.go('/onboarding/full-name');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayspinUnderlineField(
            controller: _iban,
            hintText: 'NL00 ABNA 1234 5678 90',
            filledLetterSpacing: 0.02,
            onChanged: (v) {
              cubit.updateIban(v);
              setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
            child: Text(
              'Foreign IBAN?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: PayspinTokens.textPrimary, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
