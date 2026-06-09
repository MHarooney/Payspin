import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/errors/api_exception.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../domain/entities/support_thread.dart';
import '../../domain/repositories/support_repository.dart';

class NewSupportRequestPage extends StatefulWidget {
  const NewSupportRequestPage({super.key, this.contextRef, this.initialCategory});

  final String? contextRef;
  final SupportCategory? initialCategory;

  @override
  State<NewSupportRequestPage> createState() => _NewSupportRequestPageState();
}

class _NewSupportRequestPageState extends State<NewSupportRequestPage> {
  final TextEditingController _controller = TextEditingController();
  SupportCategory? _category;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ??
        (widget.contextRef != null ? SupportCategory.payment : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final thread = await sl<SupportRepository>().createThread(
        category: _category,
        body: body,
        contextRef: widget.contextRef,
      );
      if (!mounted) return;
      // Replace this screen with the new thread so Back returns to the inbox.
      context.pushReplacement('/support/${thread.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showPayspinSnackBar(context, apiErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        title: Text(context.l10n.supportNewRequest,
            style: GoogleFonts.raleway(fontWeight: FontWeight.w800, color: colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (widget.contextRef != null) _contextBanner(),
            Text(context.l10n.supportTopicQuestion,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textMuted)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: SupportCategory.values.map(_categoryChip).toList(),
            ),
            const SizedBox(height: 24),
            PayspinGlassSurface(
              tier: PayspinGlassTier.raised,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _controller,
                minLines: 5,
                maxLines: 10,
                maxLength: 4000,
                style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: context.l10n.supportMessageHint,
                  hintStyle: GoogleFonts.inter(color: colors.textHint),
                  border: InputBorder.none,
                  counterStyle: GoogleFonts.inter(color: colors.textHint, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: colors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(context.l10n.supportSlaHint,
                      style: GoogleFonts.inter(color: colors.textHint, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PayspinGradientPillButton(
              label: context.l10n.supportSendMessage,
              loading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextBanner() {
    final colors = context.psColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.flat,
        borderRadius: PayspinTokens.radiusCard,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: PayspinTokens.mint),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Linked to ${widget.contextRef}',
                  style: GoogleFonts.inter(color: colors.textBody, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(SupportCategory c) {
    final colors = context.psColors;
    final selected = _category == c;
    return GestureDetector(
      onTap: () => setState(() => _category = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? PayspinTokens.gradientPink : null,
          color: selected ? null : colors.glassFill,
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          border: Border.all(
            color: selected ? Colors.transparent : colors.border,
            width: 1,
          ),
        ),
        child: Text(
          context.l10n.supportCategory(c.wire),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? PayspinTokens.onBrand : colors.textBody,
          ),
        ),
      ),
    );
  }
}
