import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/di/injection.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_gradient_pill_button.dart';
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
    // Capture draft before any async gap (no BuildContext use afterwards).
    final draft = context.read<OnboardingCubit>().state;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      // Open-banking endpoints are authenticated. During brand-new onboarding
      // the account doesn't exist yet, so register first using the draft.
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
        context.go('/home');
      } else {
        context.go('/onboarding/success');
      }
    } on _ConnectFlowException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      // flutter_web_auth_2 throws PlatformException on user cancel.
      final message = e.toString().contains('CANCELED') ||
              e.toString().contains('canceled')
          ? 'Bank connection was cancelled.'
          : apiErrorMessage(e);
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(
                        _existing ? '/home' : '/onboarding/credentials'),
                    icon: const Icon(Icons.arrow_back,
                        color: PayspinTokens.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Connect your bank',
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: PayspinTokens.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Securely link your bank so payments land in the right account. '
                'We never store your bank login.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: PayspinTokens.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(
                      color: PayspinTokens.error, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              PayspinGradientPillButton(
                label: 'Connect your bank',
                icon: const Icon(Icons.account_balance,
                    color: Colors.white, size: 20),
                loading: _connecting,
                onPressed: _loading || _institutions.isEmpty || _connecting
                    ? null
                    : _connect,
              ),
              const SizedBox(height: 12),
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
                    color: PayspinTokens.textPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PayspinTokens.pink),
      );
    }
    if (_institutions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No banks available right now.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: PayspinTokens.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadInstitutions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _institutions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final inst = _institutions[i];
        final selected = inst.id == _selected?.id;
        return Material(
          color: selected
              ? PayspinTokens.pink.withValues(alpha: 0.12)
              : PayspinTokens.glass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
            side: BorderSide(
              color:
                  selected ? PayspinTokens.borderActive : PayspinTokens.border,
            ),
          ),
          child: InkWell(
            onTap: () => setState(() => _selected = inst),
            borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inst.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: PayspinTokens.textPrimary,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: PayspinTokens.pink, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectFlowException implements Exception {
  _ConnectFlowException(this.message);
  final String message;
}
