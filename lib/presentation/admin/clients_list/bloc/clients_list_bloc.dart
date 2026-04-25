import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../core/utils/either.dart';
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
  late final TrinaGridStateManager stateManager;

  ClientsListBloc(BuildContext context, this.adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending): 
  super(ClientsListState.initial(context, adminRepository, filters, columnNameSort, isAscending))
  {

  

    on<ChangeFilters>((event, emit){
      emit(
        state.copyWith(
          filters: event.newFilter
      )); 
      
      stateManager.setFilter((element) => false);
    });


  }

  bool hasDefaultFilters(){
    return (state.filters.search == null || state.filters.search!.isEmpty) && state.filters.statusId == null && state.filters.labelId == null;
  }

  bool isDirty(Map<String, dynamic> filters){
    return (state.filters.search ?? '') != (filters['search'] ?? '')|| state.filters.statusId != filters['statusId'] || state.filters.labelId != filters['labelId'];
  }

  Future<PageResponse<Client> > fetchClients (int page, String? sortKey, bool? isAscending) async {
    final response = await adminRepository.getClients(state.filters.search ?? '', page, sortKey, isAscending);

    final decodedResponse = switch (response) {
      Right(:final value) => value,
      Left() => null,
    };

    return decodedResponse!;
  }

  void refetchClients(){
    stateManager.setFilter((element) => false);
  }
}
