part of 'clients_list_bloc.dart';

@freezed
sealed class ClientsListState with _$ClientsListState {

  factory ClientsListState({
    
    @Default(false) bool loadingData,
    required ClientListFilters filters
  }) = _ClientsListState;

  factory ClientsListState.initial(BuildContext context, AdminRepository adminRepository, ClientListFilters filters, String? columnNameSort,bool? isAscending) => ClientsListState(
    filters: filters
  );
}

