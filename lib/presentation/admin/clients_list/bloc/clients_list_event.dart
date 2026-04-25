part of 'clients_list_bloc.dart';

@freezed
sealed class ClientsListEvent with _$ClientsListEvent {
  const factory ClientsListEvent.init() = _Started;
  const factory ClientsListEvent.changeFilters(ClientListFilters newFilter) = ChangeFilters;
  const factory ClientsListEvent.changeSort(int columnIndex, bool ascending) = ChangeSort;

}