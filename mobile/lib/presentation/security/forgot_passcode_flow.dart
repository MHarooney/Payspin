import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_otp_boxes.dart';
import '../../core/firebase/phone_auth_service.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/util/phone_mask.dart';
import '../../domain/entities/support_thread.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/support_repository.dart';

enum ForgotPasscodeResult { canceled, otpVerified, signOut, supportSubmitted }

Future<ForgotPasscodeResult?> showForgotPasscodeFlow(BuildContext context) {
  return showGeneralDialog<ForgotPasscodeResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cancel',
    barrierColor: Colors.transparent,
    transitionDuration: PayspinMotion.slow,
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, __) {
      final reduced = PayspinMotion.reduced(context);
      final enter = CurvedAnimation(parent: anim, curve: PayspinMotion.easeEnter);
      final spring = CurvedAnimation(parent: anim, curve: PayspinMotion.spring);

      Widget body = const _ForgotPasscodeFlowBody();

      if (!reduced) {
        body = FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(enter),
            child: Transform.scale(
              scale: 0.78 + 0.22 * spring.value,
              child: body,
            ),
          ),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: anim,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.62),
              child: reduced
                  ? const SizedBox.expand()
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 16 * anim.value,
                        sigmaY: 16 * anim.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
          Center(child: body),
        ],
      );
    },
  );
}

enum _ForgotPhase { loading, intro, otp, success, noPhone, supportSent }

class _ForgotPasscodeFlowBody extends StatefulWidget {
  const _ForgotPasscodeFlowBody();

  @override
  State<_ForgotPasscodeFlowBody> createState() => _ForgotPasscodeFlowBodyState();
}

class _ForgotPasscodeFlowBodyState extends State<_ForgotPasscodeFlowBody> {
  final AuthRepository _auth = sl<AuthRepository>();
  final PhoneAuthService _phoneAuth = sl<PhoneAuthService>();
  final SupportRepository _support = sl<SupportRepository>();
  final TextEditingController _code = TextEditingController();

  _ForgotPhase _phase = _ForgotPhase.loading;
  User? _user;
  String? _error;
  bool _busy = false;
  bool _codeSent = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  bool get _canUseOtp {
    final phone = _user?.phoneE164?.trim() ?? '';
    return (_user?.phoneVerified ?? false) && phone.isNotEmpty && _phoneAuth.available;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _code.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final user = await _auth.currentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _phase = _canUseOtp ? _ForgotPhase.intro : _ForgotPhase.noPhone;
    });
    if (_canUseOtp) {
      await _sendCode();
    }
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _sendCode({bool forceResending = false}) async {
    final phone = _user?.phoneE164?.trim();
    if (phone == null || phone.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await _phoneAuth.sendCode(
      phone,
      forceResending: forceResending,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _busy = false;
          _phase = _ForgotPhase.otp;
        });
        _startResendCooldown();
      },
      onAutoVerified: _verifyOtp,
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = friendlyPhoneAuthError(message);
          _busy = false;
          _phase = _ForgotPhase.intro;
        });
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_code.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await _phoneAuth.confirmCode(_code.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = 'Incorrect code. Please try again.';
        _busy = false;
      });
      return;
    }

    final idToken = await _phoneAuth.currentIdToken();
    if (!mounted) return;
    if (idToken == null) {
      setState(() {
        _error = 'Could not verify your identity. Try again.';
        _busy = false;
      });
      return;
    }

    try {
      final verified = await _auth.reauthenticateViaPhone(idToken);
      if (!mounted) return;
      if (!verified) {
        setState(() {
          _error = 'Could not verify your identity.';
          _busy = false;
        });
        return;
      }
      setState(() {
        _busy = false;
        _phase = _ForgotPhase.success;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(ForgotPasscodeResult.otpVerified);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not verify your identity.';
        _busy = false;
      });
    }
  }

  Future<void> _contactSupport() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _support.createThread(
        category: SupportCategory.account,
        contextRef: 'app-lock-forgot',
        subject: 'Forgot app passcode',
        body: 'I forgot my Payspin app passcode and need help verifying my identity '
            'to reset it on this device.',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _phase = _ForgotPhase.supportSent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not send your request. Try again.';
      });
    }
  }

  void _pop(ForgotPasscodeResult result) => Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final l10n = PayspinLocalizations.of(context);
    final maxW = MediaQuery.sizeOf(context).width - 48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW.clamp(280, 400)),
        child: PayspinGlassSurface(
          tier: PayspinGlassTier.overlay,
          gradientBorder: true,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: _buildContent(colors, l10n),
        ),
      ),
    );
  }

  Widget _buildContent(PayspinSemanticColors colors, PayspinLocalizations l10n) {
    switch (_phase) {
      case _ForgotPhase.loading:
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: PayspinTokens.mint)),
        );
      case _ForgotPhase.intro:
        return _intro(colors);
      case _ForgotPhase.otp:
        return _otp(colors);
      case _ForgotPhase.success:
        return _success(colors);
      case _ForgotPhase.noPhone:
        return _noPhone(colors, l10n);
      case _ForgotPhase.supportSent:
        return _supportSent(colors, l10n);
    }
  }

  Widget _heroIcon(IconData icon, {bool danger = false}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: danger ? null : PayspinTokens.gradientPink,
        color: danger ? PayspinTokens.danger.withValues(alpha: 0.15) : null,
        border: danger ? Border.all(color: PayspinTokens.danger.withValues(alpha: 0.4)) : null,
      ),
      child: Icon(icon, color: danger ? PayspinTokens.danger : PayspinTokens.mint, size: 30),
    );
  }

  Widget _intro(PayspinSemanticColors colors) {
    final masked = maskE164(_user?.phoneE164 ?? '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heroIcon(Icons.lock_reset),
        const SizedBox(height: 16),
        Text(
          'Reset your passcode',
          textAlign: TextAlign.center,
          style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          _codeSent
              ? 'Enter the 6-digit code we sent to $masked.'
              : 'We\'ll text a verification code to $masked to confirm it\'s you.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: colors.textMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        if (!_codeSent)
          PayspinGradientPillButton(
            label: 'Send code',
            loading: _busy,
            onPressed: _busy ? null : _sendCode,
          )
        else
          PayspinGradientPillButton(
            label: 'Enter code',
            onPressed: () => setState(() => _phase = _ForgotPhase.otp),
          ),
        const SizedBox(height: 10),
        _GlassSecondaryButton(label: 'Cancel', onTap: () => _pop(ForgotPasscodeResult.canceled)),
      ],
    );
  }

  Widget _otp(PayspinSemanticColors colors) {
    final masked = maskE164(_user?.phoneE164 ?? '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heroIcon(Icons.sms_outlined),
        const SizedBox(height: 16),
        Text(
          'Enter verification code',
          textAlign: TextAlign.center,
          style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Sent to $masked',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
        ),
        const SizedBox(height: 20),
        PayspinOtpBoxes(
          controller: _code,
          hasError: _error != null,
          onChanged: (_) => setState(() => _error = null),
          onCompleted: (_) => _verifyOtp(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        PayspinGradientPillButton(
          label: 'Verify',
          loading: _busy,
          onPressed: (_busy || _code.text.length != 6) ? null : _verifyOtp,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: (_busy || _resendCooldown > 0) ? null : () => _sendCode(forceResending: true),
          child: Text(
            _resendCooldown > 0 ? 'Resend in ${_resendCooldown}s' : 'Resend code',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _resendCooldown > 0 ? colors.textHint : PayspinTokens.mint,
            ),
          ),
        ),
        _GlassSecondaryButton(label: 'Cancel', onTap: () => _pop(ForgotPasscodeResult.canceled)),
      ],
    );
  }

  Widget _success(PayspinSemanticColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heroIcon(Icons.check_circle_outline),
        const SizedBox(height: 16),
        Text(
          'Identity confirmed',
          style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Set a new passcode next.',
          style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _noPhone(PayspinSemanticColors colors, PayspinLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heroIcon(Icons.support_agent),
        const SizedBox(height: 16),
        Text(
          'Verify your identity',
          textAlign: TextAlign.center,
          style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          'Your account doesn\'t have a verified phone number. '
          'Our support team can help you reset your passcode securely.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: colors.textMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        PayspinGradientPillButton(
          label: l10n.supportContactSupport,
          shimmer: true,
          loading: _busy,
          icon: const Icon(Icons.support_agent, color: PayspinTokens.onBrand, size: 20),
          onPressed: _busy ? null : _contactSupport,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.supportSlaHint,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: colors.textHint, height: 1.4),
        ),
        const SizedBox(height: 12),
        _GlassSecondaryButton(
          label: 'Sign out',
          onTap: () => _pop(ForgotPasscodeResult.signOut),
        ),
        const SizedBox(height: 8),
        _GlassSecondaryButton(label: 'Cancel', onTap: () => _pop(ForgotPasscodeResult.canceled)),
      ],
    );
  }

  Widget _supportSent(PayspinSemanticColors colors, PayspinLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heroIcon(Icons.mark_email_read_outlined),
        const SizedBox(height: 16),
        Text(
          'Request sent',
          style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.supportSlaHint,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: colors.textMuted),
        ),
        const SizedBox(height: 20),
        PayspinGradientPillButton(
          label: 'Done',
          onPressed: () => _pop(ForgotPasscodeResult.supportSubmitted),
        ),
      ],
    );
  }
}

class _GlassSecondaryButton extends StatefulWidget {
  const _GlassSecondaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_GlassSecondaryButton> createState() => _GlassSecondaryButtonState();
}

class _GlassSecondaryButtonState extends State<_GlassSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final enabled = widget.onTap != null;
    final scale = (_pressed && enabled && !reduced) ? 0.98 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: PayspinMotion.fast,
      child: Material(
        color: colors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          side: BorderSide(color: colors.glassBorder),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? colors.textPrimary : colors.textHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
