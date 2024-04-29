

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:turni/core/utils/dio_init.dart';
import 'package:turni/domain/repositories/auth_repository.dart';
import 'package:turni/domain/usercases/auth_user_cases.dart';
import 'package:turni/infrastructure/api/providers/auth_provider.dart';
import 'package:turni/infrastructure/api/repositories/auth_repository_impl.dart';
import 'package:turni/infrastructure/localstorage/provider/local_storage.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/feed/cubit/feed/feed_cubit.dart';

import '../../presentation/admin/session_form/bloc/create_sesssions_form_bloc.dart';
import '../../presentation/admin/sessions_manager/blocs/bloc/session_manager_bloc.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static initializeDependencies()  {
    
    final dio = DioInit.init(); // Inicializamos instancia de DIO.
    sl.registerSingleton<Dio>(dio); // La registramos como singleton.

    sl.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        authProvider: AuthProvider()
      )
    );

    sl.registerSingleton<AuthCubit>(AuthCubit(
      AuthUserCases(
       sl<AuthRepository>()
      )
    )); // Cubit singleton para manejo de la sesion.

    sl.registerLazySingleton<FeedCubit>(() => FeedCubit()); 

    sl.registerLazySingleton<SessionManagerBloc>(() => SessionManagerBloc()); 
    sl.registerLazySingleton<CreateSesssionsFormBloc>(() => CreateSesssionsFormBloc()); 


  
  }
}

