import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  String buildMessage({required String amountLabel, required String description, required String payUrl}) {
    final desc = description.trim().isEmpty ? '' : '\n$description';
    return 'Pay $amountLabel via Payspin$desc\n$payUrl';
  }

  /// Opens WhatsApp when installed; otherwise falls back to the system share sheet.
  /// Never throws for a missing WhatsApp install — only if every share path fails.
  Future<void> shareWhatsApp(String message) async {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (opened) return;
      }
    } on PlatformException {
      // Simulator / device without WhatsApp — use the share sheet below.
    } catch (_) {
      // canLaunchUrl or launchUrl failed — fall through.
    }

    final result = await Share.share(message);
    if (result.status == ShareResultStatus.dismissed) {
      // User closed the sheet without sharing — not an error.
      return;
    }
  }

  Future<void> shareNative(String message) => Share.share(message);
}
