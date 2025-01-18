import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/responsive_builder.dart';

class AddPaymentButton extends StatefulWidget {
  const AddPaymentButton({super.key});

  @override
  State<AddPaymentButton> createState() => _AddPaymentButtonState();
}

class _AddPaymentButtonState extends State<AddPaymentButton> {


  final dropdownController = DropdownController();


  @override
  Widget build(BuildContext context) {
       return DropdownWidget(
      menuWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        height: 400,
        child:  Column(
          spacing: 12,
          children: [
            Text("Nuevo pago", style: Theme.of(context).textTheme.titleLarge,),
            Spacer(),
            const DropdownMenu(
              label: Text("Subscripcion"),
              expandedInsets: EdgeInsets.symmetric(),
              inputDecorationTheme: InputDecorationTheme(
                contentPadding:  EdgeInsets.symmetric(horizontal: 8) 
              ),
              initialSelection: 1,
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 1, label: "Libre")
              ]
            ),
          TextFormField(
              initialValue: "14482",
              decoration: InputDecoration(
                contentPadding:  EdgeInsets.symmetric(horizontal: 8),
                labelText: "Monto",
                prefix: Text("\$")
              ),
            ),
            const DropdownMenu(
              label: Text("Medio de pago"),
              expandedInsets: EdgeInsets.symmetric(),
              inputDecorationTheme: InputDecorationTheme(
                contentPadding:  EdgeInsets.symmetric(horizontal: 8) 
              ),
              initialSelection: 1,
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 2, label: "Transferencia"),
                DropdownMenuEntry(value: 1, label: "Efectivo")

              ]
            ),
            TextFormField(
              decoration: InputDecoration(
                contentPadding:  EdgeInsets.symmetric(horizontal: 8),
                labelText: "Observaciones",
                
              ),
            ),
            Spacer(),
            FilledButton(onPressed: (){}, child: Text("Crear Pago"))
      
      
          ],
        )
      ), 
      dropdownController: dropdownController,
      child: buildButton(context)
    );
  }

  Widget buildButton(BuildContext context) {

    if(ResponsiveBuilder.isMobile(context)){
      return IconButton(onPressed: (){
        dropdownController.show!();
      }, icon: Icon(Icons.add_card_outlined), tooltip: "Registrar nuevo pago",);
    }
    
    return TextButton(
      onPressed:(){ 
        dropdownController.show!();
      }, 
      child: const Text("Registrar nuevo pago")
    );
  }
}