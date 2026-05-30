import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

class PayspinUnderlineField extends StatelessWidget {
  const PayspinUnderlineField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? maxLength;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasValue = controller.text.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: hintText != null ? ValueKey('field-$hintText') : null,
              controller: controller,
              autofocus: autofocus,
              maxLength: maxLength,
              textCapitalization: textCapitalization,
              keyboardType: keyboardType,
              obscureText: obscureText,
              textInputAction: textInputAction,
              onChanged: onChanged,
              style: GoogleFonts.raleway(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: hasValue ? PayspinTokens.mint : PayspinTokens.textHint,
              ),
              cursorColor: PayspinTokens.mint,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.raleway(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: PayspinTokens.textHint,
                ),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: hasValue ? PayspinTokens.borderActive : Colors.white.withValues(alpha: 0.12),
            ),
          ],
        );
      },
    );
  }
}
