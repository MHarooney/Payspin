import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/share_service.dart';
import '../../l10n/payspin_localizations.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_gradient_pill_button.dart';
import 'payspin_snackbar.dart';

const _kShareSheetShimmerSeen = 'share_sheet_shimmer_seen';

/// Data required to share or copy a payment link.
class ShareLinkPayload {
  const ShareLinkPayload({
    required this.linkId,
    required this.amountLabel,
    required this.description,
    required this.payUrl,
    required this.isPayable,
  });

  final String linkId;
  final String amountLabel;
  final String description;
  final String payUrl;
  final bool isPayable;

  factory ShareLinkPayload.fromLink({
    required String linkId,
    required String amountLabel,
    required String? description,
    required String payUrl,
    required bool isPayable,
  }) {
    return ShareLinkPayload(
      linkId: linkId,
      amountLabel: amountLabel,
      description: description ?? '',
      payUrl: payUrl,
      isPayable: isPayable,
    );
  }

  String message(ShareService share) => share.buildMessage(
        amountLabel: amountLabel,
        description: description,
        payUrl: payUrl,
      );
}

/// Premium share bottom sheet — WhatsApp hero + Copy / QR / More apps.
Future<void> showPayspinShareSheet(
  BuildContext context, {
  required ShareLinkPayload payload,
  VoidCallback? onShareDisabled,
  bool whatsAppShimmer = false,
}) async {
  HapticFeedback.selectionClick();
  final prefs = await SharedPreferences.getInstance();
  final shimmer = whatsAppShimmer || !(prefs.getBool(_kShareSheetShimmerSeen) ?? false);
  if (shimmer) {
    await prefs.setBool(_kShareSheetShimmerSeen, true);
  }
  if (!context.mounted) return;

  final colors = context.psColors;
  final share = ShareService();
  final message = payload.message(share);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      void disabledTap() {
        Navigator.of(sheetContext).pop();
        onShareDisabled?.call();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                payload.description.trim().isEmpty ? payload.amountLabel : payload.description.trim(),
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (payload.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  payload.amountLabel,
                  style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              PayspinShareActionCluster(
                payload: payload,
                message: message,
                whatsAppShimmer: shimmer,
                onShareDisabled: payload.isPayable ? null : disabledTap,
                onAfterAction: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Inline share cluster for link detail and other full-width contexts.
class PayspinShareActionCluster extends StatelessWidget {
  const PayspinShareActionCluster({
    super.key,
    required this.payload,
    this.message,
    this.whatsAppShimmer = false,
    this.onShareDisabled,
    this.onAfterAction,
  });

  final ShareLinkPayload payload;
  final String? message;
  final bool whatsAppShimmer;
  final VoidCallback? onShareDisabled;
  final VoidCallback? onAfterAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final share = ShareService();
    final msg = message ?? payload.message(share);
    final enabled = payload.isPayable;

    Future<void> run(Future<void> Function() action) async {
      if (!enabled) {
        onShareDisabled?.call();
        return;
      }
      try {
        await action();
        onAfterAction?.call();
      } on PlatformException {
        if (context.mounted) {
          showPayspinSnackBar(context, l10n.shareUnavailable);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayspinGradientPillButton(
          label: l10n.sendViaWhatsApp,
          shimmer: whatsAppShimmer && enabled,
          icon: const Icon(Icons.send, color: PayspinTokens.onBrand, size: 18),
          onPressed: enabled
              ? () => run(() async => share.shareWhatsApp(msg, context: context))
              : () => onShareDisabled?.call(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ShareGlassChip(
                icon: Icons.link_rounded,
                label: l10n.copyLink,
                enabled: enabled,
                onTap: () => run(() async {
                  await Clipboard.setData(ClipboardData(text: payload.payUrl));
                  if (context.mounted) {
                    showPayspinSnackBar(context, l10n.linkCopied, success: true);
                  }
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareGlassChip(
                icon: Icons.qr_code_2_rounded,
                label: l10n.showQr,
                enabled: enabled,
                onTap: () => run(() => context.push('/links/${payload.linkId}/qr')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareGlassChip(
                icon: Icons.ios_share_rounded,
                label: l10n.moreApps,
                enabled: enabled,
                onTap: () => run(() async => share.shareMoreApps(msg, context: context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareGlassChip extends StatelessWidget {
  const _ShareGlassChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.flat,
        borderRadius: PayspinTokens.radiusCard,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.textBody),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: colors.textBody,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
