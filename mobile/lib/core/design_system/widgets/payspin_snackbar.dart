import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

/// Floating snack bar styled like the dark prototype (elevated card, mint accent on success).
void showPayspinSnackBar(
  BuildContext context,
  String message, {
  bool success = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: PayspinTokens.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
        side: const BorderSide(color: PayspinTokens.border),
      ),
      content: Row(
        children: [
          if (success) ...[
            const Icon(Icons.check_circle, color: PayspinTokens.mint, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: PayspinTokens.textBody, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}
