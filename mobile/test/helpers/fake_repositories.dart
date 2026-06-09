import 'dart:async';

import 'package:payspin_mobile/domain/entities/app_notification.dart';
import 'package:payspin_mobile/domain/entities/auth_session.dart';
import 'package:payspin_mobile/domain/entities/bank_account.dart';
import 'package:payspin_mobile/domain/entities/institution.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';
import 'package:payspin_mobile/domain/entities/user.dart';
import 'package:payspin_mobile/domain/repositories/auth_repository.dart';
import 'package:payspin_mobile/domain/repositories/bank_account_repository.dart';
import 'package:payspin_mobile/domain/repositories/notification_repository.dart';
import 'package:payspin_mobile/domain/repositories/onboarding_repository.dart';
import 'package:payspin_mobile/domain/repositories/payment_link_repository.dart';

class FakePaymentLinkRepository implements PaymentLinkRepository {
  FakePaymentLinkRepository({
    this.links = const [],
    this.listError,
    this.detail,
    this.cancelError,
  });

  List<PaymentLink> links;
  Object? listError;
  PaymentLinkDetail? detail;
  Object? cancelError;
  int listCount = 0;
  int cancelCount = 0;
  int createCount = 0;

  @override
  Future<List<PaymentLink>> listLinks() async {
    listCount++;
    if (listError != null) throw listError!;
    return links;
  }

  int? lastAmountCents;
  String? lastDescription;
  String? lastBankAccountId;

  @override
  Future<PaymentLink> createLink({int? amountCents, String? description, String? bankAccountId}) async {
    createCount++;
    lastAmountCents = amountCents;
    lastDescription = description;
    lastBankAccountId = bankAccountId;
    if (links.isEmpty) {
      return PaymentLink(
        id: 'created-$createCount',
        shortCode: 'new$createCount',
        amountCents: amountCents,
        currency: 'EUR',
        description: description,
        status: 'ACTIVE',
        createdAt: '2026-01-01T10:00:00.000Z',
        payUrl: 'https://pay/new$createCount',
        completedPaymentCount: 0,
        totalReceivedCents: 0,
      );
    }
    final base = links.first;
    return PaymentLink(
      id: base.id,
      shortCode: base.shortCode,
      amountCents: amountCents ?? base.amountCents,
      currency: base.currency,
      description: description ?? base.description,
      status: base.status,
      createdAt: base.createdAt,
      payUrl: base.payUrl,
      completedPaymentCount: base.completedPaymentCount,
      totalReceivedCents: base.totalReceivedCents,
      linkType: base.linkType,
      maxUses: base.maxUses,
      useCount: base.useCount,
      expiresAt: base.expiresAt,
    );
  }

  @override
  Future<PaymentLinkDetail> getLink(String id) async {
    if (listError != null) throw listError!;
    return detail!;
  }

  @override
  Future<void> cancelLink(String id) async {
    cancelCount++;
    if (cancelError != null) throw cancelError!;
  }
}

class FakeBankAccountRepository implements BankAccountRepository {
  FakeBankAccountRepository({
    this.institutions = const [],
    this.institutionsError,
    this.institutionsCompleter,
    this.accounts = const [],
  });

  List<Institution> institutions;
  Object? institutionsError;
  Completer<List<Institution>>? institutionsCompleter;
  List<BankAccount> accounts;
  String? lastSetPrimaryId;
  String? lastDeletedId;

  @override
  Future<List<Institution>> listInstitutions({String? country}) {
    if (institutionsCompleter != null) return institutionsCompleter!.future;
    if (institutionsError != null) return Future.error(institutionsError!);
    return Future.value(institutions);
  }

  @override
  Future<List<BankAccount>> listAccounts() async => accounts;
  @override
  Future<BankAccount> addAccount({required String iban, required String accountHolder, String? bankName}) async =>
      BankAccount(id: 'ba1', ibanLast4: '0000', accountHolder: accountHolder, verified: false);
  @override
  Future<BankAccount> setPrimary(String id) async {
    lastSetPrimaryId = id;
    return accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => BankAccount(id: id, ibanLast4: '0000', accountHolder: 'x', verified: true, isPrimary: true),
    );
  }

  @override
  Future<void> deleteAccount(String id) async {
    lastDeletedId = id;
    accounts = accounts.where((a) => a.id != id).toList();
  }

  @override
  Future<BankConnectionStart> startConnect({String? institutionId}) async =>
      const BankConnectionStart(connectionId: 'c1', authorisationUrl: 'https://bank/auth');
  @override
  Future<BankAccount> completeConnect({required String connectionId, required String consentToken, String? expectedIban}) async =>
      const BankAccount(id: 'ba1', ibanLast4: '0000', accountHolder: 'x', verified: true);
}

class FakeAuthRepository implements AuthRepository {
  bool session = false;
  User? user;
  @override
  Future<bool> hasSession() async => session;
  @override
  Future<User?> currentUser() async => user;
  @override
  Future<AuthSession> register({required String email, required String password, String? displayName}) async =>
      AuthSession(accessToken: 't', user: User(id: 'u', email: email, displayName: displayName, createdAt: 'now'));
  @override
  Future<AuthSession> login({required String email, required String password}) async =>
      AuthSession(accessToken: 't', user: User(id: 'u', email: email, displayName: null, createdAt: 'now'));
  @override
  Future<AuthSession> phoneSignIn({required String idToken, String? displayName}) async {
    session = true;
    return AuthSession(
      accessToken: 't',
      user: User(id: 'u', email: 'phone@phone.payspin.app', displayName: displayName, createdAt: 'now'),
    );
  }
  @override
  Future<void> signOut() async {}
  @override
  Future<User> updateDisplayName(String name) async =>
      User(id: 'u', email: 'a@b.com', displayName: name, createdAt: 'now');
  @override
  Future<bool> reauthenticateViaPhone(String idToken) async => true;
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({this.items = const [], this.unread = 0, this.listError});

  List<AppNotification> items;
  int unread;
  Object? listError;

  @override
  Future<NotificationPage> list({String? cursor, int limit = 20}) async {
    if (listError != null) throw listError!;
    return NotificationPage(items: items, unreadCount: unread, nextCursor: null);
  }

  @override
  Future<int> unreadCount() async => unread;

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}
}

class FakeOnboardingRepository implements OnboardingRepository {
  bool complete = false;
  @override
  Future<bool> isOnboardingComplete() async => complete;
  @override
  Future<void> setOnboardingComplete(bool value) async => complete = value;
}
