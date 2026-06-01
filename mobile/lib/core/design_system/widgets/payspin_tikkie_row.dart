import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_status_chip.dart';

class PayspinTikkieRow extends StatefulWidget {
  const PayspinTikkieRow({super.key, required this.link, required this.onTap, this.tintIndex = 0});

  final PaymentLink link;
  final VoidCallback onTap;
  final int tintIndex;

  static const _tints = [Color(0x2EFC00FF), Color(0x2E07D8DD), Color(0x2EFFC408), Color(0x2E5C7AEA)];
  static const _emojis = ['🍣', '⛽', '🎁', '☕', '🍕', '🎬'];

  static String emojiFor(PaymentLink link) {
    final seed = (link.description ?? link.shortCode).hashCode;
    return _emojis[seed.abs() % _emojis.length];
  }

  @override
  State<PayspinTikkieRow> createState() => _PayspinTikkieRowState();
}

class _PayspinTikkieRowState extends State<PayspinTikkieRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    final tint = PayspinTikkieRow._tints[widget.tintIndex % PayspinTikkieRow._tints.length];
    final title = link.description?.trim().isNotEmpty == true ? link.description! : link.amountLabel;
    final status = link.completedPaymentCount > 0 ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        child: Material(
        color: PayspinTokens.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: PayspinTokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(PayspinTikkieRow.emojiFor(link), style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 15, color: PayspinTokens.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerLeft, child: PayspinStatusChip(label: status)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (link.dateLabel.isNotEmpty)
                      Text(link.dateLabel, style: GoogleFonts.inter(fontSize: 11, color: PayspinTokens.textHint)),
                    const SizedBox(height: 4),
                    Text(
                      link.amountLabel,
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 16, color: PayspinTokens.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
