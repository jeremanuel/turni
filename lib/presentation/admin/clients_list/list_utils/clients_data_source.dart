import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';
import 'client_list_filters.dart';
import 'clients_data_row.dart';

class ClientsDataSource extends AsyncDataTableSource{

  final AdminRepository _adminRepository;
  final BuildContext context;
  ClientListFilters filters;
  String? columnNameSort;
  bool? isAscending;
  List<Client>? clients;

  ClientsDataSource(this.context, {required AdminRepository adminRepository, required this.filters, this.columnNameSort, this.isAscending}) : _adminRepository  = adminRepository;
  
  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {

    final page = (startIndex / count).ceil() + 1;
    final result = await _adminRepository.getClients(filters.search ?? '', page);
    
    
    final pageInfo = result.when(
      left: (error) {
        throw Exception(error.message);
      },
      right: (pageInfo) => pageInfo
    );

    clients = pageInfo.data;

    return AsyncRowsResponse(pageInfo.total, pageInfo.data.map((client) => ClientsDataRow(context, client)).toList());
    
  }

  

}