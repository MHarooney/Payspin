import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_onboarding_journey.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_underline_field.dart';
import '../../../domain/validators/iban_validator.dart';
import '../onboarding_cubit.dart';

class _IbanSpacerFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(' ', '').toUpperCase();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(raw[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class StepIbanPage extends StatefulWidget {
  const StepIbanPage({super.key});

  @override
  State<StepIbanPage> createState() => _StepIbanPageState();
}

class _StepIbanPageState extends State<StepIbanPage> {
  late final TextEditingController _iban;
  String? _error;

  bool get _foreign => GoRouterState.of(context).uri.queryParameters['foreign'] == '1';
  bool get _existing => GoRouterState.of(context).uri.queryParameters['existing'] == '1';

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

  bool get _ibanValid => IbanValidator.validate(_iban.text) == null;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final cubit = context.read<OnboardingCubit>();

    return PayspinOnboardingShell(
      journey: OnboardingJourneySpec.iban,
      title: Text(_foreign ? 'Enter your foreign IBAN' : 'Which IBAN do you want\nthe money paid into?'),
      subtitle: _foreign
          ? 'International IBANs are supported. Enter the full number including country code.'
          : 'Your IBAN is only shared with people that have to pay you back.',
      onBack: () => context.go(_existing ? '/bank-accounts' : '/onboarding/connect'),
      onNext: _iban.text.trim().isEmpty
          ? null
          : () {
              cubit.updateIban(_iban.text);
              final err = cubit.validateIbanField();
              if (err != null) {
                setState(() => _error = err);
                return;
              }
              context.go(_existing ? '/onboarding/full-name?existing=1' : '/onboarding/full-name');
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayspinUnderlineField(
            controller: _iban,
            hintText: 'NL00 ABNA 1234 5678 90',
            filledLetterSpacing: 0.02,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
              _IbanSpacerFormatter(),
            ],
            trailing: _ibanValid
                ? const Icon(Icons.check_circle_rounded, color: PayspinTokens.mint, size: 22)
                : null,
            onChanged: (v) {
              cubit.updateIban(v);
              setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
          ],
          if (!_foreign) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(_existing
                  ? '/onboarding/iban?existing=1&foreign=1'
                  : '/onboarding/iban?foreign=1'),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
              child: Text(
                'Foreign IBAN?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
