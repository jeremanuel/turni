part of 'clients_list_bloc.dart';

@freezed
class ClientsListState with _$ClientsListState {

  factory ClientsListState({
    ClientListFilters? filters,
    @Default(false) bool loadingData,
    int? totalClients,
    String? columnNameSort,
    bool? isAscending
  }) = _ClientsListState;

  factory ClientsListState.initial(BuildContext context, AdminRepository adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending) => ClientsListState();
}

