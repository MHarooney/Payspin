import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

class PayspinNumpad extends StatelessWidget {
  const PayspinNumpad({super.key, required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [',', '0', 'back'],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((k) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: PayspinTokens.glass,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: PayspinTokens.border),
                      ),
                      child: InkWell(
                        onTap: () => onKey(k),
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 56,
                          child: Center(
                            child: k == 'back'
                                ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 22)
                                : Text(
                                    k,
                                    style: GoogleFonts.raleway(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
