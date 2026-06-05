import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/design_system/widgets/payspin_scan_frame.dart';
import '../../core/l10n/payspin_localizations.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    context.pop(raw);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const Positioned.fill(child: PayspinScanFrame()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _roundBtn(Icons.close, () => context.pop(), label: 'Close scanner'),
                      const Spacer(),
                      _roundBtn(_torchOn ? Icons.flash_on : Icons.flash_off, _toggleTorch, active: _torchOn, label: 'Toggle flashlight'),
                      const SizedBox(width: 10),
                      _roundBtn(Icons.tune_rounded, () => context.showQuickSettingsSheet(), label: 'Settings'),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: PayspinGlassSurface(
                    tier: PayspinGlassTier.overlay,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Text(context.l10n.scanCardTitle, style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.scanCardBody,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.72), height: 1.55),
                        ),
                        const SizedBox(height: 16),
                        PayspinGradientPillButton(label: context.l10n.scanOk, onPressed: () => context.pop()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap, {bool active = false, String? label}) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: active
            ? PayspinTokens.mint.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: active ? PayspinTokens.mint : Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
