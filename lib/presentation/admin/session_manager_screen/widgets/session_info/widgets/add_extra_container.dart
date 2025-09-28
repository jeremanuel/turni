import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../domain/entities/extra.dart';
import '../../../../../../domain/entities/payment/payment.dart';
import '../../../../../../domain/entities/payment/payment_method.dart';

typedef OnExtraAdded = void Function(Extra extra);

class AddExtraContainer extends StatefulWidget {
  const AddExtraContainer({super.key, required this.onExtraAdded});

  final OnExtraAdded onExtraAdded;

  @override
  State<AddExtraContainer> createState() => _AddExtraContainerState();
}

class _AddExtraContainerState extends State<AddExtraContainer> {
  final TextEditingController extraController = TextEditingController();
  final TextEditingController otherObservacionesController = TextEditingController();
  bool paidExtra = false;

  bool isValidExtra() {
    return extraController.text.isNotEmpty;
  }

  void createExtra() {
    if (!isValidExtra()) return;
    final extra = Extra(
      name: otherObservacionesController.text.isEmpty ? "Extra" : otherObservacionesController.text,
      amount: double.tryParse(extraController.text) ?? 0,
      payment: paidExtra
          ? Payment.fromExtra(
            amount: double.parse(extraController.text), 
            method: PaymentMethod(paymentMethodId: 1, name: "Efectivo"))
          : null,
    );

    widget.onExtraAdded(extra);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing:8,
        children: [
          Text("Nuevo consumo", style: textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: otherObservacionesController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Nombre del consumo",
              border: OutlineInputBorder(),
            ),
          ),
          TextField(
            onChanged: (_) => setState(() {}),
            controller: extraController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+(\.[0-9]*)?')), // Solo números y punto decimal
            ],
            decoration: const InputDecoration(
              prefixText: '\$',
              hintText: "Monto",
              border: OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: paidExtra,
            onChanged: (v) => setState(() => paidExtra = v!),
            subtitle: Text("Indica si el pago ha sido realizado", style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            title: Text("Pagado", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancelar")),
              TextButton(onPressed: isValidExtra() ? createExtra : null, child: const Text("Agregar")),
            ],
          ),
        ],
      ),
    );
  }
}
