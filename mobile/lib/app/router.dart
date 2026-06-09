import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/di/injection.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/bank_account_repository.dart';
import '../domain/repositories/onboarding_repository.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/circles/circle_detail_page.dart';
import '../presentation/circles/create_circle_page.dart';
import '../presentation/circles/join_circle_page.dart';
import '../presentation/intro/payspin_intro_flow.dart';
import '../presentation/links/link_detail_page.dart';
import '../presentation/links/link_qr_page.dart';
import '../presentation/notifications/notifications_page.dart';
import '../presentation/onboarding/onboarding_cubit.dart';
import '../presentation/onboarding/pages/step_connect_bank_page.dart';
import '../presentation/onboarding/pages/step_full_name_page.dart';
import '../presentation/onboarding/pages/step_iban_page.dart';
import '../presentation/onboarding/pages/step_name_page.dart';
import '../presentation/onboarding/pages/step_otp_page.dart';
import '../presentation/onboarding/pages/step_phone_page.dart';
import '../presentation/onboarding/pages/success_page.dart';
import '../presentation/profile/bank_accounts_page.dart';
import '../presentation/scan/scan_qr_page.dart';
import '../presentation/security/setup_lock_page.dart';
import '../presentation/send/send_amount_page.dart';
import '../presentation/send/send_name_page.dart';
import '../presentation/shell/main_shell.dart';
import '../presentation/splash/splash_page.dart';
import '../presentation/support/new_support_request_page.dart';
import '../presentation/support/support_inbox_page.dart';
import '../presentation/support/support_thread_page.dart';
import '../domain/entities/support_thread.dart';
import '../presentation/welcome/welcome_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/splash'}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    redirect: _redirect,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/intro', builder: (_, __) => const PayspinIntroFlow()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (_, state, child) => BlocProvider(
          create: (_) => sl<OnboardingCubit>(),
          child: child,
        ),
        routes: [
          GoRoute(path: '/onboarding/name', builder: (_, __) => const StepNamePage()),
          GoRoute(path: '/onboarding/phone', builder: (_, __) => const StepPhonePage()),
          GoRoute(path: '/onboarding/otp', builder: (_, __) => const StepOtpPage()),
          GoRoute(path: '/onboarding/connect', builder: (_, __) => const StepConnectBankPage()),
          GoRoute(path: '/onboarding/iban', builder: (_, __) => const StepIbanPage()),
          GoRoute(path: '/onboarding/full-name', builder: (_, __) => const StepFullNamePage()),
          GoRoute(path: '/onboarding/success', builder: (_, __) => const SuccessPage()),
        ],
      ),
      ShellRoute(
        builder: (_, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const SizedBox.shrink()),
          GoRoute(path: '/home/groepies', builder: (_, __) => const SizedBox.shrink()),
          GoRoute(path: '/home/profile', builder: (_, __) => const SizedBox.shrink()),
        ],
      ),
      GoRoute(path: '/send/amount', builder: (_, __) => const SendAmountPage()),
      GoRoute(
        path: '/send/name',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SendNamePage(
            amountCents: extra['cents'] as int?,
            amountLabel: extra['amountLabel'] as String? ?? '—',
          );
        },
      ),
      GoRoute(
        path: '/security/setup',
        builder: (_, state) => SetupLockPage(displayName: state.extra as String?),
      ),
      GoRoute(path: '/scan', builder: (_, __) => const ScanQrPage()),
      GoRoute(path: '/bank-accounts', builder: (_, __) => const BankAccountsPage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/support', builder: (_, __) => const SupportInboxPage()),
      GoRoute(
        path: '/support/new',
        builder: (_, state) => NewSupportRequestPage(
          contextRef: state.uri.queryParameters['contextRef'],
          initialCategory: SupportCategoryX.fromWire(state.uri.queryParameters['category']),
        ),
      ),
      GoRoute(
        path: '/support/:threadId',
        builder: (_, state) => SupportThreadPage(threadId: state.pathParameters['threadId']!),
      ),
      GoRoute(
        path: '/links/:id',
        builder: (_, state) => LinkDetailPage(linkId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/links/:id/qr',
        builder: (_, state) => LinkQrPage(linkId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/circles/create', builder: (_, __) => const CreateCirclePage()),
      GoRoute(path: '/circles/join', builder: (_, __) => const JoinCirclePage()),
      GoRoute(
        path: '/circles/:id',
        builder: (_, state) => CircleDetailPage(circleId: state.pathParameters['id']!),
      ),
    ],
  );
}

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final loc = state.matchedLocation;
  if (loc == '/splash' ||
      loc == '/intro' ||
      loc == '/welcome' ||
      loc.startsWith('/onboarding') ||
      loc == '/login') {
    return null;
  }

  final hasSession = await sl<AuthRepository>().hasSession();
  if (!hasSession) return '/welcome';

  if (loc.startsWith('/send') ||
      loc.startsWith('/scan') ||
      loc.startsWith('/links') ||
      loc.startsWith('/circles') ||
      loc.startsWith('/bank-accounts') ||
      loc.startsWith('/notifications') ||
      loc.startsWith('/support')) {
    return null;
  }

  if (loc.startsWith('/home')) {
    try {
      final accounts = await sl<BankAccountRepository>()
          .listAccounts()
          .timeout(const Duration(seconds: 8));
      if (accounts.isEmpty) return '/onboarding/connect?existing=1';
    } catch (_) {
      // Offline / slow API — still show home; user can retry from profile.
    }
    return null;
  }

  final complete = await sl<OnboardingRepository>().isOnboardingComplete();
  if (!complete) return '/onboarding/name';

  return null;
}
