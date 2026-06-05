import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/config/app_version.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/theme/theme_mode_controller.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/preferences/payspin_preferences_sheets.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_iban_tile.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_settings_group.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/errors/api_exception.dart';
import '../../core/security/app_lock_controller.dart';
import '../../core/security/app_lock_service.dart';
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

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  User? _user;
  List<BankAccount> _accounts = const [];
  bool _busy = false;
  bool _loading = true;
  bool _lockEnabled = false;
  String _lockDetail = 'Off';

  BankAccount? get _primaryAccount {
    if (_accounts.isEmpty) return null;
    return _accounts.firstWhere((a) => a.isPrimary, orElse: () => _accounts.first);
  }

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  final ThemeModeController _themeController = sl<ThemeModeController>();
  final LocaleController _localeController = sl<LocaleController>();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
    _localeController.addListener(_onLocaleChanged);
    _load();
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _localeController.removeListener(_onLocaleChanged);
    _shine.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _user = await sl<AuthRepository>().currentUser();
    final accounts = await sl<BankAccountRepository>().listAccounts();
    final lock = sl<AppLockService>();
    final lockEnabled = await lock.isLockEnabled();
    final biometricEnabled = lockEnabled && await lock.isBiometricEnabled();
    final cap = biometricEnabled ? await lock.capability() : LockCapability.empty;
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _lockEnabled = lockEnabled;
        _lockDetail = !lockEnabled
            ? 'Off'
            : biometricEnabled && cap.hasBiometrics
                ? cap.label
                : 'Passcode';
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _shine.forward(from: 0));
    }
  }

  Future<void> _manageLock() async {
    if (!_lockEnabled) {
      final displayName = _user?.displayName?.trim();
      final name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (_user != null && !_user!.isPhoneAccount)
              ? _user!.email.split('@').first
              : null;
      context.go('/security/setup', extra: name);
      return;
    }
    final turnOff = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.psColors.bgElevated,
        title: Text('Turn off app lock?',
            style: GoogleFonts.raleway(fontWeight: FontWeight.w700, color: context.psColors.textPrimary)),
        content: Text('Payspin will no longer ask for $_lockDetail to open the app.',
            style: GoogleFonts.inter(color: context.psColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Turn off', style: GoogleFonts.inter(color: PayspinTokens.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (turnOff == true) {
      await sl<AppLockService>().disableLock();
      sl<AppLockController>().markDisabled();
      await _load();
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showPayspinConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You can sign back in anytime. App lock will be turned off on this device.',
      confirmLabel: 'Log out',
      destructive: true,
      icon: Icons.logout,
    );
    if (!confirmed) return;
    // Clear the lock so the next account doesn't inherit this user's
    // passcode/biometric preference.
    await sl<AppLockService>().disableLock();
    sl<AppLockController>().markDisabled();
    await sl<AuthRepository>().signOut();
    if (mounted) context.go('/welcome');
  }

  Future<void> _openBankAccounts() async {
    await context.push('/bank-accounts');
    if (mounted) await _load();
  }

  Future<void> _chooseAppearance() async {
    await context.showAppearanceSheet();
    if (mounted) setState(() {});
  }

  Future<void> _chooseLanguage() async {
    await context.showLanguageSheet();
    if (mounted) setState(() {});
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.psColors.bgElevated,
        title: Text('Remove this IBAN?',
            style: GoogleFonts.raleway(fontWeight: FontWeight.w700, color: context.psColors.textPrimary)),
        content: Text('•••• ${account.ibanLast4} will be removed from your account.',
            style: GoogleFonts.inter(color: context.psColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.inter(color: PayspinTokens.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
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
          child: Text('Remove', style: GoogleFonts.inter(color: PayspinTokens.pink, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _addRow({required IconData icon, required String label, required VoidCallback onTap}) {
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
                decoration: BoxDecoration(color: colors.glassFill, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: colors.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
              ),
              Icon(Icons.chevron_right, size: 16, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountsSection() {
    final accounts = _accounts;
    final colors = context.psColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  accounts.length > 1 ? 'BANK ACCOUNTS · ${accounts.length}' : 'BANK ACCOUNT',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: colors.textMuted, letterSpacing: 1),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _openBankAccounts,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Manage', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: PayspinTokens.mint)),
              ),
            ],
          ),
        ),
        PayspinGlassSurface(
          tier: PayspinGlassTier.raised,
          borderRadius: 18,
          child: Column(
            children: [
              for (var i = 0; i < accounts.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                PayspinIbanTile(
                  ibanLast4: accounts[i].ibanLast4,
                  accountHolder: accounts[i].accountHolder,
                  bankName: accounts[i].bankName,
                  isPrimary: accounts[i].isPrimary,
                  onTap: _busy ? null : () => _setPrimary(accounts[i]),
                  trailing: _accountMenu(accounts[i]),
                ),
              ],
              if (accounts.isNotEmpty) Divider(height: 1, color: colors.border),
              _addRow(
                icon: Icons.add,
                label: accounts.isEmpty ? 'Add an IBAN' : 'Add another IBAN',
                onTap: () => context.push('/onboarding/iban?existing=1'),
              ),
              Divider(height: 1, color: colors.border),
              _addRow(
                icon: Icons.account_balance_outlined,
                label: 'Connect a bank',
                onTap: () => context.push('/onboarding/connect?existing=1'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const PayspinPageLoader();

    final colors = context.psColors;
    final displayName = _user?.displayName?.trim();
    // For phone accounts the email local-part is just raw digits, so fall back
    // to a friendly default rather than showing a number where a name belongs.
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (_user != null && !_user!.isPhoneAccount)
            ? _user!.email.split('@').first
            : 'Payspin user';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final contact = _user?.contactLabel ?? '';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(onPressed: widget.onGoHome, tooltip: 'Back', icon: Icon(Icons.arrow_back, color: colors.textPrimary)),
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
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: PayspinTokens.gradientTri, boxShadow: PayspinTokens.fabShadow),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bg),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: PayspinTokens.gradientPink),
                        alignment: Alignment.center,
                        child: Text(initial, style: GoogleFonts.raleway(fontSize: 34, fontWeight: FontWeight.w800, color: PayspinTokens.onBrand)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                  if (contact.isNotEmpty)
                    Text(contact, style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted)),
                ],
              ),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: _primaryAccount != null
                    ? 'Primary IBAN ending ${_primaryAccount!.ibanLast4}. Tap to manage bank accounts.'
                    : 'No IBAN linked. Tap to add one.',
                child: PayspinGlassSurface(
                  tier: PayspinGlassTier.hero,
                  borderRadius: 18,
                  gradientBorder: true,
                  glow: true,
                  onTap: _openBankAccounts,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PRIMARY IBAN', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: colors.textMuted, letterSpacing: 1)),
                                    const SizedBox(height: 8),
                                    Text(_primaryAccount != null ? '•••• ${_primaryAccount!.ibanLast4}' : 'Not linked', style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 18, color: colors.textPrimary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _shine,
                            builder: (context, _) {
                              if (_shine.isDismissed || _shine.isCompleted) return const SizedBox.shrink();
                              final t = Curves.easeInOut.transform(_shine.value);
                              final streak = colors.bg.computeLuminance() < 0.5
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : PayspinTokens.pink.withValues(alpha: 0.12);
                              return IgnorePointer(
                                child: FractionallySizedBox(
                                  widthFactor: 0.4,
                                  alignment: Alignment(-1.4 + 2.8 * t, 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.transparent, streak, Colors.transparent],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildBankAccountsSection(),
              const SizedBox(height: 24),
              PayspinSettingsGroup(
                rows: [
                  PayspinSettingsRow(icon: Icons.lock_outline, label: 'App lock', detail: _lockDetail, onTap: _manageLock),
                  PayspinSettingsRow(
                    icon: Icons.brightness_6_outlined,
                    label: context.l10n.appearance,
                    detail: switch (_themeController.mode) {
                      ThemeMode.light => context.l10n.themeLight,
                      ThemeMode.dark => context.l10n.themeDark,
                      ThemeMode.system => context.l10n.themeSystem,
                    },
                    onTap: _chooseAppearance,
                  ),
                  PayspinSettingsRow(icon: Icons.notifications_outlined, label: 'Push notifications', detail: 'On', onTap: () {}),
                  PayspinSettingsRow(
                    icon: Icons.language,
                    label: context.l10n.language,
                    detail: _localeController.languageLabel,
                    onTap: _chooseLanguage,
                  ),
                  PayspinSettingsRow(icon: Icons.help_outline, label: context.l10n.helpSupport, onTap: () {}),
                  PayspinSettingsRow(icon: Icons.info_outline, label: context.l10n.version, detail: AppVersion.serial, onTap: null),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: PayspinTokens.danger.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: PayspinTokens.danger.withValues(alpha: 0.2))),
                child: InkWell(
                  onTap: _confirmLogout,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: PayspinTokens.danger, size: 18),
                        const SizedBox(width: 10),
                        Text('Log out', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: PayspinTokens.danger)),
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
