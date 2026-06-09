import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_payment_timeline.dart';
import '../../core/design_system/widgets/payspin_share_sheet.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_staggered_entrance.dart';
import '../../core/design_system/widgets/payspin_status_chip.dart';
import '../../core/errors/api_exception.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/utils/payment_visuals.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../send/request_again_flow.dart';

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

  void _leaveDetail() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
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
        _leaveDetail();
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
    final l10n = context.l10n;
    final confirmed = await showPayspinConfirmDialog(
      context,
      title: l10n.cancelLinkTitle,
      message: l10n.cancelLinkMessage,
      confirmLabel: l10n.cancelLinkConfirm,
      cancelLabel: l10n.keepLink,
      destructive: true,
      icon: Icons.link_off,
    );
    if (!confirmed) return;
    setState(() => _cancelling = true);
    try {
      await sl<PaymentLinkRepository>().cancelLink(widget.linkId);
      if (!mounted) return;
      showPayspinSnackBar(context, l10n.linkCancelled);
      _leaveDetail();
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        showPayspinSnackBar(context, apiErrorMessage(e));
      }
    }
  }

  Widget _heroCard(PaymentLinkDetail link) {
    final colors = context.psColors;
    final statusColor = PaymentVisuals.linkStatusColor(
      link.status,
      hasCompletedPayments: link.completedPaymentCount > 0,
    );
    return PayspinStaggeredEntrance(
      index: 0,
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.hero,
        gradientBorder: true,
        glow: link.isPayable,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((link.description ?? '').isNotEmpty) ...[
              Text(link.description!, style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted)),
              const SizedBox(height: 8),
            ],
            Text(
              link.amountLabel,
              style: GoogleFonts.raleway(fontSize: 40, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                PayspinStatusChip(
                  label: link.completedPaymentCount > 0 ? 'Paid ${link.completedPaymentCount}x' : link.statusLabel,
                  color: statusColor,
                ),
                if (link.usageLabel != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    link.usageLabel!,
                    style: GoogleFonts.inter(color: colors.textMuted, fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  ShareLinkPayload _sharePayload(PaymentLinkDetail link) => ShareLinkPayload.fromLink(
        linkId: link.id,
        amountLabel: link.amountLabel,
        description: link.description,
        payUrl: link.payUrl,
        isPayable: link.isPayable,
      );

  @override
  Widget build(BuildContext context) {
    final link = _link;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.psColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: _leaveDetail),
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
                          PayspinStaggeredEntrance(
                            index: 1,
                            child: PayspinShareActionCluster(payload: _sharePayload(link)),
                          ),
                        ],
                        if (link.canRequestAgain) ...[
                          PayspinStaggeredEntrance(
                            index: 1,
                            child: PayspinGradientPillButton(
                              label: l10n.requestAgain,
                              icon: const Icon(Icons.replay_rounded, color: PayspinTokens.onBrand, size: 18),
                              onPressed: () => RequestAgainFlow.launch(context, link),
                            ),
                          ),
                        ],
                        if (link.canCancel) ...[
                          if (link.isPayable) const SizedBox(height: 4),
                          TextButton(
                            onPressed: _cancelling ? null : _cancelLink,
                          child: _cancelling
                              ? const PayspinEmblemLoader(size: 20)
                                : Text(
                                    l10n.cancelThisLink,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.danger),
                                  ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        PayspinStaggeredEntrance(
                          index: 2,
                          child: Text(
                            l10n.paymentsSection,
                            style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700, color: context.psColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PayspinPaymentTimeline(payments: link.payments),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => context.push(
                              '/support/new?contextRef=${widget.linkId}&category=PAYMENT',
                            ),
                            icon: Icon(Icons.support_agent, size: 18, color: context.psColors.textMuted),
                            label: Text(
                              l10n.supportNeedHelp,
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
