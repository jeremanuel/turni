import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
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
  //usePathUrlStrategy();

  runApp( MyApp());
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  final routerConfig = buildGoRouter(RouterType.adminRoute);

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
      },
    );
  }
}
