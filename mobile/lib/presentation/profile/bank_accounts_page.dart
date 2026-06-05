import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_iban_tile.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/bank_account_repository.dart';

/// Dedicated screen that lists every linked bank account / IBAN and lets the
/// user set the primary, remove an account, add another IBAN, or connect a new
/// bank. Reached from Profile → "Bank accounts".
class BankAccountsPage extends StatefulWidget {
  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  List<BankAccount> _accounts = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final accounts = await sl<BankAccountRepository>().listAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showPayspinSnackBar(context, apiErrorMessage(e));
      }
    }
  }

  Future<void> _setPrimary(BankAccount account) async {
    if (account.isPrimary || _busy) return;
    setState(() => _busy = true);
    try {
      await sl<BankAccountRepository>().setPrimary(account.id);
      await _load();
      if (mounted) {
        showPayspinSnackBar(context, '•••• ${account.ibanLast4} is now your primary IBAN');
      }
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount(BankAccount account) async {
    if (_busy) return;
    if (account.isPrimary && _accounts.length > 1) {
      showPayspinSnackBar(context, 'Set another IBAN as primary before removing this one.');
      return;
    }
    final confirm = await showPayspinConfirmDialog(
      context,
      title: 'Remove this IBAN?',
      message: '•••• ${account.ibanLast4} will be removed from your account.',
      confirmLabel: 'Remove',
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirm) return;
    setState(() => _busy = true);
    try {
      await sl<BankAccountRepository>().deleteAccount(account.id);
      await _load();
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _accountMenu(BankAccount account) {
    final colors = context.psColors;
    return PopupMenuButton<String>(
      enabled: !_busy,
      icon: Icon(Icons.more_vert, size: 18, color: colors.textMuted),
      color: colors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'primary') _setPrimary(account);
        if (value == 'remove') _deleteAccount(account);
      },
      itemBuilder: (ctx) => [
        if (!account.isPrimary)
          PopupMenuItem(
            value: 'primary',
            child: Text('Set as primary', style: GoogleFonts.inter(color: colors.textPrimary)),
          ),
        PopupMenuItem(
          value: 'remove',
          child: Text('Remove', style: GoogleFonts.inter(color: PayspinTokens.danger, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _addRow({required IconData icon, required String label, required String sublabel, required VoidCallback onTap}) {
    final colors = context.psColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: colors.glassFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.glassBorder)),
                child: Icon(icon, size: 18, color: colors.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(sublabel, style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/home/profile'),
        ),
        title: Text('Bank accounts', style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: PayspinAmbientBackground(
        intensity: 0.7,
        child: _loading
            ? const PayspinPageLoader()
            : RefreshIndicator(
                onRefresh: _load,
                color: PayspinTokens.pink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + kToolbarHeight + 8, 20, 40),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        _accounts.isEmpty
                            ? 'YOUR IBANS'
                            : 'YOUR IBANS · ${_accounts.length}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 11, color: colors.textMuted, letterSpacing: 1),
                      ),
                    ),
                    if (_accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                        child: Text(
                          'You haven\'t linked an IBAN yet. Add one so people can pay you back.',
                          style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted, height: 1.5),
                        ),
                      ),
                    PayspinGlassSurface(
                      tier: PayspinGlassTier.raised,
                      borderRadius: 18,
                      child: Column(
                        children: [
                          for (var i = 0; i < _accounts.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: colors.border),
                            PayspinIbanTile(
                              ibanLast4: _accounts[i].ibanLast4,
                              accountHolder: _accounts[i].accountHolder,
                              bankName: _accounts[i].bankName,
                              isPrimary: _accounts[i].isPrimary,
                              onTap: _busy ? null : () => _setPrimary(_accounts[i]),
                              trailing: _accountMenu(_accounts[i]),
                            ),
                          ],
                          if (_accounts.isNotEmpty) Divider(height: 1, color: colors.border),
                          _addRow(
                            icon: Icons.add,
                            label: _accounts.isEmpty ? 'Add an IBAN' : 'Add another IBAN',
                            sublabel: 'Enter an IBAN manually',
                            onTap: () => context.push('/onboarding/iban?existing=1'),
                          ),
                          Divider(height: 1, color: colors.border),
                          _addRow(
                            icon: Icons.account_balance_outlined,
                            label: 'Connect a bank',
                            sublabel: 'Link securely via open banking',
                            onTap: () => context.push('/onboarding/connect?existing=1'),
                          ),
                        ],
                      ),
                    ),
                    if (_accounts.length > 1) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Tap an IBAN to make it your primary. New payment requests default to the primary IBAN, and you can still pick a different one when creating a link.',
                          style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted, height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
