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
import '../../core/design_system/widgets/payspin_morphing_sliver_header.dart';
import '../../core/design_system/widgets/payspin_settings_group.dart';
import '../../core/design_system/widgets/payspin_shell_tab_headers.dart';
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
  bool _loading = true;
  bool _lockEnabled = false;
  String _lockDetail = 'Off';

  BankAccount? get _primaryAccount {
    if (_accounts.isEmpty) return null;
    return _accounts.firstWhere((a) => a.isPrimary, orElse: () => _accounts.first);
  }

  String get _ibanHeroLabel =>
      _accounts.length > 1 ? 'PRIMARY IBAN' : 'LINKED IBAN';

  String? get _ibanHeroSubtitle {
    final primary = _primaryAccount;
    if (primary == null) return 'Add an IBAN to receive payments';

    final parts = <String>[
      if (primary.bankName != null && primary.bankName!.isNotEmpty) primary.bankName!,
      if (primary.accountHolder.isNotEmpty) primary.accountHolder,
    ];
    var subtitle = parts.join(' · ');
    if (_accounts.length > 1) {
      final countSuffix = '${_accounts.length} linked';
      subtitle = subtitle.isEmpty ? countSuffix : '$subtitle · $countSuffix';
    }
    return subtitle.isEmpty ? null : subtitle;
  }

  String get _ibanHeroSemanticsLabel {
    if (_primaryAccount == null) return 'No IBAN linked. Tap to add one.';
    if (_accounts.length > 1) {
      return 'Primary IBAN ending ${_primaryAccount!.ibanLast4}. ${_accounts.length} accounts linked. Tap to manage bank accounts.';
    }
    return 'Linked IBAN ending ${_primaryAccount!.ibanLast4}. Tap to manage bank accounts.';
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
        PayspinMorphingSliverHeader(
          expandedHeight: PayspinProfileShellHeaderMetrics.expandedHeight,
          collapsedHeight: PayspinProfileShellHeaderMetrics.collapsedHeight,
          builder: (ctx, t, _) => PayspinProfileShellHeader(
            t: t,
            name: name,
            initial: initial,
            contact: contact.isNotEmpty ? contact : null,
            onBack: widget.onGoHome,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Semantics(
                button: true,
                label: _ibanHeroSemanticsLabel,
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
                                    Text(_ibanHeroLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: colors.textMuted, letterSpacing: 1)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _primaryAccount != null ? '•••• ${_primaryAccount!.ibanLast4}' : 'Not linked',
                                            style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 18, color: colors.textPrimary),
                                          ),
                                        ),
                                        if (_primaryAccount != null) ...[
                                          const SizedBox(width: 8),
                                          const PayspinPrimaryBadge(),
                                        ],
                                      ],
                                    ),
                                    if (_ibanHeroSubtitle != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _ibanHeroSubtitle!,
                                        style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
                                      ),
                                    ],
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
                  PayspinSettingsRow(icon: Icons.help_outline, label: context.l10n.helpSupport, onTap: () => context.push('/support')),
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
