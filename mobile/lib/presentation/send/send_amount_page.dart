import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_flow_header.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_circle_button.dart';
import '../../core/design_system/widgets/payspin_numpad.dart';
import '../../core/l10n/payspin_localizations.dart';

class SendAmountPage extends StatefulWidget {
  const SendAmountPage({super.key});

  @override
  State<SendAmountPage> createState() => _SendAmountPageState();
}

class _SendAmountPageState extends State<SendAmountPage> with SingleTickerProviderStateMixin {
  String _raw = '0';
  bool _openAmount = false;
  double _amountScale = 1;
  double _continueScale = 1;

  String get _display {
    if (_openAmount) return '0,00';
    if (_raw == '0') return '0,00';
    final v = double.tryParse(_raw.replaceAll(',', '.'));
    if (v == null) return '0,00';
    final p = v.toStringAsFixed(2).split('.');
    return '${p[0]},${p[1]}';
  }

  void _pulseAmount() {
    if (PayspinMotion.reduced(context)) return;
    setState(() => _amountScale = 1.04);
    Future<void>.delayed(PayspinMotion.fast, () {
      if (mounted) setState(() => _amountScale = 1);
    });
  }

  void _pulseContinue() {
    if (PayspinMotion.reduced(context)) return;
    setState(() => _continueScale = 1.08);
    Future<void>.delayed(PayspinMotion.fast, () {
      if (mounted) setState(() => _continueScale = 1);
    });
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
    _pulseAmount();
  }

  int? get _cents {
    if (_openAmount) return null;
    final v = double.tryParse(_raw.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return (v * 100).round();
  }

  void _onOpenAmountChanged(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _openAmount = value);
    if (value || _cents != null) _pulseContinue();
  }

  @override
  Widget build(BuildContext context) {
    final isZero = !_openAmount && (_cents == null);
    final canContinue = _openAmount || !isZero;
    final colors = context.psColors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PayspinFlowHeader(onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.sendAmountQuestion,
                style: GoogleFonts.raleway(fontSize: 30, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: AnimatedSwitcher(
                duration: PayspinMotion.medium,
                switchInCurve: PayspinMotion.easeEnter,
                switchOutCurve: PayspinMotion.easeExit,
                child: _openAmount
                    ? Text(
                        l10n.sendOpenAmount,
                        key: const ValueKey('open'),
                        style: GoogleFonts.raleway(fontSize: 42, fontWeight: FontWeight.w800, color: colors.fieldAccent),
                      )
                    : Row(
                        key: const ValueKey('fixed'),
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('€', style: GoogleFonts.raleway(fontSize: 38, fontWeight: FontWeight.w800, color: colors.fieldAccent)),
                          const SizedBox(width: 12),
                          AnimatedScale(
                            scale: _amountScale,
                            duration: PayspinMotion.fast,
                            curve: PayspinMotion.spring,
                            child: Text(
                              _display,
                              style: GoogleFonts.raleway(fontSize: 42, fontWeight: FontWeight.w800, color: colors.fieldAccent),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Text(l10n.sendMaxHint, style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: PayspinGlassSurface(
                        tier: PayspinGlassTier.flat,
                        borderRadius: PayspinTokens.radiusCard,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.sendOpenAmountToggle,
                                style: GoogleFonts.inter(fontSize: 13, color: colors.textBody),
                              ),
                            ),
                            Switch(
                              value: _openAmount,
                              activeThumbColor: PayspinTokens.pink,
                              activeTrackColor: PayspinTokens.pink.withValues(alpha: 0.35),
                              onChanged: _onOpenAmountChanged,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedScale(
                      scale: _continueScale,
                      duration: PayspinMotion.fast,
                      curve: PayspinMotion.spring,
                      child: PayspinGradientCircleButton(
                        onPressed: canContinue
                            ? () {
                                _pulseContinue();
                                context.push(
                                  '/send/name',
                                  extra: {
                                    'cents': _cents,
                                    'amountLabel': _openAmount ? l10n.sendOpenAmount : '€$_display',
                                  },
                                );
                              }
                            : null,
                      ),
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
