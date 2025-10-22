// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/presentation/components/custom_trina_grid/custom_trina_grid.dart';
import '../../../core/presentation/components/inputs/label_chip.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/client.dart';
import '../client_page/widgets/add_payment_button.dart';
import 'bloc/clients_list_bloc.dart';
import 'widgets/client_list_filters_container.dart';


class ClientsList extends StatefulWidget {
  const ClientsList({super.key});

  @override
  State<ClientsList> createState() => _ClientsListState();
}

class _ClientsListState extends State<ClientsList> {

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsBloc = BlocProvider.of<ClientsListBloc>(context);
    final child = Column(
      children: [
        ClientListFiltersContainer(),
        Expanded(
          child: CustomTrinaGrid(
            columns: getTrinaColumns(),
            rows: [],
            onLoaded: (event) => clientsBloc.stateManager = event.stateManager..setPageSize(15),
            createFooter: (stateManager) => TrinaLazyPagination(
              showTotalRows: false,
              enableGotoPage: false,
              initialPageSize: 15,
              stateManager: stateManager,
              
              fetch: (request) async {
                final data = await clientsBloc.fetchClients(request.page, request.sortColumn?.field, request.sortColumn?.sort.isAscending);
                return TrinaLazyPaginationResponse(
                    
                    totalRecords: data.total,
                    totalPage: (data.total / stateManager.pageSize).ceil(),
                    rows: data.data.map((e) {
                      return TrinaRow(
                        cells: {
                          "id": TrinaCell(value: e.clientId ?? '',),
                          "name": TrinaCell(value: e.person?.fullName ?? ''),
                          "phone": TrinaCell(value: e.person?.phone ?? ''),
                          "email": TrinaCell(value: e.person?.email ?? ''),
                          "labels": TrinaCell(renderer: (rendererContext) {
                            if(e.labels == null) return SizedBox();
    
                            return ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...e.labels!.map((label) => Padding(padding: EdgeInsetsGeometry.only(left: 4), child: Labelchip(label)))
                              ],
                            );
                          },),
                          'action': TrinaCell(
                            
                            renderer: (rendererContext) {
                            return Row(
                              spacing: 4,
                              children: [
                                AddPaymentButton(
                                  shortButton: true,
                                  client: e, 
                                  onPaymentCreated: (payment) {
    
                                    Future.delayed(const Duration(seconds: 3)).then((value) => clientsBloc.refetchClients());
                                    
                                  }
                                  ),
                                IconButton(
                                onPressed: () => context.goNamed(AppRoutes.CLIENT_ROUTE.name, extra: {"client":e, "bloc":context.read<ClientsListBloc>()}, pathParameters: {"clientId":e.clientId!}),
                                icon: Icon(Icons.edit, size: 16,),
                              )
                              ],
                            );
                          },)
                        }
                      );
                    }).toList(),
                  );
              },
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(AppRoutes.NEW_CLIENT_ROUTE.name, extra: context.read<ClientsListBloc>()),
        label: ResponsiveBuilder.isDesktop(context)
            ? Row(spacing: 8, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_add_alt_1_rounded), Text("Nuevo cliente")])
            : Icon(Icons.person_add_alt_1_rounded),
      ),
      body: child,
    );
  }
  List<TrinaColumn> getTrinaColumns() {
    final mobileColumns = [
      TrinaColumn(title: "Cliente", field: "name", type: TrinaColumnType.text(), enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "Telefono", field: "phone", type: TrinaColumnType.text(), width: 150, enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "Etiquetas", field: "labels", type: TrinaColumnType.text(), width: 150, enableEditingMode: false),
    ];

    final desktopColumns = [
      TrinaColumn(title: "ID", field: "id", type: TrinaColumnType.text(), width: 80, enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "Cliente", field: "name", type: TrinaColumnType.text(), width: 400, enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "Telefono", field: "phone", type: TrinaColumnType.text(), width: 300, enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "Email", field: "email", type: TrinaColumnType.text(), width: 400, enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "Etiquetas", field: "labels", type: TrinaColumnType.text(),  minWidth: 500, enableEditingMode: false, enableContextMenu: false),
      TrinaColumn(title: "", field: "action", type: TrinaColumnType.boolean(), width: 115, enableDropToResize: false, frozen: TrinaColumnFrozen.end)
    ];

    return ResponsiveBuilder.isMobile(context) ? mobileColumns : desktopColumns;
  }



}



