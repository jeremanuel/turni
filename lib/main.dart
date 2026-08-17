import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:turni/core/config/app_router.dart';
import 'package:turni/core/config/environment.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/services/push_notification_service.dart';
import 'package:turni/infrastructure/localstorage/provider/local_storage.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

// Token de un admin real de dev, impreso por `npm run seed:dev` en
// turni_mono_be (bloque "--dart-define flag (para arrancar la app admin
// logueada, turni)"). Si se pasa por --dart-define, se precarga en
// LocalStorage antes de que AuthCheck.checkAuthStatus() (llamado en el primer
// frame, ver check_status_page.dart) lo lea — deja la app ya logueada como
// ese admin, sin pasar por Google Sign-In. Vacío por default: no afecta el
// arranque normal.
const _devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.initEnvironment();
  ServiceLocator.initializeDependencies();
  await initializeDateFormatting('es');

  if (_devAdminToken.isNotEmpty) {
    await LocalStorage.save(LocalStorage.TOKEN_KEY, _devAdminToken);
  }

  Intl.defaultLocale = 'es';
  //usePathUrlStrategy();

  // Sin credenciales reales de Firebase todavía (ver instrucciones en
  // push_notification_service.dart), esto es un no-op silencioso: no
  // bloquea ni rompe el arranque de la app.
  await PushNotificationService.initializeFirebase();
  PushNotificationService.setupMessageHandlers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final localization = sl<FlutterLocalization>();

    return BlocBuilder<AuthCubit, AuthState>(
      bloc: sl<AuthCubit>(),
      buildWhen: (previous, current) =>
          previous.userCredential?.isAdmin != current.userCredential?.isAdmin,
      builder: (context, state) {
        final isAdmin = sl<AuthCubit>().isAdmin();
        final router = buildGoRouter(
            isAdmin ? RouterType.adminRoute : RouterType.clientRoute);
        // Registrado (y re-registrado cada vez que este router se
        // reconstruye) para que AuthCubit pueda forzar un refresh explícito
        // del redirect tras loguear/desloguear (ver auth_cubit.dart) —
        // depender solo del `refreshListenable` implícito podía dejar la
        // navegación pegada en "/" o "/login" en algunos casos, mismo fix
        // ya aplicado en turni_client.
        if (sl.isRegistered<GoRouter>()) {
          sl.unregister<GoRouter>();
        }
        sl.registerSingleton<GoRouter>(router);

        return MaterialApp.router(
          localizationsDelegates: localization.localizationsDelegates,
          supportedLocales: localization.supportedLocales,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          title: 'Turni',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff672bea),
                brightness: Brightness.dark),
            useMaterial3: true,
          ),
        );
      },
    );
  }
}
