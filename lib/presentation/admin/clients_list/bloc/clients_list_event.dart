part of 'clients_list_bloc.dart';

@freezed
class ClientsListEvent with _$ClientsListEvent {
  const factory ClientsListEvent.init() = _Started;
  const factory ClientsListEvent.changeFilters(ClientListFilters newFilter) = ChangeFilters;
  const factory ClientsListEvent.changeSort(String columnNameSort, bool ascending) = ChangeSort;
    const factory ClientsListEvent.onChangePage(int newPage) = OnChangePage;


}