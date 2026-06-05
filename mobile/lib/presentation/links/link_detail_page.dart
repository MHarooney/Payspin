import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_status_chip.dart';
import '../../core/errors/api_exception.dart';
import '../../core/utils/payment_visuals.dart';
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
  static const _pollInterval = Duration(seconds: 5);

  PaymentLinkDetail? _link;
  bool _loading = true;
  bool _cancelling = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final link = await sl<PaymentLinkRepository>().getLink(widget.linkId);
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
      _syncPolling(link);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
        context.pop();
      }
    }
  }

  /// Poll only while a payment is still settling; stop once all are terminal.
  void _syncPolling(PaymentLinkDetail link) {
    if (link.hasPendingPayments) {
      _poll ??= Timer.periodic(_pollInterval, (_) => _refreshQuietly());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      final link = await sl<PaymentLinkRepository>().getLink(widget.linkId);
      if (!mounted) return;
      setState(() => _link = link);
      _syncPolling(link);
    } catch (_) {
      // Transient poll failure: keep the last good state, try again next tick.
    }
  }

  Future<void> _cancelLink() async {
    setState(() => _cancelling = true);
    try {
      await sl<PaymentLinkRepository>().cancelLink(widget.linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment link cancelled')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Widget _heroCard(PaymentLinkDetail link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PayspinTokens.pink.withValues(alpha: 0.14), PayspinTokens.mint.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
        border: Border.all(color: PayspinTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((link.description ?? '').isNotEmpty) ...[
            Text(link.description!, style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted)),
            const SizedBox(height: 8),
          ],
          Text(link.amountLabel, style: GoogleFonts.raleway(fontSize: 40, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              PayspinStatusChip(
                label: link.completedPaymentCount > 0 ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel,
                color: PaymentVisuals.linkStatusColor(
                  link.status,
                  hasCompletedPayments: link.completedPaymentCount > 0,
                ),
              ),
              if (link.usageLabel != null) ...[
                const SizedBox(width: 8),
                Text(link.usageLabel!, style: GoogleFonts.inter(color: PayspinTokens.textMuted, fontWeight: FontWeight.w500, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _copyLinkButton(String url) {
    return Material(
      color: PayspinTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        side: const BorderSide(color: PayspinTokens.border),
      ),
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: url));
          if (!mounted) return;
          showPayspinSnackBar(context, 'Link copied', success: true);
        },
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link, color: PayspinTokens.textBody, size: 18),
              const SizedBox(width: 10),
              Text('Copy link', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.textBody)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showQrButton() {
    return Material(
      color: PayspinTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        side: const BorderSide(color: PayspinTokens.border),
      ),
      child: InkWell(
        onTap: () => context.push('/links/${widget.linkId}/qr'),
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, color: PayspinTokens.textBody, size: 18),
              const SizedBox(width: 10),
              Text('Show QR', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.textBody)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noPaymentsYet() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PayspinTokens.bgElevated,
        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
        border: Border.all(color: PayspinTokens.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: PayspinTokens.textMuted, size: 18),
          const SizedBox(width: 12),
          Text('No payments yet — waiting for the first.', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
        ],
      ),
    );
  }

  Widget _timelineTile(PaymentRecord p, bool isLast) {
    final color = PaymentVisuals.recordStatusColor(p.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: PayspinTokens.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PayspinTokens.bgElevated,
                borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
                border: Border.all(color: PayspinTokens.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(p.amountLabel, style: const TextStyle(fontWeight: FontWeight.w700))),
                  PayspinStatusChip(label: p.statusLabel, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              : RefreshIndicator(
                  onRefresh: _load,
                  color: PayspinTokens.pink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      _heroCard(link),
                      const SizedBox(height: 24),
                      if (link.isPayable) ...[
                        PayspinGradientPillButton(
                          label: 'Share via WhatsApp',
                          icon: const Icon(Icons.send, color: PayspinTokens.onBrand, size: 18),
                          onPressed: () {
                            final share = ShareService();
                            share.shareWhatsApp(share.buildMessage(
                              amountLabel: link.amountLabel,
                              description: link.description ?? '',
                              payUrl: link.payUrl,
                            ));
                          },
                        ),
                        const SizedBox(height: 12),
                        _copyLinkButton(link.payUrl),
                        const SizedBox(height: 12),
                        _showQrButton(),
                      ],
                      if (link.canCancel) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _cancelling ? null : _cancelLink,
                          child: _cancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: PayspinTokens.pink),
                                )
                              : Text(
                                  'Cancel this link',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.pink),
                                ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('Payments', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      if (link.payments.isEmpty)
                        _noPaymentsYet()
                      else
                        ...List.generate(link.payments.length, (i) => _timelineTile(link.payments[i], i == link.payments.length - 1)),
                    ],
                  ),
                ),
    );
  }
}
