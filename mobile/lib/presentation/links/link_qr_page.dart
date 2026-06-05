import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_branded_qr.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_status_chip.dart';
import '../../core/errors/api_exception.dart';
import '../../core/utils/payment_visuals.dart';
import '../../data/services/share_service.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';

/// In-person payer QR screen (P07). Shows a Payspin-branded QR that encodes the
/// link's `payUrl`, so a payer can scan and pay without WhatsApp.
class LinkQrPage extends StatefulWidget {
  const LinkQrPage({super.key, required this.linkId});

  final String linkId;

  @override
  State<LinkQrPage> createState() => _LinkQrPageState();
}

class _LinkQrPageState extends State<LinkQrPage> {
  PaymentLink? _link;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await sl<PaymentLinkRepository>().getLink(widget.linkId);
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        showPayspinSnackBar(context, apiErrorMessage(e));
        context.pop();
      }
    }
  }

  String? _validityLabel(PaymentLink link) {
    final raw = link.expiresAt;
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final days = parsed.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Valid for less than a day';
    return 'Valid for $days more day${days == 1 ? '' : 's'}';
  }

  void _shareAgain(PaymentLink link) {
    final share = ShareService();
    share.shareWhatsApp(share.buildMessage(
      amountLabel: link.amountLabel,
      description: link.description ?? '',
      payUrl: link.payUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          link?.description?.trim().isNotEmpty == true
              ? link!.description!
              : 'Scan to pay',
          style: GoogleFonts.raleway(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayspinTokens.pink))
          : link == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    children: [
                      Text(
                        '${link.amountLabel} via Payspin',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: PayspinTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PayspinStatusChip(
                        label: link.completedPaymentCount > 0
                            ? 'Paid ${link.completedPaymentCount}x'
                            : link.statusLabel,
                        color: PaymentVisuals.linkStatusColor(
                          link.status,
                          hasCompletedPayments: link.completedPaymentCount > 0,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(child: PayspinBrandedQr(data: link.payUrl)),
                      const SizedBox(height: 28),
                      if (_validityLabel(link) != null)
                        Text(
                          _validityLabel(link)!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PayspinTokens.textMuted,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'pay.payspin.io/${link.shortCode}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: PayspinTokens.textHint,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (link.isPayable)
                        PayspinGradientPillButton(
                          label: 'Share again',
                          icon: const Icon(Icons.share, color: PayspinTokens.onBrand, size: 18),
                          onPressed: () => _shareAgain(link),
                        ),
                    ],
                  ),
                ),
    );
  }
}
