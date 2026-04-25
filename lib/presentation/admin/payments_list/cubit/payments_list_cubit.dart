import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../core/utils/data_source.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/payment/payment.dart';
import '../../../../domain/repositories/payment_repository.dart';

part 'payments_list_state.dart';
part 'payments_list_cubit.freezed.dart';

class PaymentsListCubit extends Cubit<PaymentsListState> {
  final PaymentRepository _paymentRepository;
  late final TrinaGridStateManager trinaGridStateManager;
  final filtersFormKey = GlobalKey<FormBuilderState>();
  ThemeData? themeData;

  bool isDirty(Map<String, dynamic> filters) {
    return (state.filters['search'] ?? '') != (filters['search'] ?? '') ||
           (state.filters['fechaDesde'] ?? '') != (filters['fechaDesde'] ?? '') ||
           (state.filters['fechaHasta'] ?? '') != (filters['fechaHasta'] ?? '');
  }

  void onChangeFilters(Map<String, dynamic> filters) {
    emit(state.copyWith(filters: filters));
    refresh();
  }

  TrinaRow _paymentToRow(Payment payment) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: payment.paymentId?.toString() ?? 'N/A'),
        'cliente': TrinaCell(value: '${payment.client!.person!.name} ${payment.client!.person!.lastName}'),
        'fecha': TrinaCell(value: _formatDate(payment.paymentDate)),
        'monto': TrinaCell(value: _formatAmount(payment.amount)),
        'metodo': TrinaCell(value: payment.paymentMethod.name),
        'subscripcion': TrinaCell(value: payment.clientSubscription?.subscription.name ?? 'Sin suscripción'),
      }
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  PaymentsListCubit(this._paymentRepository) : super( PaymentsListState(
    filters: {
      'fechaHasta': DateTime.now(),
      'fechaDesde': DateTime.now().subtract(const Duration(days: 30))
    }
  ));

  Future<TrinaInfinityScrollRowsResponse> loadClientPayments([bool reset = false]) async {
      emit(state.copyWith(
        payments: DataSource(status: DataSourceStatus.loading),
        currentPage: reset ? 1 : state.currentPage,
      ));

      // Extraer fechas de los filtros si están disponibles


      final result = await _paymentRepository.getPayments(
        state.currentPage,
        fechaDesde: state.filters['fechaDesde'],
        fechaHasta: state.filters['fechaHasta'],
      );
      
      switch (result) {
        case Right(:final value):
          final totalPages = (value.extraData!.totalCount! / 25).ceil();
          emit(state.copyWith(
            payments: DataSource(
              status: DataSourceStatus.loaded,
              data: value.payments,
            ),
            totalPages: totalPages,
            currentPage: state.currentPage + 1,
            totalItems: value.extraData!.totalCount!,
          ));

          trinaGridStateManager.columns.last.footerRenderer = (rend) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                width: 2,
                color: themeData!.colorScheme.primary
              )
            ),
            child: Text("${_formatAmount(value.extraData!.totalAmount!)}"));

   
        
          return TrinaInfinityScrollRowsResponse(
            isLast: (state.currentPage - 1) >= totalPages,
            rows: value.payments!.map(_paymentToRow).toList(),
          );

        case Left(:final failure):
          emit(state.copyWith(
            payments: DataSource(
              status: DataSourceStatus.error,
              errorMessage: failure.message,
            ),
          ));
          return TrinaInfinityScrollRowsResponse(
            isLast: true,
            rows: [],
          );
      }
  }



  void refresh() {

    emit(state.copyWith(
      currentPage: 1,
    ));

    trinaGridStateManager.setFilter((element) => false);

  }

  void resetError() {
    emit(state.copyWith(
      payments: DataSource(
        status: DataSourceStatus.loaded,
        data: state.payments?.data,
      ),
    ));
  }

  Future<void> createPayment(Map<String, dynamic> paymentData) async {
    try {
      final result = await _paymentRepository.createPayment(paymentData);
      switch (result) {
        case Right():
          // Recargar la lista después de crear un pago
          if (state.currentClientId != null) {
            refresh();
          }
        case Left(:final failure):
          emit(state.copyWith(
            payments: DataSource(
              status: DataSourceStatus.error,
              errorMessage: failure.message,
            ),
          ));
      }
    } catch (e) {
      emit(state.copyWith(
        payments: DataSource(
          status: DataSourceStatus.error,
          errorMessage: 'Error al crear el pago',
        ),
      ));
    }
  }
}