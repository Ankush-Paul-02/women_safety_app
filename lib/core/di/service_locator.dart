import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../data/auth/repositories/auth_repository_impl.dart';
import '../../data/auth/sources/auth_remote_source.dart';
import '../../data/safety/repositories/safety_repository_impl.dart';
import '../../data/safety/services/location_service.dart';
import '../../data/safety/services/voice_monitoring_service.dart';
import '../../data/safety/sources/safety_remote_source.dart';
import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/usecases/confirm_verification_code.dart';
import '../../domain/auth/usecases/sign_out.dart';
import '../../domain/auth/usecases/verify_phone_number.dart';
import '../../domain/safety/repositories/safety_repository.dart';
import '../../domain/safety/usecases/safety_usecases.dart';
import '../../presentation/auth/viewmodels/auth_state_provider.dart';
import '../../presentation/home/viewmodels/home_state_provider.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // External
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data Sources
  sl.registerLazySingleton<AuthRemoteSource>(
    () => AuthRemoteSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => VerifyPhoneNumber(sl()));
  sl.registerLazySingleton(() => ConfirmVerificationCode(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // ViewModels / Providers
  sl.registerFactory(
    () => AuthStateProvider(
      verifyPhoneNumberUseCase: sl(),
      confirmVerificationCodeUseCase: sl(),
      signOutUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // Safety Services
  sl.registerLazySingleton(() => LocationService());
  sl.registerLazySingleton(() => VoiceMonitoringService());

  // Safety Data Sources & Repositories
  sl.registerLazySingleton<SafetyRemoteSource>(
    () => SafetyRemoteSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<SafetyRepository>(
    () => SafetyRepositoryImpl(remoteSource: sl(), locationService: sl()),
  );

  // Safety Use Cases
  sl.registerLazySingleton(() => WatchEmergencyContacts(sl()));
  sl.registerLazySingleton(() => AddEmergencyContact(sl()));
  sl.registerLazySingleton(() => RemoveEmergencyContact(sl()));
  sl.registerLazySingleton(() => TriggerSosAlert(sl()));

  // Home ViewModel
  sl.registerFactory(
    () => HomeStateProvider(
      watchContactsUseCase: sl(),
      addContactUseCase: sl(),
      removeContactUseCase: sl(),
      triggerSosUseCase: sl(),
      voiceService: sl(),
    ),
  );
}
