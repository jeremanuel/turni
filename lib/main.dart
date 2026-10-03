import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/config/app_theme.dart';
import 'core/config/router/app_router.dart';
import 'core/config/environment.dart';
import 'core/config/service_locator.dart';
import 'core/services/push_notification_service.dart';
import 'infrastructure/localstorage/provider/local_storage.dart';
import 'presentation/core/cubit/auth/auth_cubit.dart';

// Token de un admin real de dev, impreso por `npm run seed:dev` en
// turni_mono_be (bloque "--dart-define flag (para arrancar la app admin
// logueada, turni)"), o pasado por --dart-define-from-file=dev_define.json.
// Si viene seteado, se precarga en LocalStorage antes de que
// AuthCheck.checkAuthStatus() (llamado en el primer frame, ver
// check_status_page.dart) lo lea — deja la app ya logueada como ese admin,
// sin pasar por Google Sign-In. Vacío por default: no afecta el arranque
// normal.
const _devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.initEnvironment();
  ServiceLocator.initializeDependencies();
  await initializeDateFormatting('es');

  Intl.defaultLocale = 'es';
  //usePathUrlStrategy();

  if (_devAdminToken.isNotEmpty) {
    await LocalStorage.save(LocalStorage.TOKEN_KEY, _devAdminToken);
  }

  // Sin credenciales reales de Firebase todavía (ver instrucciones en
  // push_notification_service.dart), esto es un no-op silencioso: no
  // bloquea ni rompe el arranque de la app.
  await PushNotificationService.initializeFirebase();
  PushNotificationService.setupMessageHandlers();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
    late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildGoRouter(RouterType.adminRoute);
    // Para que AuthCubit pueda forzar un refresh explícito del redirect tras
    // loguear/desloguear (ver auth_cubit.dart, _notifyRouter) — depender
    // solo del `refreshListenable` implícito puede dejar la navegación
    // pegada en "/" o "/login" en algunos casos, mismo fix ya aplicado en
    // turni_client.
    if (sl.isRegistered<GoRouter>()) {
      sl.unregister<GoRouter>();
    }
    sl.registerSingleton<GoRouter>(_router);
  }
  @override
  Widget build(BuildContext context) {
    final localization = sl<FlutterLocalization>();
    //usePathUrlStrategy();
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: sl<AuthCubit>(),
      buildWhen: (previous, current) =>
          previous.userCredential?.isAdmin != current.userCredential?.isAdmin,
      builder: (context, state) {
        return MaterialApp.router(
          localizationsDelegates: localization.localizationsDelegates,
          supportedLocales: localization.supportedLocales,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          title: 'Turni',
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
        );
      },
    );
  }

}
