part of 'clients_list_bloc.dart';

@freezed
class ClientsListState with _$ClientsListState {

  factory ClientsListState({
    required ClientsDataSource dataSource,
    @Default(false) bool loadingData
  }) = _ClientsListState;

  factory ClientsListState.initial(BuildContext context, AdminRepository adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending) => ClientsListState(
    dataSource: ClientsDataSource(context, adminRepository: adminRepository, filters: filters, columnNameSort: columnNameSort, isAscending: isAscending),
  );
}

