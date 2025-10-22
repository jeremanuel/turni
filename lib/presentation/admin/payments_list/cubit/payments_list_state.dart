part of 'payments_list_cubit.dart';

@freezed
sealed class PaymentsListState with _$PaymentsListState {
  const factory PaymentsListState({
    DataSource<List<Payment>>? payments,
    @Default(1) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int totalItems,
    @Default(<String, dynamic>{}) Map<String, dynamic> filters,
    int? currentClientId,
  }) = _PaymentsListState;
}