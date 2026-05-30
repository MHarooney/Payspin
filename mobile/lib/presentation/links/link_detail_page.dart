import 'dart:async';

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
                      Text(link.amountLabel, style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(link.statusLabel, style: GoogleFonts.inter(color: PayspinTokens.mint, fontWeight: FontWeight.w600)),
                          if (link.usageLabel != null) ...[
                            const SizedBox(width: 8),
                            Text('· ${link.usageLabel}', style: GoogleFonts.inter(color: PayspinTokens.textMuted, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (link.isPayable)
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
                      if (link.canCancel) ...[
                        const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      if (link.payments.isEmpty)
                        Text('No payments yet.', style: GoogleFonts.inter(color: PayspinTokens.textMuted))
                      else
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
                                Text(p.statusLabel, style: GoogleFonts.inter(fontSize: 11, color: PayspinTokens.mint)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
