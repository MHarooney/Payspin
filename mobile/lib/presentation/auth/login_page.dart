import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
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
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/welcome'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log In', style: GoogleFonts.raleway(fontSize: 30, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
            const SizedBox(height: 8),
            Text('Use your email and password', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
            const SizedBox(height: 32),
            PayspinUnderlineField(controller: _email, hintText: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            PayspinUnderlineField(controller: _password, hintText: 'Password', obscureText: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
            ],
            const Spacer(),
            PayspinGradientPillButton(label: _loading ? 'Signing in…' : 'Log in', loading: _loading, onPressed: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}
