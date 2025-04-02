import 'package:dio/dio.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/ia_repository.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/label_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usercases/session_user_cases.dart';
import '../../infrastructure/api/providers/admin_provider.dart';
import '../../infrastructure/api/providers/session_provider.dart';
import '../../infrastructure/api/repositories/IA/gemini_repository.dart';
import '../../infrastructure/api/repositories/admin_repository_impl.dart';
import '../../infrastructure/api/repositories/label_repository_impl.dart';
import '../../infrastructure/api/repositories/payment_repository_impl.dart';
import '../../infrastructure/api/repositories/session_repository_impl.dart';
import '../../infrastructure/api/repositories/subscription_repository_impl.dart';
import '../../presentation/admin/states/global_data/global_data_cubit.dart';
import '../../presentation/admin/states/scaffold_cubit/scaffold_cubit.dart';
import '../../presentation/client/bloc/client_session_manager_bloc.dart';
import '../utils/dio_init.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usercases/auth_user_cases.dart';
import '../../infrastructure/api/providers/auth_provider.dart';
import '../../infrastructure/api/repositories/auth_repository_impl.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../../presentation/client/home_manager_screen/home/cubit/home_cubit.dart';

import '../../presentation/admin/create_session_screen/bloc/create_sesssions_form_bloc.dart';
import '../../presentation/admin/session_manager_screen/bloc/session_manager_bloc.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static initializeDependencies() {
    final dio = DioInit.init(); // Inicializamos instancia de DIO.
    sl.registerSingleton<Dio>(dio); // La registramos como singleton.

    sl.registerSingleton<AuthRepository>(
        AuthRepositoryImpl(authProvider: AuthProvider()));
    
    sl.registerSingleton<PaymentRepository>(PaymentRepositoryImpl());

    sl.registerSingleton<LabelRepository>(LabelRepositoryImpl());

    sl.registerSingleton<SubscriptionRepository>(SubscriptionRepositoryImpl());


    sl.registerSingleton<AdminRepository>(
    AdminrepositroyImpl(adminProvider: AdminProvider())
    );

    sl.registerSingleton<SessionRepository>(SessionRepositoryImplementation(sessionProvider: SessionProvider()));

    sl.registerSingleton<AuthCubit>(
      AuthCubit(
        AuthUserCases(sl<AuthRepository>()))
    ); // Cubit singleton para manejo de la sesion.

    sl.registerSingleton<ScaffoldCubit>(
      ScaffoldCubit()
    ); // Cubit singleton para manejo de la sesion.

    sl.registerLazySingleton<GlobalDataCubit>(() {
      return GlobalDataCubit(sl<LabelRepository>());
    });


    //sl.registerLazySingleton<FeedCubit>(() => FeedCubit());

    sl.registerLazySingleton<CreateSesssionsFormBloc>(() => CreateSesssionsFormBloc());

    sl.registerLazySingleton<HomeCubit>(() => HomeCubit());
    sl.registerLazySingleton<ClientSessionManagerBloc>(
        () => ClientSessionManagerBloc());

    sl.registerLazySingleton<IARepository>(
      () => GeminiRepository(), 
    ); 

    sl.registerFactoryParam<SessionManagerBloc, int?, void>((sessionId, _) => SessionManagerBloc(sessionId, SessionUserCases(sl<SessionRepository>())));


    _initializeLocalization();
  }

  static _initializeLocalization() async {
    final FlutterLocalization localization = FlutterLocalization.instance;
    await FlutterLocalization.instance.ensureInitialized();

    localization.init(mapLocales: [
      const MapLocale('es', {'title': 'Localizacion'})
    ], initLanguageCode: 'es');

    sl.registerSingleton(localization);
  }

}
