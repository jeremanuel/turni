import 'package:turni/core/presentation/components/custom_trina_grid/custom_trina_grid.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/date_functions.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../domain/entities/payment/payment.dart';
import '../../../../../domain/repositories/payment_repository.dart';

class Paymentslist extends StatefulWidget {
  final int clientId;
  final Function(Payment?)? onPaymentsLoad;
  final PaymentRepository paymentRepository;
  final void Function(TrinaGridOnLoadedEvent)? onLoaded;
 
  const Paymentslist({super.key, required  this.clientId, this.onPaymentsLoad, required this.paymentRepository, this.onLoaded});

  @override
  State<Paymentslist> createState() => _PaymentslistState();
}

class _PaymentslistState extends State<Paymentslist> {

  @override
  Widget build(BuildContext context) {
    return CustomTrinaGrid(
      onLoaded: widget.onLoaded,
      columns: [
        TrinaColumn(
          title: 'Fecha',
          field: 'fecha',
          type: TrinaColumnType.text(),
          enableContextMenu: false,
          enableDropToResize: false,
          enableEditingMode: false,
          
        ),
        TrinaColumn(
          title: 'Monto',
          field: 'monto',
          type: TrinaColumnType.text(),
          width: 80,
          enableContextMenu: false,
          enableDropToResize: false,
          enableEditingMode: false
        ),
        TrinaColumn(
          title: 'Método de Pago',
          field: 'metodo',
          type: TrinaColumnType.text(),
          enableContextMenu: false,
          enableDropToResize: false,
          enableEditingMode: false
        ),
        TrinaColumn(
          title: 'Subscripcion',
          field: 'subscripcion',
          type: TrinaColumnType.text(),
          enableContextMenu: false,
          enableDropToResize: false,
          enableEditingMode: false
        ),
        TrinaColumn(
          title: 'Observaciones',
          field: 'observaciones',
          type: TrinaColumnType.text(),
          enableEditingMode: false
        ),
      ],
      rows:  [],
      createFooter: (stateManager) => TrinaLazyPagination(
        showTotalRows: false,
        enableGotoPage: false,
        initialPageSize: 5,
        stateManager: stateManager,
        pageSizes: const [5, 10, 20],
        fetch: (request) async {
          final page = request.page;
          final result = await widget.paymentRepository.getClientPayments(widget.clientId, page);
          final pageResponse = switch (result) {
            Left(:final failure) => throw failure,
            Right(:final value) => value,
          };
          if (page == 1) {
            widget.onPaymentsLoad?.call(pageResponse.data.isNotEmpty ? pageResponse.data.first : null);
          }
          return TrinaLazyPaginationResponse(
            totalRecords: pageResponse.total,
            totalPage: (pageResponse.total / stateManager.pageSize).ceil(),
            rows: pageResponse.data.map((payment) {
              return TrinaRow(cells: {
                'fecha': TrinaCell(value: DateFunctions.formatDateToDefaultFormat(payment.paymentDate)),
                'monto': TrinaCell(value: payment.amount.toString()),
                'metodo': TrinaCell(value: payment.paymentMethod.name),
                'subscripcion': TrinaCell(value: payment.clientSubscription?.subscription.name ?? '',
                  renderer: (ctx) => Text(
                    payment.clientSubscription?.subscription.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                'observaciones': TrinaCell(
                  renderer: (ctx) => Tooltip(
                    message: payment.observation ?? '',
                    child: Text(
                      payment.observation ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  value: payment.observation ?? '',
                ),
              });
            }).toList(),
          );
        },
      ),
    );
  }
}
