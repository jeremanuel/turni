import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../../presentation/admin/client_page/client_page.dart';
import '../../../presentation/admin/clients_list/bloc/clients_list_bloc.dart';
import '../../../presentation/admin/clients_list/clients_list_page.dart';
import '../../../presentation/admin/clients_list/list_utils/client_list_filters.dart';
import '../../../presentation/admin/states/scaffold_cubit/scaffold_cubit.dart';
import '../../utils/responsive_builder.dart';
import '../service_locator.dart';
import 'app_routes.dart';
import 'router_utils.dart';

List<StatefulShellBranch> clientsBranches(GlobalKey<ScaffoldState> scaffoldKey) => [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/clients',
        name: 'CLIENTS_LIST_ROUTE',
        redirect: setCurrentRoute,
        builder: (context, state) {
          final params = state.uri.queryParameters ?? {};
          return BlocProvider(
            create: (context) => ClientsListBloc(
              context,
              sl<AdminRepository>(),
              ClientListFilters.fromJson(params),
              params['sort'],
              bool.tryParse(params['order'] ?? ''),
            ),
            child: ClientsList(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.CLIENT_ROUTE.path,
        name: AppRoutes.CLIENT_ROUTE.name,
        redirect: (context, state) {
          final extraMap = state.extra as Map?;
          final clientFromList = extraMap?['client'] as Client?;
          if (ResponsiveBuilder.isMobile(context)) return null;
          scaffoldKey.currentState?.openEndDrawer();
          final scaffoldCubit = sl<ScaffoldCubit>();
          final clientId = int.tryParse(state.pathParameters['clientId'] ?? '');
          if (clientId != null) {
            scaffoldCubit.setChild(
              Clientpage(
                clientId: clientId,
                client: clientFromList,
                onUpdateClient: (p0) {},
              ),
            );
          }
          return null;
        },
      ),
      GoRoute(
        path: AppRoutes.NEW_CLIENT_ROUTE.path,
        name: AppRoutes.NEW_CLIENT_ROUTE.name,
        redirect: (context, state) {
          final extraMap = state.extra as Map?;
          final onNewClient = extraMap?['onClientCreated'] as Function(Client)?;
          if (ResponsiveBuilder.isMobile(context)) return null;
          scaffoldKey.currentState?.openEndDrawer();
          final scaffoldCubit = sl<ScaffoldCubit>();
          scaffoldCubit.setChild(
            Clientpage(
              clientId: -1,
              createNewClient: true,
              onUpdateClient: (client) => onNewClient?.call(client),
            ),
          );
          return null;
        },
      ),
    ],
  ),
];