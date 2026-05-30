import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_settings_group.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bank_account_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  BankAccount? _account;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _user = await sl<AuthRepository>().currentUser();
    final accounts = await sl<BankAccountRepository>().listAccounts();
    if (mounted) {
      setState(() {
        _account = accounts.isNotEmpty ? accounts.first : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: PayspinTokens.pink));

    final name = _user?.displayName ?? _user?.email.split('@').first ?? 'Payspin user';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(onPressed: widget.onGoHome, icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  Expanded(child: Text('Profile', textAlign: TextAlign.center, style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 17))),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: PayspinTokens.gradientPink, boxShadow: PayspinTokens.fabShadow),
                    alignment: Alignment.center,
                    child: Text(initial, style: GoogleFonts.raleway(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
                  Text(_user?.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: PayspinTokens.textMuted)),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [PayspinTokens.pink.withValues(alpha: 0.12), PayspinTokens.mint.withValues(alpha: 0.08)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: PayspinTokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LINKED IBAN', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: PayspinTokens.textMuted, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(_account != null ? '•••• ${_account!.ibanLast4}' : 'Not linked', style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PayspinSettingsGroup(
                rows: [
                  PayspinSettingsRow(icon: Icons.credit_card_outlined, label: 'Linked IBAN', detail: _account?.ibanLast4 != null ? '•••• ${_account!.ibanLast4}' : null, onTap: () => context.go('/onboarding/iban?existing=1')),
                  PayspinSettingsRow(icon: Icons.notifications_outlined, label: 'Push notifications', detail: 'On', onTap: () {}),
                  PayspinSettingsRow(icon: Icons.language, label: 'Language', detail: 'English', onTap: () {}),
                  PayspinSettingsRow(icon: Icons.help_outline, label: 'Help & support', onTap: () {}),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: PayspinTokens.pink.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: PayspinTokens.pink.withValues(alpha: 0.2))),
                child: InkWell(
                  onTap: () async {
                    await sl<AuthRepository>().signOut();
                    if (context.mounted) context.go('/welcome');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: PayspinTokens.pink, size: 18),
                        const SizedBox(width: 10),
                        Text('Log out', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: PayspinTokens.pink)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
