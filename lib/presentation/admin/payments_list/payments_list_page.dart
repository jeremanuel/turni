import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/custom_trina_grid/custom_trina_grid.dart';
import '../../../domain/repositories/payment_repository.dart';
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
                        title: 'Turno',
                        field: 'turno',
                        type: TrinaColumnType.text(),
                        width: 90,
                        enableContextMenu: false,
                        enableDropToResize: false,
                        enableEditingMode: false,
                        renderer: (rendererContext) {
                          final sessionId = rendererContext.cell.value as int?;

                          if (sessionId == null) {
                            return Text('-');
                          }

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => context.goNamed(
                                AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name,
                                pathParameters: {'idSession': sessionId.toString()},
                              ),
                              child: Text(
                                '#$sessionId',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
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