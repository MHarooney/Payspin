import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/domain/entities/bank_account.dart';
import 'package:payspin_mobile/domain/repositories/bank_account_repository.dart';
import 'package:payspin_mobile/presentation/profile/bank_accounts_page.dart';

import 'helpers/fake_repositories.dart';

BankAccount _acc(String id, String last4, {bool primary = false}) =>
    BankAccount(id: id, ibanLast4: last4, accountHolder: 'Holder $last4', verified: true, isPrimary: primary);

/// Wraps the page in a minimal router so `context.push`/`context.pop` work.
Widget _app(Widget page) {
  final router = GoRouter(
    initialLocation: '/bank-accounts',
    routes: [
      GoRoute(path: '/bank-accounts', builder: (_, __) => page),
      GoRoute(path: '/onboarding/iban', builder: (_, __) => const Scaffold(body: Text('add iban'))),
      GoRoute(path: '/onboarding/connect', builder: (_, __) => const Scaffold(body: Text('connect'))),
    ],
  );
  return MaterialApp.router(theme: PayspinTheme.dark(), routerConfig: router);
}

void main() {
  late FakeBankAccountRepository bank;

  setUp(() {
    bank = FakeBankAccountRepository();
    sl.registerSingleton<BankAccountRepository>(bank);
  });

  tearDown(() => sl.reset());

  testWidgets('lists IBANs with a Primary badge and add/connect actions', (tester) async {
    bank.accounts = [_acc('ba1', '1111', primary: true), _acc('ba2', '2222')];
    await tester.pumpWidget(_app(const BankAccountsPage()));
    await tester.pumpAndSettle();

    expect(find.text('•••• 1111'), findsOneWidget);
    expect(find.text('•••• 2222'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Add another IBAN'), findsOneWidget);
    expect(find.text('Connect a bank'), findsOneWidget);
  });

  testWidgets('tapping a non-primary IBAN sets it as primary', (tester) async {
    bank.accounts = [_acc('ba1', '1111', primary: true), _acc('ba2', '2222')];
    await tester.pumpWidget(_app(const BankAccountsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('•••• 2222'));
    await tester.pumpAndSettle();

    expect(bank.lastSetPrimaryId, 'ba2');
  });

  testWidgets('empty state invites adding the first IBAN', (tester) async {
    bank.accounts = const [];
    await tester.pumpWidget(_app(const BankAccountsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Add an IBAN'), findsOneWidget);
    expect(find.text('Connect a bank'), findsOneWidget);
  });
}
