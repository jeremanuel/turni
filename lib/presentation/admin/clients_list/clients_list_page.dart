// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/presentation/components/paginated_table/paginated_table.dart';
import '../../../core/prototypes/trina_grid_prototype.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/client.dart';
import 'bloc/clients_list_bloc.dart';
import 'widgets/client_list_filters_container.dart';
import 'widgets/client_list_header.dart';

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

  void _onDataSourceChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final clientsBloc = BlocProvider.of<ClientsListBloc>(context);
    
    final child = Column(
        children: [
          if(ResponsiveBuilder.isDesktop(context)) ClientListHeader(),
          ClientListFiltersContainer(),
          Expanded(
            child: PaginatedTable<Client>(
              columns: getColumns(),
              dataSource: clientsBloc.state.dataSource,
              onTap: (row, Client client) => context.goNamed(AppRoutes.CLIENT_ROUTE.name, extra: {"client":client, "bloc":context.read<ClientsListBloc>()}, pathParameters: {"clientId":client.clientId!}),
            ),
          ),
        ],
      );

    if(ResponsiveBuilder.isDesktop(context)) return child;

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(onPressed: () => context.goNamed(AppRoutes.NEW_CLIENT_ROUTE.name, extra: context.read<ClientsListBloc>()), tooltip: "Nuevo cliente", child: Icon(Icons.person_add_alt_1_rounded), ),
      body: child,
    );
  }

  List<GridColumn> getColumns() {

    final mobileColumns = [
      GridColumn(columnName: "name", label: const ColumnWrapper(padding: EdgeInsets.only(left: 16),child: Text("Cliente"),), width: 200,),
      GridColumn(columnName: "phone", label: const ColumnWrapper(child: Text("Telefono")), width: 150),
      GridColumn(columnName: "labels", label: const ColumnWrapper(child: Text("Etiquetas")), columnWidthMode: ColumnWidthMode.fill)
    ];

    final desktopColumns = [
      GridColumn(columnName: "id", label: const ColumnWrapper(child: Center(child: Text("ID"))),  width: 80),
      GridColumn(columnName: "name", label: const ColumnWrapper(child: Text("Cliente")), width: 300),
      GridColumn(columnName: "phone", label: const ColumnWrapper(child: Text("Telefono")), width: 200),
      GridColumn(columnName: "email", label: const ColumnWrapper(child: Text("Email")), width: 350),
      GridColumn(columnName: "labels", label: const ColumnWrapper(child: Text("Etiquetas")), columnWidthMode: ColumnWidthMode.fill)
    ];

    return ResponsiveBuilder.isMobile(context) ? mobileColumns : desktopColumns;

  }

  List<GridColumn> get buildColumns {
    return [
      GridColumn(
        width: 80,
        columnName: "id", 
        label: tinyColumnWrapper(Text("ID")),
      ),
      GridColumn(columnName: "name", label: columnWrapper(Text("Nombre"))), 
      GridColumn(columnName: "phone", label: columnWrapper(Text("Telefono"))),
      GridColumn(columnName: "email", label: columnWrapper(Text("Email"))),
      GridColumn(width: 110, columnName: "status", label: tinyColumnWrapper(Text("Estado"))),
      GridColumn(columnName: "labels", label: columnWrapper(Text("Etiquetas"))),
    ];
  }
}

columnWrapper(Text text) => Column(
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Align(alignment: Alignment.centerLeft, child: text),
      ),
    ),
    Divider(height: 1),
  ],
);

tinyColumnWrapper(Text text) => Column(
  children: [
    Expanded(
      child: Center(child: text),
    ),
    Divider(height: 1),
  ],
);