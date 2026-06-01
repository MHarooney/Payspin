import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';
import 'payspin_underline_field.dart';

/// Form row: muted caption + prototype underline field (mint when typing).
class PayspinLabeledField extends StatelessWidget {
  const PayspinLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.filledTextColor,
    this.filledLetterSpacing = 0,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Color? filledTextColor;
  final double filledLetterSpacing;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted),
        ),
        const SizedBox(height: 8),
        PayspinUnderlineField(
          controller: controller,
          hintText: hintText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          filledTextColor: filledTextColor,
          filledLetterSpacing: filledLetterSpacing,
          autofocus: autofocus,
          onChanged: onChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
        ],
      ],
    );
  }
}
