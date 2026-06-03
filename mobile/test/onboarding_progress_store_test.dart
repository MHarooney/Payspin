import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/onboarding/onboarding_progress.dart';
import 'package:payspin_mobile/core/onboarding/onboarding_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingProgressStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = OnboardingProgressStore();
  });

  test('save then load round-trips the in-progress verification', () async {
    await store.save(OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: 'Mo',
      verificationId: 'vid-123',
      codeSent: true,
      savedAt: DateTime.now(),
    ));

    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.countryCode, '+20');
    expect(loaded.phone, '1060908902');
    expect(loaded.displayName, 'Mo');
    expect(loaded.verificationId, 'vid-123');
    expect(loaded.codeSent, isTrue);
  });

  test('load returns null and clears when the entry is expired', () async {
    await store.save(OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: '',
      savedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ));

    expect(await store.load(), isNull);
  });

  test('load returns null when there is no phone to restore', () async {
    await store.save(OnboardingProgress(
      countryCode: '+20',
      phone: '',
      displayName: '',
      savedAt: DateTime.now(),
    ));

    expect(await store.load(), isNull);
  });

  test('clear removes persisted progress', () async {
    await store.save(OnboardingProgress(
      countryCode: '+20',
      phone: '123456',
      displayName: '',
      savedAt: DateTime.now(),
    ));

    await store.clear();

    expect(await store.load(), isNull);
  });

  test('restore routing flags distinguish OTP vs phone resume', () {
    final savedAt = DateTime(2026, 1, 1);
    final withVerification = OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: 'Mo',
      verificationId: 'vid-abc',
      codeSent: true,
      savedAt: savedAt,
    );
    final phoneOnly = OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: 'Mo',
      savedAt: savedAt,
    );

    expect(withVerification.shouldRestoreOtp, isTrue);
    expect(withVerification.shouldRestorePhone, isFalse);
    expect(phoneOnly.shouldRestoreOtp, isFalse);
    expect(phoneOnly.shouldRestorePhone, isTrue);

    final verificationWithoutSms = OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: 'Mo',
      verificationId: 'vid-partial',
      codeSent: false,
      savedAt: savedAt,
    );
    expect(verificationWithoutSms.shouldRestoreOtp, isFalse);
    expect(verificationWithoutSms.shouldRestorePhone, isTrue);
  });

  test('needsResend is true when the saved session is older than resendAfter', () {
    final fresh = OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: '',
      verificationId: 'vid',
      codeSent: true,
      savedAt: DateTime.now(),
    );
    final stale = OnboardingProgress(
      countryCode: '+20',
      phone: '1060908902',
      displayName: '',
      verificationId: 'vid',
      codeSent: true,
      savedAt: DateTime.now().subtract(OnboardingProgress.resendAfter + const Duration(seconds: 1)),
    );

    expect(fresh.needsResend, isFalse);
    expect(stale.needsResend, isTrue);
  });
}
