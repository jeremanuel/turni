

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:turni/core/cubit/auth/auth_cubit.dart';
import 'package:turni/core/utils/dio_init.dart';
import 'package:turni/presentation/feed/cubit/feed/feed_cubit.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static initializeDependencies() async {
    
    final dio = DioInit.init(); // Inicializamos instancia de DIO.
    sl.registerSingleton<Dio>(dio); // La registramos como singleton.

    sl.registerSingleton<AuthCubit>(AuthCubit()); // Cubit singleton para manejo de la sesion.

    sl.registerLazySingleton<FeedCubit>(() => FeedCubit()); 
     
  }
}