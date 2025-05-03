import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/LabelChip.dart';
import '../../../../core/presentation/components/trina_paginated_table/trina_paginated_table.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../list_utils/client_list_filters.dart';
import '../list_utils/clients_data_source.dart';
import '../list_utils/clients_data_source_sf.dart';
import '../widgets/client_list_filters_container.dart';
import 'package:turni/domain/entities/request/page_response.dart';

part 'clients_list_event.dart';
part 'clients_list_state.dart';
part 'clients_list_bloc.freezed.dart';

class ClientsListBloc extends Bloc<ClientsListEvent, ClientsListState> {

  final filtersFormKey = GlobalKey<FormBuilderState>();
  late final TrinaGridStateManager stateManager;


  ClientsListBloc(BuildContext context, AdminRepository adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending): 
  super(ClientsListState.initial(context, adminRepository, filters, columnNameSort, isAscending))
  {

    on<ChangeFilters>((event, emit) async {

    final data = await adminRepository.getClients(event.newFilter.search ?? '', 1);

    emit(state.copyWith(
      filters: event.newFilter
    ));


    data.whenOrNull(
      right: (value) {
        
        stateManager.scroll.bodyRowsVertical?.jumpTo(0);
        stateManager.refRows.clear();
        stateManager.insertRows(0, value.data.map(_clientToRow).toList());
        stateManager.setPageSize(15);
        stateManager.setShowLoading(false);

        emit(
          state.copyWith(
            totalClients: value.total
          )
        );
        
      },
    );

    });

    on<OnChangePage>((event, emit) async {

    final data = await adminRepository.getClients("", event.newPage);

    data.whenOrNull(
      right: (value) {
        
        rebuildRows(value);

        emit(
          state.copyWith(
            totalClients: value.total
          )
        );
        
      },  
    );

    });


    on<ChangeSort>((event, emit) async { 


      emit(
        state.copyWith(
          columnNameSort: event.columnNameSort,
          isAscending: event.ascending
      ));

      final data = await adminRepository.getClients("", 1, event.columnNameSort, event.ascending);


      data.whenOrNull(
        right: (value) {
          
          rebuildRows(value);

          emit(
            state.copyWith(
              totalClients: value.total
            )
          );
          
        },
    );


    });
  }

  void rebuildRows(PageResponse<Client> value) {
    stateManager.scroll.bodyRowsVertical?.jumpTo(0);
    stateManager.refRows.clear();
    stateManager.insertRows(0, value.data.map(_clientToRow).toList());
    stateManager.setPageSize(15);
    stateManager.setShowLoading(false);
  }

  bool hasDefaultFilters(){
    return (state.filters?.search == null || (state.filters?.search?.isEmpty ?? false)) && state.filters?.statusId == null && state.filters?.labelId == null;
  }

  bool isDirty(Map<String, dynamic> filters){
    return (state.filters?.search ?? '') != (filters['search'] ?? '')|| state.filters?.statusId != filters['statusId'] || state.filters?.labelId != filters['labelId'];
  }

  TrinaRow _clientToRow(Client client){
    return TrinaRow(
      cells: {
        "name": TrinaCell(
          value:client.person?.name ?? '',
          renderer: (rendererContext) {
            return Text(rendererContext.cell.value);
          }
        ),
        "email": TrinaCell(
          value:client.person?.email ?? '',
          renderer: (rendererContext) {
            return Text(rendererContext.cell.value);
          }
        ),
        "phone": TrinaCell(
          value:client.person?.phone ?? '',
          renderer: (rendererContext) {
            return Text(rendererContext.cell.value);
          }
        ),
        "labels": TrinaCell(
          value:client.labels,
          renderer: (rendererContext) {
            return SingleChildScrollView(
              child: Row(
                spacing: 4,
                children: [
                  ...client.labels!.map((e) => Labelchip(e))
                ],
              ),
            );
          },
        ),
      }
    );
  }
}
