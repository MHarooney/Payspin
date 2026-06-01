import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payspin_mobile/core/security/app_lock_service.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

class _MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late _MockStorage storage;
  late _MockLocalAuth auth;
  late AppLockService service;
  late Map<String, String?> store;

  setUp(() {
    storage = _MockStorage();
    auth = _MockLocalAuth();
    service = AppLockService(storage: storage, localAuth: auth);
    store = <String, String?>{};

    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((inv) async {
      store[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String?;
    });
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((inv) async => store[inv.namedArguments[#key] as String]);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((inv) async {
      store.remove(inv.namedArguments[#key] as String);
    });
  });

  group('passcode', () {
    test('isValidPin only accepts 6 digits', () {
      expect(service.isValidPin('123456'), isTrue);
      expect(service.isValidPin('12345'), isFalse);
      expect(service.isValidPin('1234567'), isFalse);
      expect(service.isValidPin('12345a'), isFalse);
      expect(service.isValidPin(''), isFalse);
    });

    test('enableLock stores enabled + biometric flags and a verifiable hash',
        () async {
      await service.enableLock(
        pin: '424242',
        biometricEnabled: true,
        displayName: 'Mahmoud Elharoun',
      );

      expect(await service.isLockEnabled(), isTrue);
      expect(await service.isBiometricEnabled(), isTrue);
      expect(await service.displayName(), 'Mahmoud Elharoun');
      // Raw PIN is never persisted.
      expect(store.values.contains('424242'), isFalse);
    });

    test('verifyPin succeeds for correct code and fails for wrong code',
        () async {
      await service.enableLock(pin: '654321', biometricEnabled: false);

      expect(await service.verifyPin('654321'), isTrue);
      expect(await service.verifyPin('000000'), isFalse);
    });

    test('verifyPin returns false when no lock is set up', () async {
      expect(await service.verifyPin('123456'), isFalse);
    });

    test('disableLock removes all lock material', () async {
      await service.enableLock(pin: '111111', biometricEnabled: true, displayName: 'X');
      await service.disableLock();

      expect(await service.isLockEnabled(), isFalse);
      expect(await service.isBiometricEnabled(), isFalse);
      expect(await service.displayName(), isNull);
      expect(await service.verifyPin('111111'), isFalse);
    });
  });

  group('capability', () {
    void stubBiometrics({
      bool supported = true,
      bool canCheck = true,
      List<BiometricType> enrolled = const [],
    }) {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => supported);
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => canCheck);
      when(() => auth.getAvailableBiometrics()).thenAnswer((_) async => enrolled);
    }

    test('detects a face biometric as the priority kind', () async {
      stubBiometrics(enrolled: const [BiometricType.face]);
      final cap = await service.capability();
      expect(cap.hasBiometrics, isTrue);
      expect(cap.kind, anyOf(BiometricKind.faceId, BiometricKind.faceUnlock));
    });

    test('falls back to fingerprint when no face is enrolled', () async {
      stubBiometrics(enrolled: const [BiometricType.fingerprint]);
      final cap = await service.capability();
      expect(cap.hasBiometrics, isTrue);
      expect(cap.kind, anyOf(BiometricKind.touchId, BiometricKind.fingerprint));
    });

    test('reports no biometrics when none are enrolled', () async {
      stubBiometrics(enrolled: const []);
      final cap = await service.capability();
      expect(cap.hasBiometrics, isFalse);
      expect(cap.kind, BiometricKind.none);
      expect(cap.label, 'Passcode');
    });

    test('degrades to empty capability if the platform throws', () async {
      when(() => auth.isDeviceSupported()).thenThrow(Exception('no plugin'));
      final cap = await service.capability();
      expect(cap, same(LockCapability.empty));
    });
  });

  group('authenticateBiometric', () {
    void stubAuth({bool? returns, Object? throws}) {
      final stub = when(() => auth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          ));
      if (throws != null) {
        stub.thenThrow(throws);
      } else {
        stub.thenAnswer((_) async => returns ?? false);
      }
    }

    test('returns success when the OS confirms', () async {
      stubAuth(returns: true);
      expect(await service.authenticateBiometric(reason: 'x'),
          BiometricResult.success);
    });

    test('maps lockout codes to lockedOut', () async {
      stubAuth(
        throws: const LocalAuthException(code: LocalAuthExceptionCode.biometricLockout),
      );
      expect(await service.authenticateBiometric(reason: 'x'),
          BiometricResult.lockedOut);
    });

    test('maps missing-hardware codes to unavailable', () async {
      stubAuth(
        throws: const LocalAuthException(code: LocalAuthExceptionCode.noBiometricHardware),
      );
      expect(await service.authenticateBiometric(reason: 'x'),
          BiometricResult.unavailable);
    });

    test('maps user cancellation to canceled', () async {
      stubAuth(
        throws: const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
      );
      expect(await service.authenticateBiometric(reason: 'x'),
          BiometricResult.canceled);
    });
  });
}
