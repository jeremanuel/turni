import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/custom_trina_grid/custom_trina_grid.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../../../infrastructure/mock/payment_repository_mock.dart';
import 'cubit/payments_list_cubit.dart';
import 'widgets/payments_list_header.dart';

class PaymentsListPage extends StatelessWidget {
  const PaymentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: BlocProvider<PaymentsListCubit>(
        create: (context) => PaymentsListCubit(sl<PaymentRepository>()),
        child: Builder(
          builder: (context) {
      
            if(context.read<PaymentsListCubit>().themeData == null){
              context.read<PaymentsListCubit>().themeData = Theme.of(context);
            }
      
            return Column(
              children: [
                const PaymentsListHeader(),
                Expanded(
                  child: CustomTrinaGrid(
                    onLoaded: (event) => context.read<PaymentsListCubit>().trinaGridStateManager = event.stateManager..setShowColumnFooter(true),
                    columns: [
                      TrinaColumn(
                        title: 'ID',
                        field: 'id',
                        type: TrinaColumnType.text(),
                        width: 15,
                        enableContextMenu: false,
                        enableDropToResize: false,
                        enableEditingMode: false,
                  
                      ),
                      TrinaColumn(
                        title: 'Cliente',
                        field: 'cliente',
                        type: TrinaColumnType.text(),
                        enableContextMenu: false,
                        enableDropToResize: false,
                        enableEditingMode: false
                      ),
                      TrinaColumn(
                        title: 'Fecha de pago',
                        field: 'fecha',
                        type: TrinaColumnType.text(),
                        enableContextMenu: false,
                        enableDropToResize: false,
                        enableEditingMode: false,
                        width: 120
                        
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
                        title: 'Monto',
                        field: 'monto',
                        type: TrinaColumnType.text(),
                        width: 80,
                        enableContextMenu: false,
                        enableDropToResize: false,
                        enableEditingMode: false,
                        textAlign: TrinaColumnTextAlign.center,
                        titleTextAlign: TrinaColumnTextAlign.center,
                        renderer: (rendererContext) {
                          return Container(
                            alignment: Alignment.center,
                            child: Text(rendererContext.cell.value),
                          );
                        },
                      
                      )
                    ], 
                    rows: [],
                    createFooter: (stateManager) {
                      return TrinaInfinityScrollRows(
                        fetch: (request) {
                          
                          return context.read<PaymentsListCubit>().loadClientPayments();
                        },
                        stateManager: stateManager
                    );
                    },
                    ),
                ),
              ],
            );
          }
        )
      ),
    );
  }
}