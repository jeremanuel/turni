
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_routes.dart';
import '../../../../core/presentation/components/inputs/label_chip.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/client.dart';

class ClientsDataRow extends DataRow2 {

  final Client client;
  final BuildContext context;

  ClientsDataRow(this.context, this.client) 
  : super(
    onTap: () => context.goNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {"clientId":client.clientId!}, extra: client),
    cells: _buildCells(client, Theme.of(context).colorScheme, context), 
    color: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerLow)
  );

  static List<DataCell> _buildCells(Client client, ColorScheme colorScheme, context) {
    
    final mobileList = [
                DataCell(
                  Text(client.clientId!)
                ),
                DataCell(
                  
                  Text(client.person!.fullName, overflow: TextOverflow.ellipsis,)
                ),
            
                DataCell(
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: client.labels?.map((e) => Labelchip(e)).toList() ?? []
                    ),
                  )
                )
            ];
            
    final desktopList = [
                DataCell(
                  Text(client.clientId!)
                ),
                DataCell(
                  Row(
                    spacing: 8,
                    children: [
                      CircleAvatar(
                        child: Text(client.person!.fullName.characters.first),
                      ),
                      Expanded(child: Text(client.person!.fullName, overflow: TextOverflow.ellipsis,))
                    ]
                  )
                ),
     
                DataCell(
                  Text(client.person?.phone ?? '')
                ),
                DataCell(
                  Text(client.person?.email ?? '')
                ),
                DataCell(
                  Chip(
                    label: const Text("Activo", style: TextStyle(color:Colors.white )),
                    backgroundColor: Colors.green.shade600,
                    visualDensity: const VisualDensity(vertical: -4),
                    side: BorderSide.none,
                  )
                ),
                DataCell(
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: client.labels?.map((e) => Labelchip(e)).toList() ?? []
                    ),
                  )
                )
            ];

    return ResponsiveBuilder.isMobile(context) ? mobileList : desktopList;
  }


}