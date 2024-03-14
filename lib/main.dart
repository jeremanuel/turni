import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';


import 'package:turni/core/config/app_router.dart';
import 'package:turni/core/config/environment.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

void main() async {

  await Environment.initEnvironment();
  ServiceLocator.initializeDependencies();
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

  
  runApp( const MyApp() );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    final isAdmin = sl<AuthCubit>().isAdmin();

    return MaterialApp.router(
      routerConfig: buildGoRouter(isAdmin ? RouterType.adminRoute : RouterType.clientRoute),
      debugShowCheckedModeBanner: false,
      title: 'Turni',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff672bea), brightness: Brightness.dark),
        useMaterial3: true,
      ),
    );
  }
}
