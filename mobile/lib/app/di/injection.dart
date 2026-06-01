import 'package:get_it/get_it.dart';

import '../../core/config/remote_config_service.dart';
import '../../core/firebase/phone_auth_service.dart';
import '../../core/notifications/push_service.dart';
import '../../core/security/app_lock_controller.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/state/circles_refresh_notifier.dart';
import '../../core/state/links_refresh_notifier.dart';
import '../../core/state/notifications_refresh_notifier.dart';
import '../../data/datasources/payspin_api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bank_account_repository_impl.dart';
import '../../data/repositories/circle_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../data/repositories/payment_link_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../../domain/usecases/complete_onboarding_usecase.dart';
import '../../domain/usecases/validate_iban_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../presentation/onboarding/onboarding_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton(PayspinApiClient.new);
  sl.registerLazySingleton(LinksRefreshNotifier.new);
  sl.registerLazySingleton(CirclesRefreshNotifier.new);
  sl.registerLazySingleton(NotificationsRefreshNotifier.new);
  sl.registerLazySingleton(RemoteConfigService.new);
  sl.registerLazySingleton(AppLockService.new);
  sl.registerLazySingleton(() => AppLockController(sl()));
  sl.registerLazySingleton(() => PhoneAuthService(sl()));
  sl.registerLazySingleton(() => PushService(sl(), sl(), sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<BankAccountRepository>(() => BankAccountRepositoryImpl(sl()));
  sl.registerLazySingleton<PaymentLinkRepository>(
    () => PaymentLinkRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<CircleRepository>(
    () => CircleRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<OnboardingRepository>(OnboardingRepositoryImpl.new);
  sl.registerLazySingleton(VerifyOtpUseCase.new);
  sl.registerLazySingleton(ValidateIbanUseCase.new);
  sl.registerLazySingleton(
    () => CompleteOnboardingUseCase(
      authRepository: sl(),
      bankAccountRepository: sl(),
      onboardingRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => OnboardingCubit(
      verifyOtp: sl(),
      validateIban: sl(),
      completeOnboarding: sl(),
      authRepository: sl(),
    ),
  );
}
