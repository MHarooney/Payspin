import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

class PayspinSettingsRow {
  const PayspinSettingsRow({required this.icon, required this.label, this.detail, this.onTap});

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;
}

class PayspinSettingsGroup extends StatelessWidget {
  const PayspinSettingsGroup({super.key, required this.rows});

  final List<PayspinSettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PayspinTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PayspinTokens.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: PayspinTokens.border),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: rows[i].onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: PayspinTokens.glass, borderRadius: BorderRadius.circular(10)),
                        child: Icon(rows[i].icon, size: 18, color: PayspinTokens.textPrimary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rows[i].label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: PayspinTokens.textPrimary)),
                            if (rows[i].detail != null)
                              Text(rows[i].detail!, style: GoogleFonts.inter(fontSize: 12, color: PayspinTokens.textMuted)),
                          ],
                        ),
                      ),
                      if (rows[i].onTap != null) const Icon(Icons.chevron_right, size: 16, color: PayspinTokens.textHint),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
