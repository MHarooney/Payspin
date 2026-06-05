import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
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
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/welcome')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: PayspinQuickSettings(size: 36, iconSize: 18),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned(top: -40, left: 0, right: 0, child: PayspinRadialGlow(size: 360, animate: false)),
          SafeArea(
            child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.logInTitle, style: GoogleFonts.raleway(fontSize: 30, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(l10n.logInSubtitle, style: GoogleFonts.inter(color: colors.textMuted)),
            const SizedBox(height: 32),
            PayspinUnderlineField(controller: _email, hintText: l10n.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            PayspinUnderlineField(
              controller: _password,
              hintText: l10n.password,
              obscureText: true,
              showVisibilityToggle: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
            ],
            const Spacer(),
            PayspinGradientPillButton(label: _loading ? l10n.signingIn : l10n.logIn, loading: _loading, onPressed: _loading ? null : _submit),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }
}
