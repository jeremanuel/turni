part of 'clients_list_bloc.dart';

@freezed
class ClientsListState with _$ClientsListState {

  factory ClientsListState({
    required ClientsDataSourceSf<Client> dataSource,
    @Default(false) bool loadingData
  }) = _ClientsListState;

  factory ClientsListState.initial(BuildContext context, AdminRepository adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending) => ClientsListState(
    dataSource: ClientsDataSourceSf<Client>(adminRepository, filters, context)..loadPage(1),
  );
}

