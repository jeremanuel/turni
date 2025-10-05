import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/request/page_response.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../list_utils/client_list_filters.dart';

part 'clients_list_event.dart';
part 'clients_list_state.dart';
part 'clients_list_bloc.freezed.dart';

class ClientsListBloc extends Bloc<ClientsListEvent, ClientsListState> {

  final filtersFormKey = GlobalKey<FormBuilderState>();
  late AdminRepository adminRepository;


  ClientsListBloc(BuildContext context, this.adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending): 
  super(ClientsListState.initial(context, adminRepository, filters, columnNameSort, isAscending))
  {

  

    on<ChangeFilters>((event, emit){

   /*    var dataSource = state.dataSource;

      dataSource.filters = event.newFilter;
      emit(
        state.copyWith(
          dataSource: dataSource
      )); */


    });

    on<ChangeSort>((event, emit){
/*         var dataSource = state.dataSource;

/*       dataSource.columnNameSort = event.columnIndex == 0 ? 'id' : event.columnIndex == 1 ? 'name' : 'phone';
      dataSource.isAscending = event.ascending;
 */
      emit(
        state.copyWith(
          dataSource: dataSource
      )); */

    

    });
  }

  bool hasDefaultFilters(){
    return (state.filters.search == null || state.filters.search!.isEmpty) && state.filters.statusId == null && state.filters.labelId == null;
  }

  bool isDirty(Map<String, dynamic> filters){
    return (state.filters.search ?? '') != (filters['search'] ?? '')|| state.filters.statusId != filters['statusId'] || state.filters.labelId != filters['labelId'];
  }

  Future<PageResponse<Client> > fetchClients (int page) async {
    final response = await adminRepository.getClients("");

    final decodedResponse = response.when(
      right: (value) => value,
      left: (failure) => null,
    );

    return decodedResponse!;
  }
}
