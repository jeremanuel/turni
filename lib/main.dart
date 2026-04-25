import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/config/router/app_router.dart';
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
    late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildGoRouter();
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
