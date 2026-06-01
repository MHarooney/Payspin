import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_flow_header.dart';
import '../../core/design_system/widgets/payspin_gradient_circle_button.dart';
import '../../core/design_system/widgets/payspin_numpad.dart';

class SendAmountPage extends StatefulWidget {
  const SendAmountPage({super.key});

  @override
  State<SendAmountPage> createState() => _SendAmountPageState();
}

class _SendAmountPageState extends State<SendAmountPage> {
  String _raw = '0';
  bool _openAmount = false;

  String get _display {
    if (_openAmount) return '0,00';
    if (_raw == '0') return '0,00';
    final v = double.tryParse(_raw.replaceAll(',', '.'));
    if (v == null) return '0,00';
    final p = v.toStringAsFixed(2).split('.');
    return '${p[0]},${p[1]}';
  }

  void _key(String k) {
    if (_openAmount) return;
    setState(() {
      if (k == 'back') {
        _raw = _raw.length <= 1 ? '0' : _raw.substring(0, _raw.length - 1);
      } else if (k == ',') {
        if (!_raw.contains('.')) _raw = '$_raw.';
      } else {
        _raw = _raw == '0' ? k : _raw + k;
      }
    });
  }

  int? get _cents {
    if (_openAmount) return null;
    final v = double.tryParse(_raw.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return (v * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isZero = !_openAmount && (_cents == null);
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PayspinFlowHeader(onBack: () => context.pop(), onHelp: () {}),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text("What's the amount?", style: GoogleFonts.raleway(fontSize: 30, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('€', style: GoogleFonts.raleway(fontSize: 38, fontWeight: FontWeight.w800, color: PayspinTokens.mint)),
                  const SizedBox(width: 12),
                  Text(_display, style: GoogleFonts.raleway(fontSize: 42, fontWeight: FontWeight.w800, color: isZero ? PayspinTokens.mint : PayspinTokens.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Text('You can request back a maximum of €950.', style: GoogleFonts.inter(fontSize: 12, color: PayspinTokens.textMuted)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Material(
                      color: PayspinTokens.glass,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
                        side: const BorderSide(color: PayspinTokens.border),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        title: Text(
                          'Payer may choose amount',
                          style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textBody),
                        ),
                        value: _openAmount,
                        activeThumbColor: PayspinTokens.pink,
                        onChanged: (v) => setState(() => _openAmount = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                    PayspinGradientCircleButton(
                      onPressed: (!_openAmount && isZero)
                          ? null
                          : () => context.push('/send/name', extra: {'cents': _cents, 'amountLabel': _openAmount ? 'Open amount' : '€$_display'}),
                    ),
                  ],
                ),
              ),
            ),
            if (!_openAmount) PayspinNumpad(onKey: _key),
          ],
        ),
      ),
    );
  }
}
