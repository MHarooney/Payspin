import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../../core/design_system/widgets/payspin_onboarding_journey.dart';
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

  bool get _showGreeting => _controller.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final cubit = context.read<OnboardingCubit>();
    final name = _controller.text.trim();

    return PayspinOnboardingShell(
      journey: OnboardingJourneySpec.name,
      title: const Text('What should we call you?'),
      subtitleBelowChild: true,
      subtitle: 'We use this name in the app. Others will see it too after they\'ve paid you.',
      onBack: () => context.go('/welcome'),
      onNext: name.isEmpty
          ? null
          : () {
              cubit.updateDisplayName(_controller.text);
              context.go('/onboarding/phone');
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayspinUnderlineField(
            controller: _controller,
            hintText: 'Enter your name',
            autofocus: true,
            caretGlow: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              cubit.updateDisplayName(v);
              setState(() {});
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showGreeting
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: PayspinGlassSurface(
                      tier: PayspinGlassTier.flat,
                      borderRadius: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Hi, $name',
                        style: GoogleFonts.raleway(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
