import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  String buildMessage({required String amountLabel, required String description, required String payUrl}) {
    final desc = description.trim().isEmpty ? '' : '\n$description';
    return 'Pay $amountLabel via Payspin$desc\n$payUrl';
  }

  /// Center of the screen — required for iPad popover anchoring when no widget origin exists.
  static Rect fallbackShareOrigin() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 2,
      height: 2,
    );
  }

  static Rect? originFrom(BuildContext? context) {
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (rect.size == Size.zero) return null;
    return rect;
  }

  Future<ShareResult> _presentShare(
    String message, {
    BuildContext? context,
    Rect? origin,
  }) async {
    final rect = origin ?? originFrom(context) ?? fallbackShareOrigin();
    try {
      return await Share.share(message, sharePositionOrigin: rect);
    } on PlatformException {
      return Share.share(message);
    }
  }

  /// Opens WhatsApp when installed; otherwise falls back to the system share sheet.
  /// Never throws for a missing WhatsApp install — only if every share path fails.
  Future<void> shareWhatsApp(String message, {BuildContext? context, Rect? origin}) async {
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

    final result = await _presentShare(message, context: context, origin: origin);
    if (result.status == ShareResultStatus.dismissed) {
      // User closed the sheet without sharing — not an error.
      return;
    }
  }

  Future<ShareResult> shareNative(String message, {BuildContext? context, Rect? origin}) =>
      _presentShare(message, context: context, origin: origin);

  /// Opens the system share sheet only — never attempts WhatsApp deep link.
  Future<ShareResult> shareMoreApps(String message, {BuildContext? context, Rect? origin}) =>
      _presentShare(message, context: context, origin: origin);
}
