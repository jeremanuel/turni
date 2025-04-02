import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/config/app_router.dart';
import 'core/config/environment.dart';
import 'core/config/service_locator.dart';
import 'presentation/admin/states/scaffold_cubit/scaffold_cubit.dart';
import 'presentation/core/cubit/auth/auth_cubit.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  await Environment.initEnvironment();
  ServiceLocator.initializeDependencies();
  await initializeDateFormatting('es');

  Intl.defaultLocale = 'es';
  //usePathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final localization = sl<FlutterLocalization>();
    //usePathUrlStrategy();
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: sl<AuthCubit>(),
      buildWhen: (previous, current) =>
          previous.userCredential?.isAdmin != current.userCredential?.isAdmin,
      builder: (context, state) {
        final isAdmin = sl<AuthCubit>().isAdmin();
        return MaterialApp.router(
          localizationsDelegates: localization.localizationsDelegates,
          supportedLocales: localization.supportedLocales,
          routerConfig: buildGoRouter(
              isAdmin ? RouterType.adminRoute : RouterType.clientRoute),
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
