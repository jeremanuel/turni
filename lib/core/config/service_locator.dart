import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/club_type.dart';
import '../utils/dio_init.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usercases/auth_user_cases.dart';
import '../../infrastructure/api/providers/auth_provider.dart';
import '../../infrastructure/api/repositories/auth_repository_impl.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../../presentation/feed/cubit/feed/feed_cubit.dart';
import '../../presentation/home/cubit/home_cubit.dart';
import '../../presentation/session_feed/cubit/session_cubit.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static initializeDependencies() {
    final dio = DioInit.init(); // Inicializamos instancia de DIO.
    sl.registerSingleton<Dio>(dio); // La registramos como singleton.

    sl.registerSingleton<AuthRepository>(
        AuthRepositoryImpl(authProvider: AuthProvider()));

    sl.registerSingleton<AuthCubit>(AuthCubit(AuthUserCases(
        sl<AuthRepository>()))); // Cubit singleton para manejo de la sesion.

    sl.registerLazySingleton<FeedCubit>(() => FeedCubit());

    sl.registerLazySingleton<HomeCubit>(() => HomeCubit());

    sl.registerLazySingleton<SessionCubit>(() => SessionCubit());
  }
}
