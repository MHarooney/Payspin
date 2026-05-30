abstract class OnboardingRepository {
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);
}
