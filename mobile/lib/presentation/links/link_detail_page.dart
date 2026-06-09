import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_status_chip.dart';
import '../../core/errors/api_exception.dart';
import '../../core/l10n/payspin_localizations.dart';
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
        showPayspinSnackBar(context, apiErrorMessage(e));
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
    final confirmed = await showPayspinConfirmDialog(
      context,
      title: 'Cancel this link?',
      message: 'Anyone with the link will no longer be able to pay it. '
          'This can\'t be undone.',
      confirmLabel: 'Cancel link',
      cancelLabel: 'Keep link',
      destructive: true,
      icon: Icons.link_off,
    );
    if (!confirmed) return;
    setState(() => _cancelling = true);
    try {
      await sl<PaymentLinkRepository>().cancelLink(widget.linkId);
      if (!mounted) return;
      showPayspinSnackBar(context, 'Payment link cancelled');
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        showPayspinSnackBar(context, apiErrorMessage(e));
      }
    }
  }

  Widget _heroCard(PaymentLinkDetail link) {
    final colors = context.psColors;
    return PayspinGlassSurface(
      tier: PayspinGlassTier.hero,
      gradientBorder: true,
      glow: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((link.description ?? '').isNotEmpty) ...[
            Text(link.description!, style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted)),
            const SizedBox(height: 8),
          ],
          Text(link.amountLabel, style: GoogleFonts.raleway(fontSize: 40, fontWeight: FontWeight.w800, color: colors.textPrimary)),
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
                Text(link.usageLabel!, style: GoogleFonts.inter(color: colors.textMuted, fontWeight: FontWeight.w500, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassPillButton({required IconData icon, required String label, required VoidCallback onTap}) {
    final colors = context.psColors;
    return PayspinGlassSurface(
      tier: PayspinGlassTier.flat,
      borderRadius: PayspinTokens.radiusPill,
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.textBody, size: 18),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textBody)),
          ],
        ),
      ),
    );
  }

  Widget _copyLinkButton(String url) {
    return _glassPillButton(
      icon: Icons.link,
      label: 'Copy link',
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: url));
        if (!mounted) return;
        showPayspinSnackBar(context, 'Link copied', success: true);
      },
    );
  }

  Widget _showQrButton() {
    return _glassPillButton(
      icon: Icons.qr_code_2,
      label: 'Show QR',
      onTap: () => context.push('/links/${widget.linkId}/qr'),
    );
  }

  Widget _noPaymentsYet() {
    final colors = context.psColors;
    return PayspinGlassSurface(
      tier: PayspinGlassTier.flat,
      borderRadius: PayspinTokens.radiusCard,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.schedule, color: colors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text('No payments yet — waiting for the first.', style: GoogleFonts.inter(color: colors.textMuted))),
        ],
      ),
    );
  }

  Widget _timelineTile(PaymentRecord p, bool isLast) {
    final color = PaymentVisuals.recordStatusColor(p.status);
    final colors = context.psColors;
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
                Expanded(child: Container(width: 2, color: colors.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PayspinGlassSurface(
                tier: PayspinGlassTier.flat,
                borderRadius: PayspinTokens.radiusCard,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(child: Text(p.amountLabel, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary))),
                    PayspinStatusChip(label: p.statusLabel, color: color),
                  ],
                ),
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
      backgroundColor: context.psColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: () => context.pop()),
        title: Text(link?.description ?? 'Link', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: PayspinAmbientBackground(
        intensity: 0.7,
        child: _loading
          ? const PayspinPageLoader()
          : link == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: PayspinTokens.pink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + kToolbarHeight + 8, 24, 40),
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: PayspinTokens.danger),
                                )
                              : Text(
                                  'Cancel this link',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.danger),
                                ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('Payments', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700, color: context.psColors.textPrimary)),
                      const SizedBox(height: 16),
                      if (link.payments.isEmpty)
                        _noPaymentsYet()
                      else
                        ...List.generate(link.payments.length, (i) => _timelineTile(link.payments[i], i == link.payments.length - 1)),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.push(
                            '/support/new?contextRef=${widget.linkId}&category=PAYMENT',
                          ),
                          icon: Icon(Icons.support_agent, size: 18, color: context.psColors.textMuted),
                          label: Text(
                            context.l10n.supportNeedHelp,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.psColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
