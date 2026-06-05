import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class CircleDetailPage extends StatefulWidget {
  const CircleDetailPage({super.key, required this.circleId});

  final String circleId;

  @override
  State<CircleDetailPage> createState() => _CircleDetailPageState();
}

class _CircleDetailPageState extends State<CircleDetailPage> {
  Circle? _circle;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final circle = await sl<CircleRepository>().getCircle(widget.circleId);
      if (mounted) setState(() => _circle = circle);
    } catch (e) {
      if (mounted) {
        showPayspinSnackBar(context, apiErrorMessage(e));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activate() async {
    setState(() => _acting = true);
    try {
      final circle = await sl<CircleRepository>().activateCircle(widget.circleId);
      if (mounted) setState(() => _circle = circle);
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _advance() async {
    final confirmed = await showPayspinConfirmDialog(
      context,
      title: 'Advance to the next round?',
      message: 'This closes the current payout and moves the Groepie to the next '
          'recipient. This can\'t be undone.',
      confirmLabel: 'Advance round',
      icon: Icons.fast_forward_rounded,
    );
    if (!confirmed) return;
    setState(() => _acting = true);
    try {
      final circle = await sl<CircleRepository>().advanceRound(widget.circleId);
      if (mounted) setState(() => _circle = circle);
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _contributionLink() async {
    setState(() => _acting = true);
    try {
      final url = await sl<CircleRepository>().createContributionLink(widget.circleId);
      if (!mounted) return;
      await Share.share('Contribute to ${_circle!.name}: $url');
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _copyInvite(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showPayspinSnackBar(context, 'Invite code copied');
  }

  @override
  Widget build(BuildContext context) {
    final circle = _circle;
    final colors = context.psColors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: () => context.pop()),
        title: Text(circle?.name ?? 'Groepie', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: PayspinAmbientBackground(
        intensity: 0.7,
        child: _loading
            ? const PayspinPageLoader()
            : circle == null
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: PayspinTokens.pink,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + kToolbarHeight + 8, 24, 40),
                      children: [
                        Text(circle.contributionLabel, style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('${circle.statusLabel} · ${circle.usageLabel}', style: GoogleFonts.inter(color: PayspinTokens.mint, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(circle.roundLabel, style: GoogleFonts.inter(color: colors.textMuted)),
                        if (circle.currentRecipientDisplayName != null) ...[
                          const SizedBox(height: 8),
                          Text('Current recipient: ${circle.currentRecipientDisplayName}', style: GoogleFonts.inter(color: colors.textPrimary)),
                        ],
                        if (circle.isHost && circle.inviteCode != null) ...[
                          const SizedBox(height: 20),
                          PayspinGlassSurface(
                            tier: PayspinGlassTier.raised,
                            borderRadius: 16,
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('INVITE CODE', style: GoogleFonts.inter(color: colors.textMuted, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(circle.inviteCode!, style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: PayspinTokens.mint, letterSpacing: 3)),
                                    ],
                                  ),
                                ),
                                IconButton(onPressed: () => _copyInvite(circle.inviteCode!), tooltip: 'Copy invite code', icon: Icon(Icons.copy, color: colors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (circle.canActivate)
                          PayspinGradientPillButton(label: 'Activate Groepie', loading: _acting, onPressed: _acting ? null : _activate),
                        if (circle.canCreateContributionLink) ...[
                          const SizedBox(height: 12),
                          PayspinGradientPillButton(label: 'Share contribution link', loading: _acting, onPressed: _acting ? null : _contributionLink),
                        ],
                        if (circle.canAdvance) ...[
                          const SizedBox(height: 12),
                          PayspinGradientPillButton(label: 'Advance round', loading: _acting, onPressed: _acting ? null : _advance),
                        ],
                        const SizedBox(height: 24),
                        Text('Members', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                        const SizedBox(height: 12),
                        ...circle.members.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PayspinGlassSurface(
                              tier: PayspinGlassTier.flat,
                              borderRadius: PayspinTokens.radiusCard,
                              padding: const EdgeInsets.all(14),
                              border: m.isCurrentRecipient
                                  ? Border.all(color: PayspinTokens.borderActive, width: 1)
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(child: Text(m.label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                                  Text('Payout #${m.payoutOrder + 1}', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted)),
                                ],
                              ),
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
