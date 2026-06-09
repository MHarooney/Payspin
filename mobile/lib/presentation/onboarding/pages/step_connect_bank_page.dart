import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/di/injection.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_explainer_sheet.dart';
import '../../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../../core/design_system/widgets/payspin_onboarding_journey.dart';
import '../../../core/design_system/widgets/payspin_onboarding_shell.dart';
import '../../../core/design_system/widgets/payspin_skeleton.dart';
import '../../../core/errors/api_exception.dart';
import '../../../domain/entities/institution.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/bank_account_repository.dart';
import '../../../domain/repositories/onboarding_repository.dart';
import '../onboarding_cubit.dart';

/// Open-banking "connect your bank" step. Lists institutions, runs the Yapily
/// web-auth flow, then calls the backend `connect/complete` to create a
/// verified bank account. Falls back to manual IBAN entry.
class StepConnectBankPage extends StatefulWidget {
  const StepConnectBankPage({super.key});

  @override
  State<StepConnectBankPage> createState() => _StepConnectBankPageState();
}

class _StepConnectBankPageState extends State<StepConnectBankPage> {
  final _bank = sl<BankAccountRepository>();
  final _auth = sl<AuthRepository>();
  final _onboarding = sl<OnboardingRepository>();

  List<Institution> _institutions = const [];
  Institution? _selected;
  bool _loading = true;
  bool _connecting = false;
  String? _error;

  bool get _existing =>
      GoRouterState.of(context).uri.queryParameters['existing'] == '1';

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _bank.listInstitutions();
      if (!mounted) return;
      setState(() {
        _institutions = list;
        _selected = list.isNotEmpty ? list.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _connect() async {
    final institution = _selected;
    final draft = context.read<OnboardingCubit>().state;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      if (!await _auth.hasSession()) {
        await _auth.register(
          email: draft.email.trim(),
          password: draft.password,
          displayName: draft.displayName.trim().isEmpty
              ? null
              : draft.displayName.trim(),
        );
      }

      final start = await _bank.startConnect(institutionId: institution?.id);
      final result = await FlutterWebAuth2.authenticate(
        url: start.authorisationUrl,
        callbackUrlScheme: 'payspin',
      );
      final consent = Uri.parse(result).queryParameters['consent'];
      final callbackError = Uri.parse(result).queryParameters['error'];
      if (callbackError != null) {
        throw _ConnectFlowException('Your bank reported: $callbackError');
      }
      if (consent == null || consent.isEmpty) {
        throw _ConnectFlowException('No consent was returned from your bank.');
      }

      await _bank.completeConnect(
        connectionId: start.connectionId,
        consentToken: consent,
      );
      await _onboarding.setOnboardingComplete(true);

      if (!mounted) return;
      if (_existing) {
        context.go('/bank-accounts');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank connected')),
        );
      } else {
        context.go('/onboarding/success');
      }
    } on _ConnectFlowException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      final message = e.toString().contains('CANCELED') ||
              e.toString().contains('canceled')
          ? 'Bank connection was cancelled.'
          : apiErrorMessage(e);
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _showSecuritySheet() {
    PayspinExplainerSheet.show(
      context,
      title: 'How we keep this safe',
      steps: const [
        (emoji: '🔐', title: 'Secure redirect', body: 'You sign in directly with your bank in a protected browser window.'),
        (emoji: '✅', title: 'Your consent', body: 'You choose what Payspin can access. We only read account details needed to receive payments.'),
        (emoji: '🚫', title: 'No passwords stored', body: 'We never see or store your bank login. Open banking handles authentication.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final canConnect = !_loading && _institutions.isNotEmpty && !_connecting;

    return PayspinOnboardingShell(
      journey: OnboardingJourneySpec.connect,
      title: const Text('Connect your bank'),
      subtitle: 'Securely link your bank so payments land in the right account. We never store your bank login.',
      onBack: () => context.go(_existing ? '/bank-accounts' : '/onboarding/otp'),
      footerStyle: OnboardingFooterStyle.pill,
      nextLabel: 'Connect your bank',
      nextIcon: Icons.account_balance,
      nextLoading: _connecting,
      onNext: canConnect ? _connect : null,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: PayspinTokens.error, fontSize: 13)),
            const SizedBox(height: 12),
          ],
          PayspinGradientPillButton(
            label: 'Connect your bank',
            icon: const Icon(Icons.account_balance, color: PayspinTokens.onBrand, size: 20),
            loading: _connecting,
            onPressed: canConnect ? _connect : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _connecting
                ? null
                : () => context.go(_existing
                    ? '/onboarding/iban?existing=1'
                    : '/onboarding/iban'),
            child: Text(
              'Enter IBAN manually instead',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: colors.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          TextButton(
            onPressed: _connecting
                ? null
                : () => context.go(_existing
                    ? '/onboarding/iban?existing=1&foreign=1'
                    : '/onboarding/iban?foreign=1'),
            child: Text(
              'Foreign IBAN?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: colors.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          TextButton(
            onPressed: _showSecuritySheet,
            child: Text(
              'How we keep this safe',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: PayspinTokens.mint),
            ),
          ),
        ],
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colors = context.psColors;

    if (_loading) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => PayspinGlassSurface(
          tier: PayspinGlassTier.flat,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: const Row(
            children: [
              PayspinSkeleton(width: 28, height: 28, radius: 8),
              SizedBox(width: 14),
              PayspinSkeleton(width: 140, height: 14),
            ],
          ),
        ),
      );
    }

    if (_institutions.isEmpty) {
      return Column(
        children: [
          Text(
            'No banks available right now.',
            style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadInstitutions, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selected != null) ...[
          PayspinGlassSurface(
            tier: PayspinGlassTier.raised,
            gradientBorder: true,
            glow: true,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PayspinTokens.pink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance, color: PayspinTokens.pink, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!.name,
                        style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Secured by open banking',
                        style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...List.generate(_institutions.length, (i) {
          final inst = _institutions[i];
          final selected = inst.id == _selected?.id;
          return Padding(
            padding: EdgeInsets.only(bottom: i < _institutions.length - 1 ? 8 : 0),
            child: _InstitutionCard(
              institution: inst,
              selected: selected,
              onTap: () => setState(() => _selected = inst),
            ),
          );
        }),
      ],
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({
    required this.institution,
    required this.selected,
    required this.onTap,
  });

  final Institution institution;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;

    return PayspinGlassSurface(
      tier: PayspinGlassTier.flat,
      gradientBorder: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.glassFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              institution.name.isNotEmpty ? institution.name[0].toUpperCase() : '?',
              style: GoogleFonts.raleway(fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              institution.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          AnimatedScale(
            scale: selected ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: selected
                ? const Icon(Icons.check_circle, color: PayspinTokens.pink, size: 20)
                : const SizedBox(width: 20),
          ),
        ],
      ),
    );
  }
}

class _ConnectFlowException implements Exception {
  _ConnectFlowException(this.message);
  final String message;
}
