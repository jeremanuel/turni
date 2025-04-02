import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../core/utils/date_functions.dart';
import '../../../../../domain/entities/payment/payment.dart';
import '../../../../../domain/repositories/payment_repository.dart';

class Paymentslist extends StatefulWidget {
  final int clientId;
  final Function(Payment?)? onPaymentsLoad;
  final PaymentsDataSource paymentDataSource;

  const Paymentslist({super.key, required  this.clientId, this.onPaymentsLoad, required this.paymentDataSource});

  @override
  State<Paymentslist> createState() => _PaymentslistState();
}

class _PaymentslistState extends State<Paymentslist> {

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AsyncPaginatedDataTable2(
      empty: const Center(child: Text("El cliente no tiene pagos cargados")),
      headingRowColor: WidgetStateProperty.resolveWith((states) => colorScheme.surfaceContainer),
      columns: const [
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Monto")),
        DataColumn(label: Text("Método de Pago")),
        DataColumn(label: Text("Subscripcion")),
        DataColumn(label: Text("Observaciones")),
      ],
      source: widget.paymentDataSource,
      autoRowsToHeight: true,
      wrapInCard: false,
      columnSpacing: 12,
      horizontalMargin: 16,
      rowsPerPage: 5, // Cambia según el número deseado por página
      showFirstLastButtons: true,
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class PaymentsDataSource extends AsyncDataTableSource {

  PaymentsDataSource(
    this.clientId, this.onPaymentsLoad, {
    required this.paymentRepository,
  });

  PaymentRepository paymentRepository;
  final int clientId;
  final Function(Payment?)? onPaymentsLoad;
  
  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {

  
    final page = (startIndex / count).ceil() + 1;

    final result = await paymentRepository.getClientPayments(clientId, page);
    
    final pageResponse = result.whenOrNull(
      left: (failure) => throw failure,
      right: (value) => value,
    );

    if(page == 1){
      onPaymentsLoad?.call(pageResponse!.data.isNotEmpty ? pageResponse.data.first : null);
    }

    return AsyncRowsResponse(pageResponse!.total, pageResponse.data.map(rowFromPayment).toList());

    
  }

  DataRow rowFromPayment(Payment payment){
    return DataRow(
      cells: [
        DataCell(Text(DateFunctions.formatDateToDefaultFormat(payment.paymentDate))),
        DataCell(Text(payment.amount.toString())),
        DataCell(Text(payment.paymentMethod.name)),
        DataCell(
          Text(
            payment.clientSubscription?.subscription.name ?? '',
            style:const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Tooltip(
            message: payment.observation ?? '',
            child: Text(
              payment.observation ?? '',
              style:const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
    ]);
  }
}