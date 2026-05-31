import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

class PayspinUnderlineField extends StatefulWidget {
  const PayspinUnderlineField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.obscureText = false,
    this.showVisibilityToggle = false,
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
  final bool showVisibilityToggle;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<PayspinUnderlineField> createState() => _PayspinUnderlineFieldState();
}

class _PayspinUnderlineFieldState extends State<PayspinUnderlineField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant PayspinUnderlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText && !widget.showVisibilityToggle) {
      _obscured = widget.obscureText;
    }
  }

  bool get _isObscured => widget.showVisibilityToggle ? _obscured : widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hasValue = widget.controller.text.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: widget.hintText != null ? ValueKey('field-${widget.hintText}') : null,
                    controller: widget.controller,
                    autofocus: widget.autofocus,
                    maxLength: widget.maxLength,
                    textCapitalization: widget.textCapitalization,
                    keyboardType: widget.keyboardType,
                    obscureText: _isObscured,
                    textInputAction: widget.textInputAction,
                    onChanged: widget.onChanged,
                    style: GoogleFonts.raleway(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: hasValue ? PayspinTokens.mint : PayspinTokens.textHint,
                    ),
                    cursorColor: PayspinTokens.mint,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
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
                ),
                if (widget.showVisibilityToggle) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: PayspinTokens.textMuted,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                  ),
                ],
              ],
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
