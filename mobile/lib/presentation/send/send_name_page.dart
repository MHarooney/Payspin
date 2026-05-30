import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_underline_field.dart';
import '../../core/errors/api_exception.dart';
import '../../data/services/share_service.dart';
import '../../domain/repositories/payment_link_repository.dart';

class SendNamePage extends StatefulWidget {
  const SendNamePage({super.key, required this.amountCents, required this.amountLabel});

  final int? amountCents;
  final String amountLabel;

  @override
  State<SendNamePage> createState() => _SendNamePageState();
}

class _SendNamePageState extends State<SendNamePage> {
  final _label = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      final link = await sl<PaymentLinkRepository>().createLink(
        amountCents: widget.amountCents,
        description: _label.text.trim().isEmpty ? null : _label.text.trim(),
      );
      final share = ShareService();
      final msg = share.buildMessage(
        amountLabel: widget.amountLabel,
        description: _label.text,
        payUrl: link.payUrl,
      );
      await share.shareWhatsApp(msg);
      if (mounted) {
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = _label.text.trim().isNotEmpty;
    final left = 35 - _label.text.length;
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline, color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Requesting ${widget.amountLabel}', style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text('What is it for?', style: GoogleFonts.raleway(fontSize: 30, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PayspinUnderlineField(
                controller: _label,
                hintText: 'E.g. Dinner',
                maxLength: 35,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(alignment: Alignment.centerRight, child: Text('$left left', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: PayspinTokens.textMuted))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: filled ? null : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      child: InkWell(
                        onTap: filled && !_loading ? _send : null,
                        borderRadius: BorderRadius.circular(100),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: filled ? PayspinTokens.gradientPink : null,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: filled ? PayspinTokens.fabShadow : null,
                          ),
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.send, color: Colors.white, size: 18),
                                        const SizedBox(width: 10),
                                        Text('Share via WhatsApp', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleBtn(Icons.qr_code_2, filled, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, bool filled, VoidCallback onTap) {
    return Material(
      color: filled ? PayspinTokens.mint.withValues(alpha: 0.15) : PayspinTokens.glass,
      shape: CircleBorder(side: BorderSide(color: filled ? PayspinTokens.mint.withValues(alpha: 0.3) : PayspinTokens.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 52, height: 52, child: Icon(icon, color: filled ? PayspinTokens.mint : Colors.white)),
      ),
    );
  }
}
