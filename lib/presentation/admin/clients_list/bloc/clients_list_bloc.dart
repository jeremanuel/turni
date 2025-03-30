import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../list_utils/client_list_filters.dart';
import '../list_utils/clients_data_source.dart';
import '../list_utils/clients_data_source_sf.dart';
import '../widgets/client_list_filters_container.dart';

part 'clients_list_event.dart';
part 'clients_list_state.dart';
part 'clients_list_bloc.freezed.dart';

class ClientsListBloc extends Bloc<ClientsListEvent, ClientsListState> {

  final filtersFormKey = GlobalKey<FormBuilderState>();


  ClientsListBloc(BuildContext context, AdminRepository adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending): 
  super(ClientsListState.initial(context, adminRepository, filters, columnNameSort, isAscending))
  {

    on<ChangeFilters>((event, emit){

      var dataSource = state.dataSource;

      dataSource.filters = event.newFilter;
      emit(
        state.copyWith(
          dataSource: dataSource
      ));

      dataSource.loadPage(dataSource.currentPage);

    });

    on<ChangeSort>((event, emit){
        var dataSource = state.dataSource;

/*       dataSource.columnNameSort = event.columnIndex == 0 ? 'id' : event.columnIndex == 1 ? 'name' : 'phone';
      dataSource.isAscending = event.ascending;
 */
      emit(
        state.copyWith(
          dataSource: dataSource
      ));

      dataSource.loadPage(dataSource.currentPage);

    });
  }

  bool hasDefaultFilters(){
    return (state.dataSource.filters.search == null || state.dataSource.filters.search!.isEmpty) && state.dataSource.filters.statusId == null && state.dataSource.filters.labelId == null;
  }

  bool isDirty(Map<String, dynamic> filters){
    return (state.dataSource.filters.search ?? '') != (filters['search'] ?? '')|| state.dataSource.filters.statusId != filters['statusId'] || state.dataSource.filters.labelId != filters['labelId'];
  }
}
