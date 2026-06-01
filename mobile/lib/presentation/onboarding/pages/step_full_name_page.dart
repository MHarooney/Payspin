import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_underline_field.dart';
import '../onboarding_cubit.dart';

class StepFullNamePage extends StatefulWidget {
  const StepFullNamePage({super.key});

  @override
  State<StepFullNamePage> createState() => _StepFullNamePageState();
}

class _StepFullNamePageState extends State<StepFullNamePage> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<OnboardingCubit>().state.fullName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final iban = cubit.state.ibanDisplay;
    final filled = _name.text.trim().contains(' ');
    return PayspinOnboardingShell(
      step: 5,
      totalSteps: 5,
      title: const Text('What\'s your first and\nlast name?'),
      onBack: () {
        final existing = GoRouterState.of(context).uri.queryParameters['existing'] == '1';
        context.go(existing ? '/onboarding/iban?existing=1' : '/onboarding/iban');
      },
      nextIcon: Icons.check_rounded,
      nextLoading: cubit.isLoading,
      onNext: !filled || cubit.isLoading
          ? null
          : () async {
              cubit.updateFullName(_name.text);
              final existing = GoRouterState.of(context).uri.queryParameters['existing'] == '1';
              final ok = await cubit.complete(alreadyRegistered: existing);
              if (!context.mounted) return;
              if (ok) {
                // Existing users are only adding another IBAN — skip the
                // celebration + app-lock setup and return to the bank list.
                if (existing) {
                  context.go('/bank-accounts');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('IBAN added')),
                  );
                } else {
                  context.go('/onboarding/success');
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(cubit.lastError ?? 'Could not complete setup')),
                );
              }
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayspinUnderlineField(
            controller: _name,
            hintText: 'First and last name',
            textCapitalization: TextCapitalization.words,
            filledTextColor: PayspinTokens.textPrimary,
            onChanged: (v) {
              cubit.updateFullName(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted, height: 1.6),
              children: [
                const TextSpan(text: 'We will use this to check whether '),
                TextSpan(text: iban, style: const TextStyle(color: PayspinTokens.textPrimary, fontWeight: FontWeight.w700)),
                const TextSpan(text: ' is in your name, so we can keep Payspin safe.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
