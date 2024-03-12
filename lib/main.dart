import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:turni/core/config/app_router.dart';
import 'package:turni/core/config/environment.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

void main() async {

  await Environment.initEnvironment();
  ServiceLocator.initializeDependencies();
  
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
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 32, 0, 212), brightness: Brightness.light),
        useMaterial3: true,
      ),
    );
  }
}
