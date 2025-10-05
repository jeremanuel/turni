// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/presentation/components/inputs/label_chip.dart';
import '../../../core/presentation/components/paginated_table/paginated_table.dart';
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
  late final TrinaGridStateManager _stateManager;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

/* 
        child: PaginatedTable<Client>(
              columns: getColumns(),
              dataSource: clientsBloc.state.dataSource,
              onTap: (row, Client client) => context.goNamed(AppRoutes.CLIENT_ROUTE.name, extra: {"client":client, "bloc":context.read<ClientsListBloc>()}, pathParameters: {"clientId":client.clientId!}),
            ),

 */

  @override
  Widget build(BuildContext context) {
    final clientsBloc = BlocProvider.of<ClientsListBloc>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    final child = Column(
        children: [
          if(ResponsiveBuilder.isDesktop(context)) ClientListHeader(),
          ClientListFiltersContainer(),
          Expanded(
            child: TrinaGrid(
              configuration: TrinaGridConfiguration.dark(
                localeText: TrinaGridLocaleText.spanish(),
                style: TrinaGridStyleConfig(
                    iconColor: colorScheme.onSurfaceVariant,
                    gridBorderColor: Colors.transparent,
                    gridBorderWidth: 0,
                    enableCellBorderVertical: false,
                    enableColumnBorderVertical: false,
                    enableColumnBorderHorizontal: false,
                    activatedColor: colorScheme.primary.withValues(alpha:0.1),
                    cellActiveColor: Colors.transparent,
                    activatedBorderColor: colorScheme.primary,
                    borderColor: colorScheme.outlineVariant,
                    gridBackgroundColor: colorScheme.surfaceContainer,
                    menuBackgroundColor: colorScheme.surface,
                    rowColor: colorScheme.surfaceContainer,
                    cellTextStyle: TextStyle(color: colorScheme.onSurface,),
                    columnTextStyle: TextStyle(color: colorScheme.onSurface,),
                    columnAscendingIcon: Icon(Icons.arrow_upward),
                    columnDescendingIcon: Icon(Icons.arrow_downward),
                    evenRowColor: colorScheme.surfaceContainerLow,
                    dragTargetColumnColor: colorScheme.primary,
                    
                    
                    
                ),
                columnSize: TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.scale),
              ),
              columns: getTrinaColumns(),
              rows: [],
              onLoaded: (event) => _stateManager = event.stateManager..showSetColumnsPopup(context),
              createFooter: (stateManager) => TrinaLazyPagination(
                enableGotoPage: false,
                
                stateManager: stateManager,
                pageSizes: [10, 20, 50, 100],
                fetch: (data) async {
                  final data = await clientsBloc.fetchClients(1);

                  return TrinaLazyPaginationResponse(
                    totalPage: data.total,
                    rows: data.data.map((e) {
                      return TrinaRow(
                        cells: {
                          "id": TrinaCell(value: e.clientId ?? '',),
                          "name": TrinaCell(value: e.person?.fullName ?? ''),
                          "phone": TrinaCell(value: e.person?.phone ?? ''),
                          "email": TrinaCell(value: e.person?.email ?? ''),
                          "labels": TrinaCell(renderer: (rendererContext) {
                            if(e.labels == null) return SizedBox();

                            return Row(
                              children: [
                                ...e.labels!.map((label) => Labelchip(label))
                              ],
                            );
                          },),
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

    if(ResponsiveBuilder.isDesktop(context)) return child;

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(onPressed: () => context.goNamed(AppRoutes.NEW_CLIENT_ROUTE.name, extra: context.read<ClientsListBloc>()), tooltip: "Nuevo cliente", child: Icon(Icons.person_add_alt_1_rounded), ),
      body: child,
    );
  }
  List<TrinaColumn> getTrinaColumns() {
    final mobileColumns = [
      TrinaColumn(title: "Cliente", field: "name", type: TrinaColumnType.text(), width: 200),
      TrinaColumn(title: "Telefono", field: "phone", type: TrinaColumnType.text(), width: 150),
      TrinaColumn(title: "Etiquetas", field: "labels", type: TrinaColumnType.text(), width: 150),
    ];

    final desktopColumns = [
      TrinaColumn(title: "ID", field: "id", type: TrinaColumnType.text(), width: 80, enableEditingMode: false, ),
      TrinaColumn(title: "Cliente", field: "name", type: TrinaColumnType.text(), width: 300, enableEditingMode: false),
      TrinaColumn(title: "Telefono", field: "phone", type: TrinaColumnType.text(), enableEditingMode: false),
      TrinaColumn(title: "Email", field: "email", type: TrinaColumnType.text(), width: 350, enableEditingMode: false),
      TrinaColumn(title: "Etiquetas", field: "labels", type: TrinaColumnType.text(),  minWidth: 500, enableEditingMode: false),
    ];

    return ResponsiveBuilder.isMobile(context) ? mobileColumns : desktopColumns;
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