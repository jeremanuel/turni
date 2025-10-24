import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/config/app_router.dart';
import 'core/config/environment.dart';
import 'core/config/service_locator.dart';
import 'presentation/core/cubit/auth/auth_cubit.dart';

void main() async {
  await Environment.initEnvironment();
  ServiceLocator.initializeDependencies();
  await initializeDateFormatting('es');

  Intl.defaultLocale = 'es';
  //usePathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late RouterConfig<Object> routerConfig;
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _isAdmin = sl<AuthCubit>().isAdmin();
    routerConfig = buildGoRouter(_isAdmin! ? RouterType.adminRoute : RouterType.clientRoute);
    sl<AuthCubit>().stream.listen((state) {
      final isAdmin = sl<AuthCubit>().isAdmin();
      if (isAdmin != _isAdmin) {
        setState(() {
          _isAdmin = isAdmin;
          routerConfig = buildGoRouter(_isAdmin! ? RouterType.adminRoute : RouterType.clientRoute);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = sl<FlutterLocalization>();
    return MaterialApp.router(
      localizationsDelegates: localization.localizationsDelegates,
      supportedLocales: localization.supportedLocales,
      routerConfig: routerConfig,
      debugShowCheckedModeBanner: false,
      title: 'Turni',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff672bea),
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
    );
  }

}
