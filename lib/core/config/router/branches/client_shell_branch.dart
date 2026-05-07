import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/admin/client_page/client_page.dart';
import '../../../../presentation/admin/clients_list/clients_list_page.dart' deferred as list;
import '../../../../presentation/admin/clients_list/bloc/clients_list_bloc.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../../presentation/admin/clients_list/list_utils/client_list_filters.dart';
import '../../../../presentation/admin/routines/new_routine_page.dart';
import '../../service_locator.dart';
import '../app_router.dart';
import '../app_routes.dart';
import '../../../utils/responsive_builder.dart';
import '../../../../domain/entities/client.dart';
import '../../../../presentation/admin/states/scaffold_cubit/scaffold_cubit.dart';

final GlobalKey navigatorKey = GlobalKey<NavigatorState>();
StatefulShellBranch clientShellBranch() {
  return StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.CLIENTS_LIST_ROUTE.path,
          name: AppRoutes.CLIENTS_LIST_ROUTE.name,
          redirect: setCurrentRoute,
          builder: (context, state){

            final params = state.uri.queryParameters;
            
            return FutureBuilder(
              future: list.loadLibrary(),
              builder:(context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if(snapshot.hasError) {
                  return const Center(child: Text("Error al cargar la página"));
                }
                return BlocProvider( 
                create: (context) => ClientsListBloc(context, sl<AdminRepository>(), ClientListFilters.fromJson(params), params['sort'], bool.tryParse(params['order'] ?? '')),
                child: list.ClientsList(),
              );
              }
            
            );
          },
          routes: [


            
          GoRoute(
          path: AppRoutes.CLIENT_ROUTE.path,
          name: AppRoutes.CLIENT_ROUTE.name,
/*           redirect: (context, state) {  
            
            final extraMap = state.extra as Map?;
            final clientFromList = extraMap?['client'] as Client?;

            if(ResponsiveBuilder.isMobile(context)) return null;

            scaffoldKey.currentState?.openEndDrawer();
          
            final scaffoldCubit = sl<ScaffoldCubit>();

            final clientId = int.tryParse(
              state.pathParameters['clientId'] ?? '',
            );

            if(clientId != null) {
              scaffoldCubit.setChild(
                Clientpage(clientId: clientId, client: clientFromList, onUpdateClient: (p0) {}));
            }

            return currentRoute ?? AppRoutes.CLIENTS_LIST_ROUTE.path;
          }, */
          builder: (context, state){

            //if(ResponsiveBuilder.isDesktop(context)) return const SizedBox();

            final extraMap = state.extra as Map?;
            final clientFromList = extraMap?['client'] as Client?;
            final onUpdateClient = extraMap?['onUpdateClient'] as Function(Client)?;

            final clientId = int.tryParse(
              state.pathParameters['clientId'] ?? '',
            );

            return Clientpage(clientId: clientId!, client: clientFromList, onUpdateClient: onUpdateClient ?? (p0) {});
          },
          routes: [
            
          ]
          ),
          GoRoute(
              path: AppRoutes.NEW_ROUTINE_ROUTE.path,
              name: AppRoutes.NEW_ROUTINE_ROUTE.name,
              redirect: (context, state) {
               
                if(ResponsiveBuilder.isMobile(context)) return null;

                scaffoldKey.currentState?.openEndDrawer();
                final scaffoldCubit = sl<ScaffoldCubit>();

                final extraMap = state.extra as Map?;
                final client = extraMap?['client'] as Client?;

                final clientId = int.tryParse(
                  state.pathParameters['clientId'] ?? '',
                );

                scaffoldCubit.setChild(NewRoutinePage(client: client, clientId: clientId!));

                return currentRoute ?? AppRoutes.CLIENTS_LIST_ROUTE.path;
              },
              builder: (context, state) {
                
                if(ResponsiveBuilder.isDesktop(context)) return const SizedBox();

                final extraMap = state.extra as Map?;
                final client = extraMap?['client'] as Client?;

                final clientId = int.tryParse(
                  state.pathParameters['clientId'] ?? '',
                );

                return NewRoutinePage(client: client, clientId: clientId!);
              },
            )
          ]
       
        ),
        

        
        GoRoute(
          path: AppRoutes.NEW_CLIENT_ROUTE.path,
          name: AppRoutes.NEW_CLIENT_ROUTE.name,
         
/*           redirect: (context, state) {  


            if(ResponsiveBuilder.isMobile(context)) return null;

            scaffoldKey.currentState?.openEndDrawer();
            print(scaffoldKey.currentState);

            final scaffoldCubit = sl<ScaffoldCubit>();

            scaffoldCubit.setChild(BlocProvider.value(
              value: state.extra as Bloc,
              child:  Clientpage(clientId: -1, createNewClient: true, onUpdateClient: (p0) {
                
              },)));
       
           return currentRoute ?? AppRoutes.CLIENTS_LIST_ROUTE.path;
          }, */
          builder: (context, state){

            final extraMap = state.extra as Map?;
            final onUpdateClient = extraMap?['onClientCreated'] as Function(Client)?;



            return Clientpage(clientId: -1, createNewClient: true, onUpdateClient: onUpdateClient);
          },
        ),

    ]);
}
