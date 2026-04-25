import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../domain/entities/client.dart';
import '../bloc/clients_list_bloc.dart';

class ClientListHeader extends StatelessWidget {
  const ClientListHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final colorSchenme = Theme.of(context).colorScheme;


    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 20, right: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        color: colorSchenme.surfaceContainerHigh
      ),
      child: Row(
        spacing: 10,
        children: [
          const Text("Clientes"),
          const Spacer(),
          FilledButton(
            onPressed: () {
              context.goNamed(
                AppRoutes.NEW_CLIENT_ROUTE.name,
                  extra: {
                  //'onClientCreated': (Client client) => context.read<ClientsListBloc?>()?.state.dataSource.loadPage(context.read<ClientsListBloc>().state.dataSource.currentPage)
                }
              );
            }, 
            child: const Row(
              spacing: 8,
              children:[
                Icon(Icons.person_add_alt_1_rounded),
                Text("Nuevo cliente"),
              ],
            )),
        ],
      ),
    );
  }
}