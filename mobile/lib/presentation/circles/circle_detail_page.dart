import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _advance() async {
    setState(() => _acting = true);
    try {
      final circle = await sl<CircleRepository>().advanceRound(widget.circleId);
      if (mounted) setState(() => _circle = circle);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _copyInvite(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied')));
  }

  @override
  Widget build(BuildContext context) {
    final circle = _circle;
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(circle?.name ?? 'Groepie', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayspinTokens.pink))
          : circle == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: PayspinTokens.pink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(circle.contributionLabel, style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
                      const SizedBox(height: 8),
                      Text('${circle.statusLabel} · ${circle.usageLabel}', style: GoogleFonts.inter(color: PayspinTokens.mint, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(circle.roundLabel, style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
                      if (circle.currentRecipientDisplayName != null) ...[
                        const SizedBox(height: 8),
                        Text('Current recipient: ${circle.currentRecipientDisplayName}', style: GoogleFonts.inter(color: PayspinTokens.textPrimary)),
                      ],
                      if (circle.isHost && circle.inviteCode != null) ...[
                        const SizedBox(height: 20),
                        Text('Invite code', style: GoogleFonts.inter(color: PayspinTokens.textMuted, fontSize: 12)),
                        Row(
                          children: [
                            Text(circle.inviteCode!, style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: PayspinTokens.mint, letterSpacing: 3)),
                            IconButton(onPressed: () => _copyInvite(circle.inviteCode!), icon: const Icon(Icons.copy, color: PayspinTokens.textMuted)),
                          ],
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
                      Text('Members', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...circle.members.map(
                        (m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: PayspinTokens.bgElevated,
                            borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
                            border: Border.all(color: m.isCurrentRecipient ? PayspinTokens.borderActive : PayspinTokens.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text('Payout #${m.payoutOrder + 1}', style: GoogleFonts.inter(fontSize: 11, color: PayspinTokens.textMuted)),
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
