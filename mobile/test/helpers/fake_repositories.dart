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

  @override
  Future<List<PaymentLink>> listLinks() async {
    listCount++;
    if (listError != null) throw listError!;
    return links;
  }

  @override
  Future<PaymentLink> createLink({int? amountCents, String? description}) async => links.first;

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
  });

  List<Institution> institutions;
  Object? institutionsError;
  Completer<List<Institution>>? institutionsCompleter;

  @override
  Future<List<Institution>> listInstitutions({String? country}) {
    if (institutionsCompleter != null) return institutionsCompleter!.future;
    if (institutionsError != null) return Future.error(institutionsError!);
    return Future.value(institutions);
  }

  @override
  Future<List<BankAccount>> listAccounts() async => [];
  @override
  Future<BankAccount> addAccount({required String iban, required String accountHolder, String? bankName}) async =>
      BankAccount(id: 'ba1', ibanLast4: '0000', accountHolder: accountHolder, verified: false);
  @override
  Future<BankConnectionStart> startConnect({String? institutionId}) async =>
      const BankConnectionStart(connectionId: 'c1', authorisationUrl: 'https://bank/auth');
  @override
  Future<BankAccount> completeConnect({required String connectionId, required String consentToken, String? expectedIban}) async =>
      const BankAccount(id: 'ba1', ibanLast4: '0000', accountHolder: 'x', verified: true);
}

class FakeAuthRepository implements AuthRepository {
  bool session = false;
  @override
  Future<bool> hasSession() async => session;
  @override
  Future<User?> currentUser() async => null;
  @override
  Future<AuthSession> register({required String email, required String password, String? displayName}) async =>
      AuthSession(accessToken: 't', user: User(id: 'u', email: email, displayName: displayName, createdAt: 'now'));
  @override
  Future<AuthSession> login({required String email, required String password}) async =>
      AuthSession(accessToken: 't', user: User(id: 'u', email: email, displayName: null, createdAt: 'now'));
  @override
  Future<void> signOut() async {}
  @override
  Future<User> updateDisplayName(String name) async =>
      User(id: 'u', email: 'a@b.com', displayName: name, createdAt: 'now');
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
