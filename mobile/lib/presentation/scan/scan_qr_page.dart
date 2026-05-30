import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    context.pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _onDetect),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _roundBtn(Icons.close, () => context.pop()),
                      const Spacer(),
                      _roundBtn(Icons.flash_on, () {}),
                      const SizedBox(width: 10),
                      _roundBtn(Icons.help_outline, () {}),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: PayspinTokens.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PayspinTokens.border),
                  ),
                  child: Column(
                    children: [
                      Text('Scan a Payspin QR code', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        'Pay your friends without sending links, and more.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted, height: 1.55),
                      ),
                      const SizedBox(height: 16),
                      PayspinGradientPillButton(label: 'OK, nice!', onPressed: () => context.pop()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }
}
