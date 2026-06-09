import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_accent_circle_button.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_flow_header.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_iban_tile.dart';
import '../../core/design_system/widgets/payspin_share_sheet.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_staggered_entrance.dart';
import '../../core/design_system/widgets/payspin_underline_field.dart';
import '../../core/errors/api_exception.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../data/services/share_service.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../../domain/repositories/payment_link_repository.dart';

class SendNamePage extends StatefulWidget {
  const SendNamePage({
    super.key,
    required this.amountCents,
    required this.amountLabel,
    this.initialDescription = '',
  });

  final int? amountCents;
  final String amountLabel;
  final String initialDescription;

  @override
  State<SendNamePage> createState() => _SendNamePageState();
}

class _SendNamePageState extends State<SendNamePage> {
  final _label = TextEditingController();
  bool _loading = false;
  List<BankAccount> _accounts = const [];
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDescription.trim();
    if (initial.isNotEmpty) {
      _label.text = initial;
    }
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await sl<BankAccountRepository>().listAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selectedAccountId = accounts.isEmpty
            ? null
            : accounts.firstWhere((a) => a.isPrimary, orElse: () => accounts.first).id;
      });
    } catch (_) {
      // Account selection is optional; the backend falls back to the primary.
    }
  }

  BankAccount? get _selectedAccount {
    if (_accounts.isEmpty) return null;
    return _accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => _accounts.first,
    );
  }

  String? get _description {
    final trimmed = _label.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickAccount() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.psColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                context.l10n.payInto,
                style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800, color: context.psColors.textPrimary),
              ),
            ),
            for (final account in _accounts)
              PayspinIbanTile(
                ibanLast4: account.ibanLast4,
                accountHolder: account.accountHolder,
                bankName: account.bankName,
                isPrimary: account.isPrimary,
                selected: account.id == _selectedAccountId,
                onTap: () => Navigator.pop(ctx, account.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _selectedAccountId = chosen);
  }

  void _stopLoading() {
    if (mounted) setState(() => _loading = false);
  }

  Future<PaymentLink?> _createLink() async {
    if (_loading) return null;
    setState(() => _loading = true);
    try {
      return await sl<PaymentLinkRepository>().createLink(
        amountCents: widget.amountCents,
        description: _description,
        bankAccountId: _accounts.length > 1 ? _selectedAccountId : null,
      );
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
      return null;
    }
  }

  ShareLinkPayload _payloadFor(PaymentLink link) => ShareLinkPayload.fromLink(
        linkId: link.id,
        amountLabel: widget.amountLabel,
        description: _description,
        payUrl: link.payUrl,
        isPayable: link.isPayable,
      );

  Future<void> _shareWhatsApp() async {
    final link = await _createLink();
    if (!mounted) return;
    if (link == null) {
      _stopLoading();
      return;
    }
    final share = ShareService();
    final msg = share.buildMessage(
      amountLabel: widget.amountLabel,
      description: _label.text,
      payUrl: link.payUrl,
    );
    try {
      await share.shareWhatsApp(msg, context: context);
    } catch (_) {
      if (mounted) {
        showPayspinSnackBar(
          context,
          'Link created. WhatsApp is not on this device — open Home to copy or share the link.',
        );
      }
    }
    HapticFeedback.mediumImpact();
    if (mounted) {
      _stopLoading();
      context.go('/links/${link.id}');
    }
  }

  Future<void> _saveLink() async {
    final link = await _createLink();
    if (!mounted) return;
    if (link == null) {
      _stopLoading();
      return;
    }
    HapticFeedback.mediumImpact();
    showPayspinSnackBar(context, context.l10n.linkSaved, success: true);
    context.go('/links/${link.id}');
  }

  Future<void> _createAndShowQr() async {
    final link = await _createLink();
    if (!mounted) return;
    if (link == null) {
      _stopLoading();
      return;
    }
    HapticFeedback.mediumImpact();
    context.go('/links/${link.id}/qr');
  }

  Future<void> _openMoreSharing() async {
    final link = await _createLink();
    if (!mounted) return;
    if (link == null) {
      _stopLoading();
      return;
    }
    HapticFeedback.mediumImpact();
    await showPayspinShareSheet(context, payload: _payloadFor(link));
    if (mounted) {
      _stopLoading();
      context.go('/links/${link.id}');
    }
  }

  Widget _buildAccountSelector() {
    final account = _selectedAccount;
    if (account == null) return const SizedBox.shrink();
    final colors = context.psColors;
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        child: Material(
          color: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: _loading ? null : _pickAccount,
            borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Icon(Icons.credit_card_outlined, size: 18, color: colors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.payInto, style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          '•••• ${account.ibanLast4}',
                          style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Text(context.l10n.change, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: PayspinTokens.mint)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveLinkButton() {
    final colors = context.psColors;
    final l10n = context.l10n;
    return PayspinGlassSurface(
      tier: PayspinGlassTier.flat,
      borderRadius: PayspinTokens.radiusPill,
      onTap: _loading ? null : _saveLink,
      child: SizedBox(
        height: PayspinTokens.btnHeightLg,
        child: Center(
          child: _loading
              ? const PayspinEmblemLoader(size: 22)
              : Text(
                  l10n.saveLink,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = 35 - _label.text.length;
    final colors = context.psColors;
    final l10n = context.l10n;
    final counterColor = left <= 5 ? PayspinTokens.pink : colors.textMuted;
    final actionsEnabled = !_loading;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PayspinFlowHeader(onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.sendRequesting(widget.amountLabel),
                style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                l10n.sendWhatFor,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PayspinUnderlineField(
                controller: _label,
                hintText: l10n.sendForHint,
                maxLength: 140,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_accounts.length > 1) _buildAccountSelector(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.sendCharsLeft(left),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: counterColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PayspinStaggeredEntrance(
                    index: 0,
                    child: PayspinGradientPillButton(
                      label: l10n.sendViaWhatsApp,
                      loading: _loading,
                      onPressed: actionsEnabled ? _shareWhatsApp : null,
                      icon: const Icon(Icons.send, color: PayspinTokens.onBrand, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PayspinStaggeredEntrance(
                    index: 1,
                    child: Row(
                      children: [
                        Expanded(child: _saveLinkButton()),
                        const SizedBox(width: 10),
                        PayspinAccentCircleButton(
                          icon: Icons.qr_code_2,
                          active: actionsEnabled,
                          loading: _loading,
                          onPressed: actionsEnabled ? _createAndShowQr : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PayspinStaggeredEntrance(
                    index: 2,
                    child: Center(
                      child: TextButton.icon(
                        onPressed: actionsEnabled ? _openMoreSharing : null,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: PayspinTokens.mint),
                        label: Text(
                          l10n.moreSharingOptions,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: PayspinTokens.mint,
                            decoration: TextDecoration.underline,
                            decorationColor: PayspinTokens.mint.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
