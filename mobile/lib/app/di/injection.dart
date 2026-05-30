import 'package:get_it/get_it.dart';

import '../../data/datasources/payspin_api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bank_account_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../data/repositories/payment_link_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../../domain/usecases/complete_onboarding_usecase.dart';
import '../../domain/usecases/validate_iban_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../presentation/onboarding/onboarding_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton(PayspinApiClient.new);
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<BankAccountRepository>(() => BankAccountRepositoryImpl(sl()));
  sl.registerLazySingleton<PaymentLinkRepository>(() => PaymentLinkRepositoryImpl(sl()));
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
    ),
  );
}
