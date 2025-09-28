import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../domain/entities/extra.dart';
import '../../../../../../domain/entities/payment/payment.dart';
import '../../../../../../domain/entities/payment/payment_method.dart';

/// Tipos de pago disponibles
enum PaymentType { session, other }

/// Opciones de radio para el pago de turno
enum PaymentRadio { allTurn, remaining, half, onePerson, other }

typedef OnPaymentToSessionAdded = void Function(Payment payment);
typedef OnPaymentToExtrasAdded = void Function(List<Extra> extrasPagados);

/// Widget para agregar un pago o consumo extra
class AddPaymentContainer extends StatefulWidget {
  const AddPaymentContainer({
    super.key,
    required this.remainingPrice,
    required this.totalPrice,
    required this.onPaymentAdded,
    required this.consumos,
    required this.onConsumosPagados,
  });

  final double remainingPrice;
  final double totalPrice;
  final OnPaymentToSessionAdded onPaymentAdded;
  final List<Extra> consumos;
  final OnPaymentToExtrasAdded onConsumosPagados;

  @override
  State<AddPaymentContainer> createState() => _AddPaymentContainerState();
}

class _AddPaymentContainerState extends State<AddPaymentContainer> {

  PaymentType paymentType = PaymentType.session;
  PaymentRadio? selectedRadioValue;

  final FocusNode otroFocusNode = FocusNode();
  final TextEditingController otroController = TextEditingController();
  late final Map<PaymentRadio, Map> paymentValues;

  final List<Extra> selectedConsumos = [];
  final ExpansibleController controller = ExpansibleController();

  @override
  void initState() {
    paymentValues = {
      PaymentRadio.allTurn: {"amount": widget.remainingPrice, "name":"Todo el turno"},
      PaymentRadio.remaining: {"amount": widget.remainingPrice, "name":"Restante"},
      PaymentRadio.half: {"amount": widget.totalPrice / 2, "name":"Mitad"},
      PaymentRadio.onePerson: {"amount": widget.totalPrice / 4, "name":"1 persona"},
    };
    super.initState();
  }

  bool isValidPayment() {

    if(selectedRadioValue == PaymentRadio.other && otroController.text.isEmpty) return false;
    
    if (selectedRadioValue == null && selectedConsumos.isEmpty) return false;
    
    return true;
  }

  void createPayment() {

    if (!isValidPayment()) return;
    
    if(selectedConsumos.isNotEmpty)  widget.onConsumosPagados(selectedConsumos);

    if(selectedRadioValue != null){

      final payment = Payment(
        clientId: -1,
        paymentMethod: PaymentMethod(paymentMethodId: 1, name: "Efectivo"),
        paymentDate: DateTime.now(),
        createdByAdmin: 1,
        amount: paymentValues[selectedRadioValue]?['amount'] ?? double.parse(otroController.text),
        isExtra: false,
      );

      widget.onPaymentAdded(payment);

    }
      
    

    
  }

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      width: 500,
      height: 500,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Text("Nuevo pago", style: textTheme.titleLarge),
                const SizedBox(height: 16),
                buildPaymentTypeSelector(colorScheme, textTheme),
                const SizedBox(height: 16),
                if (paymentType == PaymentType.session)
                  buildTurnTypeBody(colorScheme, textTheme),
                if (paymentType == PaymentType.other)
                  buildConsumosBody(colorScheme, textTheme),
                
               
              ],
            ),
          ),
          buildResumen(colorScheme),
          const SizedBox(height: 8,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text("Cancelar")),
              TextButton(onPressed: isValidPayment() ? createPayment : null, child: const Text("Pagar")),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildResumen(ColorScheme colorScheme) {

    if(selectedConsumos.isEmpty && selectedRadioValue == null){
      controller.collapse();
      return const SizedBox();
    }

    return Expansible(
      controller: controller,
      headerBuilder: (context, animation) => InkWell(
        onTap: () {
          if (controller.isExpanded) {
            controller.collapse();
            return;
          }
          controller.expand();
        },
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              borderRadius: !controller.isExpanded  ? BorderRadius.circular(8) :BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              color: colorScheme.tertiaryContainer,
              border: !controller.isExpanded ? Border.all(color: colorScheme.tertiary) : Border(top: BorderSide(color: colorScheme.tertiary), right: BorderSide(color: colorScheme.tertiary), left: BorderSide(color: colorScheme.tertiary))
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                children: [
                  TextSpan(text: "Resumen ", style: TextStyle(color: colorScheme.onTertiaryContainer)),
                  TextSpan(text: "\$${calculateAmount()}", style:  TextStyle(color: colorScheme.onTertiaryContainer)),
                ]
              )
              ),
             
              Badge(
                label: Text("${selectedConsumos.length + (selectedRadioValue != null ? 1 : 0)}"),
                child: Icon(Icons.expand_more, color: colorScheme.onPrimaryContainer)
              ),
            ],
          ),
        ),
      ),
      bodyBuilder: (context, animation) => Container(
           width: 300,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              color: colorScheme.tertiaryContainer,
              border: Border(bottom: BorderSide(color: colorScheme.tertiary), right: BorderSide(color: colorScheme.tertiary), left: BorderSide(color: colorScheme.tertiary))
            ),
            child: Wrap(
              spacing: 4,
              children: [
                ...selectedConsumos.map((e) => InputChip(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  label: Text("\$ ${e.amount} ${e.name}"),
                  onDeleted: () {
                    setState(() {
                      selectedConsumos.remove(e);
                    });
                  }
                  )),
                if(selectedRadioValue != null && selectedRadioValue != PaymentRadio.other)
                  InputChip(
                    label: Text("\$ ${paymentValues[selectedRadioValue]?['amount'].toStringAsFixed(0)} ${paymentValues[selectedRadioValue]?['name']}"),
                    onDeleted: () {
                      setState(() {
                        selectedRadioValue = null;
                      });
                    },
                  ),
                if(selectedRadioValue == PaymentRadio.other)
                  InputChip(
                    label: Text("\$ ${otroController.text} Otro monto"),
                    onDeleted: () {
                      setState(() {
                        selectedRadioValue = null;
                        otroController.clear();
                      });
                    },
                  ),
              ],
            ),
          ),
    );
  }
  double calculateAmount() {
    double total = 0;
    if (selectedRadioValue != null && selectedRadioValue != PaymentRadio.other) {
      total += paymentValues[selectedRadioValue]?['amount'] ?? 0;
    }
    total += selectedConsumos.fold<double>(0, (sum, extra) => sum + (extra.amount as num).toDouble());
    return total;
  }

  Widget buildPaymentTypeSelector(ColorScheme colorScheme, TextTheme textTheme) {
    final double consumosRestantes = widget.consumos
        .where((extra) => !(extra.payed))
        .fold<double>(0, (sum, extra) => sum + (extra.amount as num).toDouble());
    final bool consumosDisponibles = consumosRestantes > 0;
    return Row(
      spacing: 3,
      children: [
        Expanded(
          child: Opacity(
            opacity: widget.remainingPrice == 0 ? 0.5 : 1,
            child: Ink(
              decoration: BoxDecoration(
                color: paymentType == PaymentType.session ? colorScheme.tertiaryContainer : null,
                border: Border.all(color: paymentType == PaymentType.session ? colorScheme.tertiaryFixed : colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: widget.remainingPrice == 0 ? null : () {
                  paymentType = PaymentType.session;
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Radio(
                        fillColor: WidgetStateProperty.all(paymentType == PaymentType.session ? colorScheme.tertiary : colorScheme.primary),
                        value: paymentType,
                        groupValue: PaymentType.session,
                        onChanged: widget.remainingPrice == 0 ? null : (value) {
                          paymentType = PaymentType.session;
                          setState(() {});
                        },
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "Turno \n", style: textTheme.titleMedium),
                            TextSpan(text: "\$${widget.remainingPrice} \n", style: textTheme.titleMedium?.copyWith(color: paymentType == PaymentType.session ? colorScheme.onTertiaryContainer : colorScheme.primary)),
                            TextSpan(text: "Restante", style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Opacity(
            opacity: !consumosDisponibles ? 0.5 : 1,
            child: Ink(
              height: 86,
              decoration: BoxDecoration(
                color: paymentType == PaymentType.other ? colorScheme.tertiaryContainer : null,
                border: Border.all(color: paymentType == PaymentType.other ? colorScheme.tertiaryFixed : colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: !consumosDisponibles ? null : () {
                  paymentType = PaymentType.other;
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Radio(
                        fillColor: WidgetStateProperty.all(paymentType == PaymentType.other ? colorScheme.tertiary : colorScheme.primary),
                        value: paymentType,
                        groupValue: PaymentType.other,
                        onChanged: !consumosDisponibles ? null : (value) {
                          paymentType = PaymentType.other;
                          setState(() {});
                        },
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "Consumos \n", style: textTheme.titleMedium),
                            TextSpan(text: "\$${consumosRestantes.toStringAsFixed(0)} \n", style: textTheme.titleMedium?.copyWith(color: paymentType == PaymentType.other ? colorScheme.onTertiaryContainer : colorScheme.primary)),
                            TextSpan(text: "Restante", style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTurnTypeBody(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        RadioListTile(
          title: Row(
            children: [
              Text(widget.remainingPrice == widget.totalPrice ? "Todo el turno" : "Restante", style: textTheme.titleMedium),
              const SizedBox(width: 8),
              Text("(\$${paymentValues[PaymentRadio.allTurn]?['amount'].toStringAsFixed(0) ?? ''})", style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
            ],
          ),
          value: PaymentRadio.allTurn,
          groupValue: selectedRadioValue,
          onChanged: (value) => setState(() => selectedRadioValue = PaymentRadio.allTurn),
        ),
        if (widget.remainingPrice > paymentValues[PaymentRadio.half]?['amount'])
        RadioListTile(
          title: Row(
            children: [
              Text("Mitad", style: textTheme.titleMedium),
              const SizedBox(width: 8),
              Text("(\$${paymentValues[PaymentRadio.half]?['amount'].toStringAsFixed(0) ?? ''})", style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
            ],
          ),
          value: PaymentRadio.half,
          groupValue: selectedRadioValue,
          onChanged: (value) => setState(() => selectedRadioValue = PaymentRadio.half),
        ),
        if (widget.remainingPrice > paymentValues[PaymentRadio.onePerson]?['amount'])
        RadioListTile(
          title: Row(
            children: [
              Text("1 persona", style: textTheme.titleMedium),
              const SizedBox(width: 8),
              Text("(\$${paymentValues[PaymentRadio.onePerson]?['amount'].toStringAsFixed(0) ?? ''})", style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
            ],
          ),
          value: PaymentRadio.onePerson,
          groupValue: selectedRadioValue,
          onChanged: (value) => setState(() => selectedRadioValue = value),
        ),
        RadioListTile(
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: otroFocusNode,
                  controller: otroController,
                  onChanged: (_) => setState(() => selectedRadioValue = PaymentRadio.other),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+(\.[0-9]*)?')), // Solo números y punto decimal
                  ],
                  decoration: const InputDecoration(
                    
                    prefixText: "\$ ",
                    hintText: "Otro monto",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          value: PaymentRadio.other,
          groupValue: selectedRadioValue,
          onChanged: (value) => setState(() => selectedRadioValue = PaymentRadio.other),
        ),
      ],
    );
  }

  Widget buildConsumosBody(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        ...widget.consumos.mapIndexed((i, extra) {

          return CheckboxListTile(
            value: selectedConsumos.contains(extra),
            onChanged: (v) => setState(() {
              if (v == true) {
                selectedConsumos.add(extra);
              } else {
                selectedConsumos.remove(extra);
              }
            }),
            title: Text(extra.name, style: textTheme.titleMedium),
            subtitle: Text("\$${extra.amount}", style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
          );
        }),
      ],
    );
  }
}
