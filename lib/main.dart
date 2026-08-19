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
import 'infrastructure/localstorage/provider/local_storage.dart';
import 'presentation/core/cubit/auth/auth_cubit.dart';

// Token de un admin real de dev, pasado por --dart-define-from-file=dev_define.json
// (o --dart-define=DEV_ADMIN_TOKEN=...). Si viene seteado, se precarga en
// LocalStorage antes de que AuthCheck.checkAuthStatus() (llamado en el primer
// frame, ver check_status_page.dart) lo lea — deja la app ya logueada como
// ese admin, sin pasar por Google Sign-In. Vacío por default: no afecta el
// arranque normal. Ver turni_mono_be/prisma/seed-dev.ts (bloque
// "DEV_ADMIN_TOKEN") para obtener un token nuevo si hace falta.
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
