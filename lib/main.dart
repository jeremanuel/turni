import 'package:flutter/material.dart';
import 'package:turni/core/config/app_router.dart';
import 'package:turni/core/config/environment.dart';
import 'package:turni/core/config/service_locator.dart';

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
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Turni',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
    );
  }
}
