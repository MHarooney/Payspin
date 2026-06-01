import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/domain/entities/auth_session.dart';
import 'package:payspin_mobile/domain/entities/bank_account.dart';
import 'package:payspin_mobile/domain/entities/institution.dart';
import 'package:payspin_mobile/domain/entities/user.dart';
import 'package:payspin_mobile/domain/repositories/auth_repository.dart';
import 'package:payspin_mobile/domain/repositories/bank_account_repository.dart';
import 'package:payspin_mobile/domain/repositories/onboarding_repository.dart';
import 'package:payspin_mobile/domain/usecases/complete_onboarding_usecase.dart';
import 'package:payspin_mobile/domain/usecases/validate_iban_usecase.dart';
import 'package:payspin_mobile/domain/usecases/verify_otp_usecase.dart';

class _FakeAuthRepo implements AuthRepository {
  bool registerCalled = false;
  String? updatedDisplayName;

  @override
  Future<AuthSession> register({required String email, required String password, String? displayName}) async {
    registerCalled = true;
    return AuthSession(
      accessToken: 'tok',
      user: User(id: 'u1', email: email, displayName: displayName, createdAt: 'now'),
    );
  }

  @override
  Future<User> updateDisplayName(String name) async {
    updatedDisplayName = name;
    return User(id: 'u1', email: 'a@b.com', displayName: name, createdAt: 'now');
  }

  @override
  Future<User?> currentUser() async => null;
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<AuthSession> login({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
}

class _FakeBankRepo implements BankAccountRepository {
  String? addedIban;
  String? addedHolder;

  @override
  Future<BankAccount> addAccount({required String iban, required String accountHolder, String? bankName}) async {
    addedIban = iban;
    addedHolder = accountHolder;
    return BankAccount(id: 'ba1', ibanLast4: '3000', accountHolder: accountHolder, verified: false);
  }

  @override
  Future<List<BankAccount>> listAccounts() async => [];
  @override
  Future<BankAccount> setPrimary(String id) => throw UnimplementedError();
  @override
  Future<void> deleteAccount(String id) => throw UnimplementedError();
  @override
  Future<List<Institution>> listInstitutions({String? country}) async => [];
  @override
  Future<BankConnectionStart> startConnect({String? institutionId}) => throw UnimplementedError();
  @override
  Future<BankAccount> completeConnect({required String connectionId, required String consentToken, String? expectedIban}) =>
      throw UnimplementedError();
}

class _FakeOnboardingRepo implements OnboardingRepository {
  bool? completedValue;
  @override
  Future<bool> isOnboardingComplete() async => completedValue ?? false;
  @override
  Future<void> setOnboardingComplete(bool value) async => completedValue = value;
}

void main() {
  group('ValidateIbanUseCase', () {
    final useCase = ValidateIbanUseCase();
    test('accepts a valid IBAN (null error)', () {
      expect(useCase('DE89370400440532013000'), isNull);
    });
    test('rejects a too-short IBAN', () {
      expect(useCase('DE32 4234 25'), isNotNull);
    });
    test('normalize strips spaces and uppercases', () {
      expect(useCase.normalize('de89 3704 0044 0532 0130 00'), 'DE89370400440532013000');
    });
  });

  group('VerifyOtpUseCase (demo gate)', () {
    final useCase = VerifyOtpUseCase();
    test('accepts any 6 digits', () {
      expect(useCase('123456'), isTrue);
      expect(useCase(' 654321 '), isTrue);
    });
    test('rejects non-6-digit input', () {
      expect(useCase('12'), isFalse);
      expect(useCase('abcdef'), isFalse);
      expect(useCase('1234567'), isFalse);
    });
  });

  group('CompleteOnboardingUseCase', () {
    test('new user: registers, adds normalized IBAN, marks complete', () async {
      final auth = _FakeAuthRepo();
      final bank = _FakeBankRepo();
      final onboarding = _FakeOnboardingRepo();
      final useCase = CompleteOnboardingUseCase(
        authRepository: auth,
        bankAccountRepository: bank,
        onboardingRepository: onboarding,
      );
      await useCase(
        displayName: 'Jane',
        fullName: 'Jane Doe',
        iban: 'de89 3704 0044 0532 0130 00',
        email: 'jane@b.com',
        password: 'pw',
      );
      expect(auth.registerCalled, isTrue);
      expect(auth.updatedDisplayName, isNull);
      expect(bank.addedIban, 'DE89370400440532013000');
      expect(bank.addedHolder, 'Jane Doe');
      expect(onboarding.completedValue, isTrue);
    });

    test('already-registered: updates display name instead of registering', () async {
      final auth = _FakeAuthRepo();
      final bank = _FakeBankRepo();
      final onboarding = _FakeOnboardingRepo();
      final useCase = CompleteOnboardingUseCase(
        authRepository: auth,
        bankAccountRepository: bank,
        onboardingRepository: onboarding,
      );
      await useCase(
        displayName: 'Jane',
        fullName: 'Jane Doe',
        iban: 'DE89370400440532013000',
        email: 'jane@b.com',
        password: 'pw',
        alreadyRegistered: true,
      );
      expect(auth.registerCalled, isFalse);
      expect(auth.updatedDisplayName, 'Jane Doe');
      expect(onboarding.completedValue, isTrue);
    });

    test('already-registered with empty names: skips display-name update', () async {
      final auth = _FakeAuthRepo();
      final useCase = CompleteOnboardingUseCase(
        authRepository: auth,
        bankAccountRepository: _FakeBankRepo(),
        onboardingRepository: _FakeOnboardingRepo(),
      );
      await useCase(
        displayName: '',
        fullName: '   ',
        iban: 'DE89370400440532013000',
        email: 'jane@b.com',
        password: 'pw',
        alreadyRegistered: true,
      );
      expect(auth.updatedDisplayName, isNull);
    });
  });
}
