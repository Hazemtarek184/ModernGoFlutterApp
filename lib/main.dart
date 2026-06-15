import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

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

import 'package:modern_go/features/auth/presentation/pages/server_config_page.dart';
import 'package:modern_go/core/constants/api_constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  const storage = FlutterSecureStorage();
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
  sl.registerFactory(() => CartBloc(socketService: sl()));

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

  final storage = sl<FlutterSecureStorage>();
  final serverUrl = await storage.read(key: 'server_url');
  final socketUrl = await storage.read(key: 'socket_url');

  bool isConfigured = false;
  if (serverUrl != null && serverUrl.isNotEmpty) {
    ApiConstants.baseUrl = serverUrl;
    ApiConstants.socketUrl = socketUrl ?? '';
    isConfigured = true;
  }

  runApp(ModernGoApp(isConfigured: isConfigured));
}

class ModernGoApp extends StatelessWidget {
  final bool isConfigured;

  const ModernGoApp({super.key, required this.isConfigured});

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
        home: isConfigured ? const SplashPage() : const ServerConfigPage(),
      ),
    );
  }
}

