import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../core/presentation/components/inputs/LabelChip.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/label.dart';
import '../../../../domain/entities/request/page_response.dart';
import '../../../../domain/repositories/admin_repository.dart';
import 'client_list_filters.dart';

class ClientsDataSourceSf extends DataGridSource  {

  PageResponse<Client> currentPageInfo = PageResponse(15, []);
  List<DataGridRow>? clientRows;
  DataPagerController dataPagerController = DataPagerController();
  ClientListFilters filters;
  final AdminRepository _adminRepository;
  bool isFirstLoad = true;
  final ValueNotifier<double> pageCountNotifier = ValueNotifier<double>(1);

  ClientsDataSourceSf(this._adminRepository, this.filters);

  @override
  List<DataGridRow> get rows => clientRows ?? [];

  double get pageCount => ((currentPageInfo?.total ?? 1) / 15).ceilToDouble();

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    
    final cells = row.getCells();

    List<Label> labels = cells[5].value;

    return DataGridRowAdapter(
      cells: [
        Center(
          child:Text(cells[0].value.toString())
        ),
        Row(
          spacing: 8,
          children: [
            CircleAvatar(
              child: Text(cells[1].value.toString().characters.first),
            ),
            Expanded(child: Text(cells[1].value.toString(), overflow: TextOverflow.ellipsis,))
          ]
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(cells[2].value.toString())
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(cells[3].value.toString())
        ),
        Chip(
          label: const Text("Activo", style: TextStyle(color:Colors.white )),
          backgroundColor: Colors.green.shade600,
          visualDensity: const VisualDensity(vertical: -4),
          side: BorderSide.none,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: labels.map((e) => Labelchip(e)).toList()
          ),
        )

      ]
    );

  }
  
  @override
  Future<bool> handlePageChange(int oldPageIndex, int newPageIndex) async {
    if (isFirstLoad) {
      isFirstLoad = false;
      return true;
    }

    final response = await _adminRepository.getClients(filters.search ?? '', newPageIndex + 1);
    
    final list = response.whenOrNull(
      right: (pageInfo) => pageInfo.data,
      left: (error) => null
    );
    
    if (list == null) return false;

    clientRows = list.map(clientToRow).toList();

    response.whenOrNull(
      right: (pageInfo) {
        currentPageInfo = pageInfo;
        pageCountNotifier.value = pageCount;
      },
    );

    notifyListeners();

    return true;
  }

  DataGridRow clientToRow(Client client){
    return DataGridRow(
      cells: [ 
        DataGridCell(columnName: "id", value: client.clientId ?? ''), 
        DataGridCell(columnName: "name", value: client.person?.fullName ?? ''), 
        DataGridCell(columnName: "phone", value: client.person?.phone ?? ''), 
        DataGridCell(columnName: "email", value: client.person?.email ?? ''), 
        DataGridCell(columnName: "status", value: "client"), 
        DataGridCell<List>(columnName: "labels", value: client.labels)
      ]);
  }

}
/* 
buildLabels(Client client) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 8,
                            children: client.labels.map((e) => Labelchip(e)).toList() 
                          ),
                        ); */