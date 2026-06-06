import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/motion/payspin_motion_scope.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_brand_mark.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/design_system/widgets/payspin_underline_field.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bank_account_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await sl<AuthRepository>().login(email: _email.text.trim(), password: _password.text);
      final accounts = await sl<BankAccountRepository>().listAccounts();
      if (!mounted) return;
      context.go(accounts.isEmpty ? '/onboarding/iban?existing=1' : '/home');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final l10n = context.l10n;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/welcome')),
      ),
      extendBodyBehindAppBar: true,
      body: PayspinAmbientBackground(
        child: Stack(
          children: [
            const Positioned(top: -40, left: 0, right: 0, child: PayspinRadialGlow(size: 360, animate: false)),
            Positioned.fill(child: PayspinFinanceParticles(intensity: isLight ? 0.85 : 0.55)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: PayspinParallax(
                        dx: 10,
                        dy: 8,
                        child: PayspinBrandMark.auth(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.logInTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.logInSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: colors.textBody, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    PayspinGlassCard(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PayspinUnderlineField(
                            controller: _email,
                            hintText: l10n.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          PayspinUnderlineField(
                            controller: _password,
                            hintText: l10n.password,
                            obscureText: true,
                            showVisibilityToggle: true,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: PayspinTokens.danger, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: PayspinTokens.danger, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    PayspinGradientPillButton(
                      label: _loading ? l10n.signingIn : l10n.logIn,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
