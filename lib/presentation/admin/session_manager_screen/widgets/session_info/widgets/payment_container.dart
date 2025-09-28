import 'package:collection/collection.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../../../domain/entities/extra.dart';
import '../../../../../../domain/entities/payment/payment.dart';
import '../../../../../../domain/entities/session.dart';
import './add_payment_container.dart';
import './add_extra_container.dart';

class PaymentContainer extends StatefulWidget {

  const PaymentContainer({
    super.key, 
    required this.session, 
    required this.onPaymentAdded, 
    required this.onExtraAdded, 
    required this.onExtrasPayed,
  });

  final Session session;
  final Function(Payment payment) onPaymentAdded;
  final Function(Extra extra, bool payed) onExtraAdded;
  final Function(List<Extra> extras) onExtrasPayed;

  @override
  State<PaymentContainer> createState() => _PaymentContainerState();
}

class _PaymentContainerState extends State<PaymentContainer> {

  final DropdownController dropdownController = DropdownController();
  final DropdownController extraDropdownController = DropdownController();
  final ExpansibleController controller = ExpansibleController();  

  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;

    return Expansible(
      controller: controller,
      headerBuilder: (context, animation) => 
        InkWell(
          onTap: () => controller.isExpanded ? controller.collapse() : controller.expand(),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Consumos", style: Theme.of(context).textTheme.titleLarge),
                Icon(controller.isExpanded? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
      bodyBuilder: (context, animation) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownWidget(
                  dropdownController: dropdownController,
                  menuWidget: AddPaymentContainer(
                    remainingPrice: widget.session.remainingSessionPrice,
                    totalPrice: widget.session.price,
                    onPaymentAdded: (payment) {
                      widget.onPaymentAdded(payment);
                      dropdownController.hide!();
                    },
                    consumos: widget.session.extras?.where((extra) => !extra.payed).toList() ?? [],
                    onConsumosPagados: (consumosPagados) {
                      widget.onExtrasPayed(consumosPagados);
                      dropdownController.hide!();
                    },
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                    ),
                    onPressed: () {
                      dropdownController.toggle!();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(Icons.attach_money),
                        Text("Nuevo Pago"),
                      ],
                    ),
                  ),
                ),
                DropdownWidget(
                  dropdownController: extraDropdownController,
                  menuWidget: AddExtraContainer(
                    onExtraAdded: (extra) {
                      widget.onExtraAdded(extra, extra.payed);
                      extraDropdownController.hide!();
                    },
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                    ),
                    onPressed: () {
                      extraDropdownController.toggle!();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        Text("Nuevo Consumo"),
                      ],
                    ),
                  ),
                )
              ],
            ),
            buildDottedLine(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(text:"Turno", style: Theme.of(context).textTheme.titleMedium),
                ),     
                RichText(
                  text:TextSpan(text:" ${widget.session.price} ", style: Theme.of(context).textTheme.titleMedium?.copyWith( color:colorScheme.primary))
                )
              ],
            ),
            if(widget.session.sessionPayedPrice != 0)
            ...[...widget.session.payments?.where((payment) => payment.isExtra != true).mapIndexed((i, payment) => 
              Opacity(
                opacity: 0.8,
                child: ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  contentPadding: EdgeInsets.zero,
                  title: Text("Pago ${i + 1}", style: Theme.of(context).textTheme.titleSmall),
                  //leading:  Icon(Icons.check, color: colorScheme.primary, size: 18) ,
                  trailing: RichText(text: TextSpan(text:"- ${payment.amount} ", style: Theme.of(context).textTheme.titleSmall?.copyWith( color:colorScheme.primary))),
                  onTap: (){},
               
                ),
              )
            ).toList() ?? [],
              Container(
             
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(text:"Restante", style: Theme.of(context).textTheme.titleMedium),
                  ),     
                  RichText(
                    text:TextSpan(text:" ${widget.session.remainingSessionPrice} ", style: Theme.of(context).textTheme.titleMedium?.copyWith( color:colorScheme.primary))
                  )
                ],
                            ),
              )
            ],
            
            if(widget.session.extras?.isNotEmpty ?? false)
            ...[
              buildDottedLine(),
              Row(
              children: [
                RichText(
                  text: TextSpan(text:"Consumos extras", style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(width: 4,),
                Tooltip(
                  message: "Los consumos extras son aquellos que no estan incluidos en el turno, como por ejemplo bebidas, comidas, etc.",
                  child: Icon(Icons.info_outline, size: 18,)
                ),
                
                const Spacer(),
                RichText(
                  text:TextSpan(text: "${widget.session.extrasTotalPrice} ", style: Theme.of(context).textTheme.titleMedium?.copyWith( color:colorScheme.primary))
                )
              ],
            ),
            ],
            ...widget.session.extras?.map((extra) => 
              Opacity(
                opacity: 0.8,
                child: ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  contentPadding: EdgeInsets.zero,
                  title: Text("${extra.name} ${extra.payed ? "(pago)" : "(pendiente)"}", style: Theme.of(context).textTheme.titleSmall),
                  leading: extra.payed ? Icon(Icons.check, color: colorScheme.primary, size: 18) : Icon(Icons.close, color: colorScheme.tertiary, size: 18),
                  trailing: RichText(text: TextSpan(text:"${extra.amount} ", style: Theme.of(context).textTheme.titleSmall?.copyWith( color:colorScheme.primary))),
                  onTap: (){

                  },
                ),
              )
            ).toList() ?? [],
            if(widget.session.extras?.isNotEmpty ?? false)
            Container(
          
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(text:"Restante", style: Theme.of(context).textTheme.titleMedium),
                  ),     
                  RichText(
                    text:TextSpan(text:" ${widget.session.remainingExtrasPrice} ", style: Theme.of(context).textTheme.titleMedium?.copyWith( color:colorScheme.primary))
                  )
                ],
              ),
            ),
            SizedBox(height: 4,),
            buildDottedLine(),
            SizedBox(height: 4,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(text:"Total", style: Theme.of(context).textTheme.titleMedium),
                ),     
                RichText(
                  text:TextSpan(text:" ${widget.session.extrasTotalPrice + widget.session.price} ", style: Theme.of(context).textTheme.titleMedium?.copyWith( color:colorScheme.primary))
                )
              ],
            ),
            Container(
         
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(text:"A pagar", style: Theme.of(context).textTheme.titleMedium),
                  ),     
                  RichText(
                    text:TextSpan(text:" ${widget.session.remainingTotalPrice} ", style: Theme.of(context).textTheme.titleMedium?.copyWith( color:colorScheme.primary))
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Container buildDottedLine() {
    return Container(
          height: 4,
          decoration: DottedDecoration(),
        );
  }
}

