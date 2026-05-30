import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_underline_field.dart';
import '../onboarding_cubit.dart';

class StepNamePage extends StatefulWidget {
  const StepNamePage({super.key});

  @override
  State<StepNamePage> createState() => _StepNamePageState();
}

class _StepNamePageState extends State<StepNamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final draft = context.read<OnboardingCubit>().state;
    _controller = TextEditingController(text: draft.displayName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return PayspinOnboardingShell(
      step: 1,
      totalSteps: 5,
      title: const Text('What should we call you?'),
      subtitle: 'We use this name in the app. Others will see it too after they\'ve paid you.',
      onBack: () => context.go('/welcome'),
      onNext: _controller.text.trim().isEmpty
          ? null
          : () {
              cubit.updateDisplayName(_controller.text);
              context.go('/onboarding/phone');
            },
      child: PayspinUnderlineField(
        controller: _controller,
        hintText: 'Enter your name',
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onChanged: (v) {
          cubit.updateDisplayName(v);
          setState(() {});
        },
      ),
    );
  }
}
