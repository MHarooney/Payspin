import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  String buildMessage({required String amountLabel, required String description, required String payUrl}) {
    final desc = description.trim().isEmpty ? '' : '\n$description';
    return 'Pay $amountLabel via Payspin$desc\n$payUrl';
  }

  Future<void> shareWhatsApp(String message) async {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Share.share(message);
    }
  }

  Future<void> shareNative(String message) => Share.share(message);

  Future<void> copyLink(BuildContext context, String url) async {
    await Share.share(url);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }
}
