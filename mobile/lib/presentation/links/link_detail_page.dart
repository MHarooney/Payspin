import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/errors/api_exception.dart';
import '../../data/services/share_service.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';

class LinkDetailPage extends StatefulWidget {
  const LinkDetailPage({super.key, required this.linkId});

  final String linkId;

  @override
  State<LinkDetailPage> createState() => _LinkDetailPageState();
}

class _LinkDetailPageState extends State<LinkDetailPage> {
  PaymentLinkDetail? _link;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await sl<PaymentLinkRepository>().getLink(widget.linkId);
      if (mounted) setState(() {
        _link = link;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(link?.description ?? 'Link', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayspinTokens.pink))
          : link == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(link.amountLabel, style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
                    const SizedBox(height: 8),
                    Text(link.statusLabel, style: GoogleFonts.inter(color: PayspinTokens.mint, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    PayspinGradientPillButton(
                      label: 'Share via WhatsApp',
                      onPressed: () {
                        final share = ShareService();
                        share.shareWhatsApp(share.buildMessage(
                          amountLabel: link.amountLabel,
                          description: link.description ?? '',
                          payUrl: link.payUrl,
                        ));
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('Payments', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...link.payments.map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: PayspinTokens.bgElevated,
                          borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
                          border: Border.all(color: PayspinTokens.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.amountLabel, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text(p.status, style: GoogleFonts.inter(fontSize: 11, color: PayspinTokens.mint)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
