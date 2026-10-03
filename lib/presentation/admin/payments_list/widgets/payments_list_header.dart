import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/client.dart';
import '../../client_page/widgets/add_payment_button.dart';
import '../cubit/payments_list_cubit.dart';

class PaymentsListHeader extends StatefulWidget {
  const PaymentsListHeader({super.key});

  @override
  State<PaymentsListHeader> createState() => _PaymentsListHeaderState();
}

class _PaymentsListHeaderState extends State<PaymentsListHeader> {

  final FocusNode _focusNode = FocusNode();

    void unFocus() {
    _focusNode.unfocus();
    setState(() {});
  }

  void focus() {
    _focusNode.requestFocus();
    setState(() {});
  }

  BorderSide getBorder(ColorScheme colorSchenme) {
    if (_focusNode.hasFocus) {
      return BorderSide(color: colorSchenme.primary);
    }

    return BorderSide(color: colorSchenme.outlineVariant);
  }

  @override
  Widget build(BuildContext context) {
    final colorSchenme = Theme.of(context).colorScheme;

    return CallbackShortcuts(
        bindings: {
          LogicalKeySet(LogicalKeyboardKey.enter): () {},
          LogicalKeySet(LogicalKeyboardKey.escape): () {}
        },
        child: Focus(
          focusNode: _focusNode,
           child: TapRegion(
              onTapInside: (event) => focus(),
              onTapOutside: (event) => unFocus(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 102,
                    decoration: BoxDecoration(
                        color: colorSchenme.surfaceContainerLow,
                        border: Border.symmetric(
                          horizontal: getBorder(colorSchenme))
                        ),
                    child: Row(
                      spacing: 10,
                      children: [
                        /* const _SearchBarFilter(), */
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            const Row(
                              children: [
                                SizedBox(width: 8,),
                                Text("En que periodo estas buscando?"),
                              ],
                            ),
                            const SizedBox(height: 4,),
                            FilterChipIntervalDate(
                              initialSuggestion: 2,
                              label: "Fecha de pago",
                              withSuggesttions: true,
                              onApply: (i) {
                                context.read<PaymentsListCubit>().onChangeFilters({
                                  'fechaDesde': i.initialDate,
                                  'fechaHasta': i.endDate,
                                });
                            },),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: VerticalDivider()),
                          TextButton(
                          onPressed: () {},
                          child: const Row(
                            spacing: 4,
                            children: [
                              Icon(Icons.filter_alt_outlined),
                              Text("Mas Filtros"),
                            ],
                          ),
                         
                        ),
                        const Spacer(),
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: VerticalDivider()
                        ),
                        AddPaymentButton(client: null, onPaymentCreated: (payment){
                          context.read<PaymentsListCubit>().refresh();
                        })
                      ],
                    ),
                  ),
                  if (ResponsiveBuilder.isMobile(context) )
                    Container(
                      height: 40,
                      color: colorSchenme.onPrimary,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                      ),
                    )
                ],
              ),
           ),
          ),
        );
      
  }
}