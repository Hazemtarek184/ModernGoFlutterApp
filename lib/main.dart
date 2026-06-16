import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/location_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/cart/data/services/socket_service.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/health_profile/data/datasources/health_profile_remote_data_source.dart';
import 'features/health_profile/data/repositories/health_profile_repository_impl.dart';
import 'features/health_profile/domain/repositories/health_profile_repository.dart';
import 'features/health_profile/domain/usecases/health_profile_usecases.dart';
import 'features/health_profile/presentation/bloc/health_profile_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  // resetOnError: true — if the keystore entry is gone after a reinstall
  // (common on Android), reset storage instead of throwing an exception.
  // encryptedSharedPreferences: false — use Android Keystore (not EncryptedSharedPrefs)
  // so that uninstall properly invalidates the keys.
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: true,
    ),
  );

  // Clear secure storage on first run to prevent keychain values persisting across fresh installs.
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('is_first_run') ?? true) {
    await storage.deleteAll();
    await prefs.setBool('is_first_run', false);
  }

  sl.registerLazySingleton(() => storage);
  sl.registerLazySingleton(() => Dio());

  // Core
  sl.registerLazySingleton(() => ApiClient(dio: sl(), storage: sl()));
  sl.registerLazySingleton(() => LocationService());

  // Features - Auth
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory(() => AuthBloc(authRepository: sl(), storage: sl()));

  // Features - Cart (Socket.IO)
  sl.registerLazySingleton(() => SocketService());
  sl.registerFactory(() => CartBloc(socketService: sl(), apiClient: sl()));

  // Features - Home
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));
  sl.registerLazySingleton(() => HomeBloc(
        homeRepository: sl(),
        locationService: sl(),
      ));

  // Features - Health Profile
  sl.registerLazySingleton<HealthProfileRemoteDataSource>(
      () => HealthProfileRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<HealthProfileRepository>(
      () => HealthProfileRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => GetHealthProfile(sl()));
  sl.registerLazySingleton(() => CreateHealthProfile(sl()));
  sl.registerLazySingleton(() => UpdateHealthProfile(sl()));
  sl.registerLazySingleton(() => DeleteHealthProfile(sl()));
  sl.registerFactory(() => HealthProfileBloc(
        getHealthProfile: sl(),
        createHealthProfile: sl(),
        updateHealthProfile: sl(),
        deleteHealthProfile: sl(),
      ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(const ModernGoApp());
}

class ModernGoApp extends StatelessWidget {
  const ModernGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<CartBloc>()),
        BlocProvider(create: (_) => sl<HealthProfileBloc>()),
      ],
      child: MaterialApp(
        title: 'Modern Go',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
