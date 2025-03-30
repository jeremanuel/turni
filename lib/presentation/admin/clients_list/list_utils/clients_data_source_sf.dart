import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../core/presentation/components/inputs/LabelChip.dart';
import '../../../../core/presentation/components/paginated_table/paginated_table.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/label.dart';
import '../../../../domain/entities/request/page_response.dart';
import '../../../../domain/repositories/admin_repository.dart';
import 'client_list_filters.dart';

class ClientsDataSourceSf<Client> extends DataGridSourceCustomASource<Client>  {

  ClientListFilters filters;

  final AdminRepository _adminRepository;
  final BuildContext context;
  

  final ValueNotifier<double> pageCountNotifier = ValueNotifier<double>(1);

  ClientsDataSourceSf(this._adminRepository, this.filters, this.context);


  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    
    final cells = row.getCells();

    List<Label> labels = cells.last.value;


    if(ResponsiveBuilder.isMobile(context)) {
      return DataGridRowAdapter(
      cells: [
      
        Row(

          children: [
            SizedBox(width: 16),
            Text(cells[0].value.toString(), overflow: TextOverflow.ellipsis)
          ]
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(cells[1].value.toString())
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
  DataGridRow dataGridRowFromValue(dynamic client)  {

    if(ResponsiveBuilder.isMobile(context)){
      return DataGridRow(
      cells: [ 
        DataGridCell(columnName: "name", value: client.person?.fullName ?? ''), 
        DataGridCell(columnName: "phone", value: client.person?.phone ?? ''), 
        DataGridCell<List>(columnName: "labels", value: client.labels)
      ]);
    }

    return DataGridRow(
      cells: [ 
        DataGridCell(columnName: "id", value: client.clientId ?? ''), 
        DataGridCell(columnName: "name", value: client.person?.fullName ?? ''), 
        DataGridCell(columnName: "phone", value: client.person?.phone ?? ''), 
        DataGridCell(columnName: "email", value: client.person?.email ?? ''), 
        DataGridCell<List>(columnName: "labels", value: client.labels)
      ]);
  }
  
@override
Future<PageResponse<Client>> getPaginatedData(int page) async {
  final response = await _adminRepository.getClients(filters.search ?? '', page);

  return response.when(
    left: (failure) => throw failure, // Lanza la excepción si hay un error
    right: (value) => Future.value(value as FutureOr<PageResponse<Client>>?), // Devuelve directamente PageResponse<Client>
  );
}

  @override
  int rowsPerPage = 15;


}
